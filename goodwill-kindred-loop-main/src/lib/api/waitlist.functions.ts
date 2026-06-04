import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { pool } from "@/lib/lovable/database";

const schema = z.object({
  email: z.string().trim().email().max(255),
  name: z.string().trim().max(100).optional().or(z.literal("")),
  role: z.string().trim().max(50).optional().or(z.literal("")),
});

export const joinWaitlist = createServerFn({ method: "POST" })
  .inputValidator((data: unknown) => schema.parse(data))
  .handler(async ({ data }) => {
    try {
      const result = await pool.query(
        `INSERT INTO public.waitlist (email, name, role)
         VALUES ($1, NULLIF($2,''), NULLIF($3,''))
         ON CONFLICT (email) DO UPDATE SET name = COALESCE(EXCLUDED.name, public.waitlist.name)
         RETURNING id`,
        [data.email.toLowerCase(), data.name ?? "", data.role ?? ""],
      );
      const countRes = await pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM public.waitlist`);
      return { ok: true as const, id: result.rows[0].id, count: Number(countRes.rows[0].count) };
    } catch (e) {
      console.error("waitlist insert failed", e);
      return { ok: false as const, error: "Could not save your signup. Please try again." };
    }
  });

export const getWaitlistCount = createServerFn({ method: "GET" }).handler(async () => {
  try {
    const r = await pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM public.waitlist`);
    return { count: Number(r.rows[0].count) };
  } catch {
    return { count: 0 };
  }
});
