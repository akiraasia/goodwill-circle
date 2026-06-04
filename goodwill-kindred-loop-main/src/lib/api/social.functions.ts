import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { pool } from "@/lib/lovable/database";
import { getCurrentProfileId } from "@/lib/auth.server";

const dataUrl = z
  .string()
  .max(800_000)
  .regex(/^data:image\/(png|jpeg|webp);base64,/, "Must be a base64 image data URL");

// ---------- Stories ----------

export type Story = {
  id: string;
  profile_id: string;
  author_name: string;
  body: string | null;
  media_url: string | null;
  created_at: string;
  expires_at: string;
};

export const listStoriesFn = createServerFn({ method: "GET" }).handler(async () => {
  const r = await pool.query<Story>(
    `SELECT s.id, s.profile_id, p.name AS author_name, s.body, s.media_url, s.created_at, s.expires_at
     FROM public.stories s
     JOIN public.profiles p ON p.id = s.profile_id
     WHERE s.expires_at > now()
     ORDER BY s.created_at DESC
     LIMIT 50`,
  );
  return r.rows;
});

export const createStoryFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) =>
    z
      .object({
        body: z.string().trim().max(280).optional(),
        media_url: dataUrl.optional(),
      })
      .refine((v) => v.body || v.media_url, { message: "Story needs text or an image." })
      .parse(d),
  )
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    if (!me) return { ok: false as const, error: "Please sign in." };
    const r = await pool.query<{ id: string }>(
      `INSERT INTO public.stories (profile_id, body, media_url) VALUES ($1,$2,$3) RETURNING id`,
      [me, data.body ?? null, data.media_url ?? null],
    );
    return { ok: true as const, id: r.rows[0].id };
  });

// ---------- Reactions ----------

export const toggleReactionFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) =>
    z.object({ request_id: z.string().uuid(), type: z.enum(["cheer", "heart", "pray"]) }).parse(d),
  )
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    if (!me) return { ok: false as const };
    const existing = await pool.query(
      `DELETE FROM public.reactions WHERE request_id = $1 AND profile_id = $2 AND type = $3 RETURNING id`,
      [data.request_id, me, data.type],
    );
    if (existing.rowCount && existing.rowCount > 0) return { ok: true as const, active: false };
    await pool.query(
      `INSERT INTO public.reactions (request_id, profile_id, type) VALUES ($1,$2,$3)
       ON CONFLICT DO NOTHING`,
      [data.request_id, me, data.type],
    );
    return { ok: true as const, active: true };
  });

// ---------- Comments ----------

export type Comment = {
  id: string;
  request_id: string;
  profile_id: string;
  author_name: string;
  body: string;
  created_at: string;
};

export const listCommentsFn = createServerFn({ method: "GET" })
  .inputValidator((d: unknown) => z.object({ request_id: z.string().uuid() }).parse(d))
  .handler(async ({ data }) => {
    const r = await pool.query<Comment>(
      `SELECT c.id, c.request_id, c.profile_id, p.name AS author_name, c.body, c.created_at
       FROM public.comments c
       JOIN public.profiles p ON p.id = c.profile_id
       WHERE c.request_id = $1
       ORDER BY c.created_at ASC
       LIMIT 200`,
      [data.request_id],
    );
    return r.rows;
  });

export const addCommentFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) =>
    z.object({ request_id: z.string().uuid(), body: z.string().trim().min(1).max(500) }).parse(d),
  )
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    if (!me) return { ok: false as const, error: "Please sign in." };
    const r = await pool.query<{ id: string }>(
      `INSERT INTO public.comments (request_id, profile_id, body) VALUES ($1,$2,$3) RETURNING id`,
      [data.request_id, me, data.body],
    );
    // Notify author if not self
    const owner = await pool.query<{ profile_id: string; title: string }>(
      `SELECT profile_id, title FROM public.help_requests WHERE id = $1`,
      [data.request_id],
    );
    const o = owner.rows[0];
    if (o && o.profile_id !== me) {
      await pool.query(
        `INSERT INTO public.notifications (profile_id, type, message, link)
         VALUES ($1, 'comment', $2, $3)`,
        [o.profile_id, `New comment on "${o.title}"`, `/app/requests/${data.request_id}`],
      );
    }
    return { ok: true as const, id: r.rows[0].id };
  });

export const deleteStoryFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    if (!me) return { ok: false as const, error: "Please sign in." };
    const r = await pool.query(
      `DELETE FROM public.stories WHERE id = $1 AND profile_id = $2 RETURNING id`,
      [data.id, me],
    );
    if (!r.rowCount) return { ok: false as const, error: "Not allowed." };
    return { ok: true as const };
  });
