import { createServerFn } from "@tanstack/react-start";
import { useSession } from "@tanstack/react-start/server";
import { z } from "zod";
import { pool } from "@/lib/lovable/database";
import {
  hashPassword,
  verifyPassword,
  sessionConfig,
  loadCurrentUser,
  type SessionData,
} from "@/lib/auth.server";

const signupSchema = z.object({
  name: z.string().trim().min(1).max(80),
  email: z.string().trim().email().max(255),
  password: z.string().min(8).max(200),
});

const loginSchema = z.object({
  email: z.string().trim().email().max(255),
  password: z.string().min(1).max(200),
});

export const signupFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) => signupSchema.parse(d))
  .handler(async ({ data }) => {
    const email = data.email.toLowerCase();
    const existing = await pool.query(`SELECT 1 FROM public.profiles WHERE email = $1`, [email]);
    if (existing.rowCount && existing.rowCount > 0) {
      return { ok: false as const, error: "An account with this email already exists." };
    }
    const hash = hashPassword(data.password);
    const r = await pool.query<{ id: string }>(
      `INSERT INTO public.profiles (email, password_hash, name) VALUES ($1,$2,$3) RETURNING id`,
      [email, hash, data.name.trim()],
    );
    const id = r.rows[0].id;
    await pool.query(
      `INSERT INTO public.credits_ledger (profile_id, delta, reason) VALUES ($1, 100, 'signup_bonus')`,
      [id],
    );
    await pool.query(
      `INSERT INTO public.notifications (profile_id, type, message, link)
       VALUES ($1, 'welcome', 'Welcome to Goodwill Circle! You have 100 credits and 1 free request to start.', '/app')`,
      [id],
    );
    const session = await useSession<SessionData>(sessionConfig);
    await session.update({ profileId: id });
    return { ok: true as const };
  });

export const loginFn = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) => loginSchema.parse(d))
  .handler(async ({ data }) => {
    const email = data.email.toLowerCase();
    const r = await pool.query<{ id: string; password_hash: string }>(
      `SELECT id, password_hash FROM public.profiles WHERE email = $1`,
      [email],
    );
    const row = r.rows[0];
    if (!row || !verifyPassword(data.password, row.password_hash)) {
      return { ok: false as const, error: "Incorrect email or password." };
    }
    const session = await useSession<SessionData>(sessionConfig);
    await session.update({ profileId: row.id });
    return { ok: true as const };
  });

export const logoutFn = createServerFn({ method: "POST" }).handler(async () => {
  const session = await useSession<SessionData>(sessionConfig);
  await session.clear();
  return { ok: true as const };
});

export const meFn = createServerFn({ method: "GET" }).handler(async () => {
  return await loadCurrentUser();
});
