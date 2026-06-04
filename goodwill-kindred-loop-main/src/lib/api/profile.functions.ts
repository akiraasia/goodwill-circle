import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { pool } from "@/lib/lovable/database";
import { getCurrentProfileId } from "@/lib/auth.server";

export const listNotificationsFn = createServerFn({ method: "GET" }).handler(async () => {
  const me = await getCurrentProfileId();
  if (!me) return [];
  const r = await pool.query(
    `SELECT id, type, message, link, read, created_at FROM public.notifications
     WHERE profile_id = $1 ORDER BY created_at DESC LIMIT 100`,
    [me],
  );
  return r.rows;
});

export const unreadCountFn = createServerFn({ method: "GET" }).handler(async () => {
  const me = await getCurrentProfileId();
  if (!me) return { count: 0 };
  const r = await pool.query<{ count: string }>(
    `SELECT COUNT(*)::text AS count FROM public.notifications WHERE profile_id = $1 AND read = false`,
    [me],
  );
  return { count: Number(r.rows[0].count) };
});

export const markAllReadFn = createServerFn({ method: "POST" }).handler(async () => {
  const me = await getCurrentProfileId();
  if (!me) return { ok: false };
  await pool.query(`UPDATE public.notifications SET read = true WHERE profile_id = $1`, [me]);
  return { ok: true };
});

export const myStatsFn = createServerFn({ method: "GET" }).handler(async () => {
  const me = await getCurrentProfileId();
  if (!me) return null;
  const stats = await pool.query<{
    requests_made: string;
    people_helped: string;
    open_requests: string;
  }>(
    `SELECT
       (SELECT COUNT(*) FROM public.help_requests WHERE profile_id = $1)::text AS requests_made,
       (SELECT COUNT(*) FROM public.help_completions WHERE helper_id = $1)::text AS people_helped,
       (SELECT COUNT(*) FROM public.help_requests WHERE profile_id = $1 AND status = 'open')::text AS open_requests`,
    [me],
  );
  const ledger = await pool.query(
    `SELECT id, delta, reason, created_at FROM public.credits_ledger
     WHERE profile_id = $1 ORDER BY created_at DESC LIMIT 20`,
    [me],
  );
  return {
    requests_made: Number(stats.rows[0].requests_made),
    people_helped: Number(stats.rows[0].people_helped),
    open_requests: Number(stats.rows[0].open_requests),
    ledger: ledger.rows,
  };
});

const dataUrl = z
  .string()
  .max(400_000)
  .regex(/^data:image\/(png|jpeg|webp);base64,/);

export const updateProfileFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) =>
    z
      .object({
        name: z.string().trim().min(1).max(80),
        photo_url: z.union([dataUrl, z.literal(""), z.null()]).optional(),
      })
      .parse(d),
  )
  .handler(async ({ data }) => {
    const me = await getCurrentProfileId();
    if (!me) return { ok: false as const, error: "Please sign in." };
    if (data.photo_url === undefined) {
      await pool.query(`UPDATE public.profiles SET name = $1 WHERE id = $2`, [data.name, me]);
    } else {
      const photo = data.photo_url === "" ? null : data.photo_url;
      await pool.query(
        `UPDATE public.profiles SET name = $1, photo_url = $2 WHERE id = $3`,
        [data.name, photo, me],
      );
    }
    return { ok: true as const };
  });

export const getPublicProfileFn = createServerFn({ method: "GET" })
  .inputValidator((d: unknown) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data }) => {
    const p = await pool.query<{
      id: string;
      name: string;
      photo_url: string | null;
      created_at: string;
    }>(
      `SELECT id, name, photo_url, created_at FROM public.profiles WHERE id = $1`,
      [data.id],
    );
    const prof = p.rows[0];
    if (!prof) return null;
    const stats = await pool.query<{ requests_made: string; people_helped: string }>(
      `SELECT
         (SELECT COUNT(*) FROM public.help_requests WHERE profile_id = $1 AND anonymous = false)::text AS requests_made,
         (SELECT COUNT(*) FROM public.help_completions WHERE helper_id = $1)::text AS people_helped`,
      [data.id],
    );
    const requests = await pool.query(
      `SELECT id, title, category, level, status, created_at, media_url
       FROM public.help_requests
       WHERE profile_id = $1 AND anonymous = false
       ORDER BY created_at DESC LIMIT 30`,
      [data.id],
    );
    return {
      profile: prof,
      requests_made: Number(stats.rows[0].requests_made),
      people_helped: Number(stats.rows[0].people_helped),
      requests: requests.rows,
    };
  });

export type Helper = {
  id: string;
  name: string;
  photo_url: string | null;
  people_helped: number;
};

export const topHelpersFn = createServerFn({ method: "GET" }).handler(async () => {
  const r = await pool.query<{
    id: string;
    name: string;
    photo_url: string | null;
    people_helped: string;
  }>(
    `SELECT p.id, p.name, p.photo_url,
            COUNT(c.id)::text AS people_helped
     FROM public.profiles p
     LEFT JOIN public.help_completions c ON c.helper_id = p.id
     GROUP BY p.id
     HAVING COUNT(c.id) > 0
     ORDER BY COUNT(c.id) DESC, p.created_at ASC
     LIMIT 50`,
  );
  return r.rows.map((x) => ({ ...x, people_helped: Number(x.people_helped) })) as Helper[];
});
