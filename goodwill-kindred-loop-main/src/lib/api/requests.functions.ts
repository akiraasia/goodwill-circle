import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { pool } from "@/lib/lovable/database";
import { getCurrentProfileId } from "@/lib/auth.server";

export const CATEGORIES = [
  "Education",
  "Career",
  "Food",
  "Medical",
  "Finance",
  "Housing",
  "Emotional Support",
  "Other",
] as const;

export const LEVELS = ["low", "normal", "urgent"] as const;

const createSchema = z.object({
  title: z.string().trim().min(4).max(120),
  description: z.string().trim().min(10).max(2000),
  category: z.enum(CATEGORIES),
  level: z.enum(LEVELS),
  anonymous: z.boolean(),
  media_url: z
    .string()
    .max(800_000)
    .regex(/^data:image\/(png|jpeg|webp);base64,/)
    .optional(),
});

export type FeedRequest = {
  id: string;
  title: string;
  description: string;
  category: string;
  level: string;
  status: string;
  created_at: string;
  anonymous: boolean;
  author_name: string | null;
  author_id: string | null;
  media_url: string | null;
  is_mine: boolean;
  reaction_count: number;
  comment_count: number;
  i_reacted: boolean;
};

export const listRequestsFn = createServerFn({ method: "GET" })
  .inputValidator((d: unknown) => z.object({ category: z.string().optional() }).parse(d ?? {}))
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    const params: unknown[] = [me];
    let where = "";
    if (data.category && data.category !== "All") {
      params.push(data.category);
      where = `WHERE r.category = $2`;
    }
    const r = await pool.query<FeedRequest>(
      `SELECT r.id, r.title, r.description, r.category, r.level, r.status, r.created_at,
              r.anonymous, r.media_url,
              CASE WHEN r.anonymous THEN NULL ELSE p.name END AS author_name,
              CASE WHEN r.anonymous THEN NULL ELSE p.id::text END AS author_id,
              (r.profile_id = $1) AS is_mine,
              COALESCE((SELECT COUNT(*)::int FROM public.reactions WHERE request_id = r.id), 0) AS reaction_count,
              COALESCE((SELECT COUNT(*)::int FROM public.comments  WHERE request_id = r.id), 0) AS comment_count,
              EXISTS(SELECT 1 FROM public.reactions WHERE request_id = r.id AND profile_id = $1) AS i_reacted
       FROM public.help_requests r
       JOIN public.profiles p ON p.id = r.profile_id
       ${where}
       ORDER BY r.created_at DESC
       LIMIT 100`,
      params,
    );
    return r.rows;
  });

export const getRequestFn = createServerFn({ method: "GET" })
  .inputValidator((d: unknown) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    const r = await pool.query(
      `SELECT r.*, p.name AS author_name,
              COALESCE((SELECT COUNT(*)::int FROM public.reactions WHERE request_id = r.id), 0) AS reaction_count,
              COALESCE((SELECT COUNT(*)::int FROM public.comments  WHERE request_id = r.id), 0) AS comment_count,
              EXISTS(SELECT 1 FROM public.reactions WHERE request_id = r.id AND profile_id = $2) AS i_reacted
       FROM public.help_requests r
       JOIN public.profiles p ON p.id = r.profile_id
       WHERE r.id = $1`,
      [data.id, me],
    );
    const req = r.rows[0];
    if (!req) return null;
    const completions = await pool.query(
      `SELECT c.id, c.message, c.completed_at, p.name AS helper_name, p.id AS helper_id
       FROM public.help_completions c
       JOIN public.profiles p ON p.id = c.helper_id
       WHERE c.request_id = $1
       ORDER BY c.completed_at ASC`,
      [data.id],
    );
    return {
      request: {
        ...req,
        author_name: req.anonymous ? null : req.author_name,
        is_mine: me === req.profile_id,
        can_help: me !== null && me !== req.profile_id && req.status === "open",
      },
      completions: completions.rows,
    };
  });

export const createRequestFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) => createSchema.parse(d))
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    if (!me) return { ok: false as const, error: "Please sign in." };
    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      const prof = await client.query<{ credits: number; free_requests: number }>(
        `SELECT credits, free_requests FROM public.profiles WHERE id = $1 FOR UPDATE`,
        [me],
      );
      const p = prof.rows[0];
      if (!p) throw new Error("Profile not found");
      let reason = "request_created";
      let delta = -10;
      if (p.free_requests > 0) {
        await client.query(
          `UPDATE public.profiles SET free_requests = free_requests - 1 WHERE id = $1`,
          [me],
        );
        delta = 0;
        reason = "free_request_used";
      } else {
        if (p.credits < 10) {
          await client.query("ROLLBACK");
          return { ok: false as const, error: "You need at least 10 credits to post. Help someone to earn more." };
        }
        await client.query(`UPDATE public.profiles SET credits = credits - 10 WHERE id = $1`, [me]);
      }
      const ins = await client.query<{ id: string }>(
        `INSERT INTO public.help_requests (profile_id, title, description, category, level, anonymous, media_url)
         VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
        [me, data.title, data.description, data.category, data.level, data.anonymous, data.media_url ?? null],
      );
      const rid = ins.rows[0].id;
      await client.query(
        `INSERT INTO public.credits_ledger (profile_id, delta, reason, request_id) VALUES ($1,$2,$3,$4)`,
        [me, delta, reason, rid],
      );
      await client.query("COMMIT");
      return { ok: true as const, id: rid };
    } catch (e) {
      await client.query("ROLLBACK");
      console.error(e);
      return { ok: false as const, error: "Could not create request." };
    } finally {
      client.release();
    }
  });

export const completeHelpFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) =>
    z.object({ request_id: z.string().uuid(), message: z.string().trim().max(500).optional() }).parse(d),
  )
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    if (!me) return { ok: false as const, error: "Please sign in." };
    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      const r = await client.query(
        `SELECT id, profile_id, title, status FROM public.help_requests WHERE id = $1 FOR UPDATE`,
        [data.request_id],
      );
      const req = r.rows[0];
      if (!req) {
        await client.query("ROLLBACK");
        return { ok: false as const, error: "Request not found." };
      }
      if (req.profile_id === me) {
        await client.query("ROLLBACK");
        return { ok: false as const, error: "You cannot help your own request." };
      }
      const existing = await client.query(
        `SELECT 1 FROM public.help_completions WHERE request_id = $1 AND helper_id = $2`,
        [data.request_id, me],
      );
      if (existing.rowCount && existing.rowCount > 0) {
        await client.query("ROLLBACK");
        return { ok: false as const, error: "You've already helped with this." };
      }
      await client.query(
        `INSERT INTO public.help_completions (request_id, helper_id, message) VALUES ($1,$2,$3)`,
        [data.request_id, me, data.message ?? null],
      );
      await client.query(
        `UPDATE public.profiles SET credits = credits + 15 WHERE id = $1`,
        [me],
      );
      await client.query(
        `INSERT INTO public.credits_ledger (profile_id, delta, reason, request_id) VALUES ($1,15,'help_completed',$2)`,
        [me, data.request_id],
      );
      if (req.status === "open") {
        await client.query(`UPDATE public.help_requests SET status = 'helped' WHERE id = $1`, [data.request_id]);
      }
      await client.query(
        `INSERT INTO public.notifications (profile_id, type, message, link)
         VALUES ($1, 'help_received', $2, $3)`,
        [
          req.profile_id,
          `Someone helped with "${req.title}"`,
          `/app/requests/${data.request_id}`,
        ],
      );
      await client.query("COMMIT");
      return { ok: true as const };
    } catch (e) {
      await client.query("ROLLBACK");
      console.error(e);
      return { ok: false as const, error: "Could not record help." };
    } finally {
      client.release();
    }
  });

export const deleteRequestFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    if (!me) return { ok: false as const, error: "Please sign in." };
    const r = await pool.query(
      `DELETE FROM public.help_requests WHERE id = $1 AND profile_id = $2 RETURNING id`,
      [data.id, me],
    );
    if (!r.rowCount) return { ok: false as const, error: "Not allowed." };
    return { ok: true as const };
  });
