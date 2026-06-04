import { pbkdf2Sync, randomBytes } from "node:crypto";
import { useSession } from "@tanstack/react-start/server";
import { pool } from "@/lib/lovable/database";

const SESSION_SECRET =
  process.env.SESSION_SECRET ??
  "goodwill-circle-dev-secret-please-rotate-via-env-2026-min-32-chars-long";

export const sessionConfig = {
  password: SESSION_SECRET,
  name: "gwc_session",
  maxAge: 60 * 60 * 24 * 30,
  cookie: { httpOnly: true, sameSite: "none" as const, path: "/", secure: true },
};

export type SessionData = { profileId?: string };

export function hashPassword(password: string): string {
  const salt = randomBytes(16);
  const derived = pbkdf2Sync(password, salt, 100000, 32, "sha256");
  return `${salt.toString("hex")}:${derived.toString("hex")}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [saltHex, hashHex] = stored.split(":");
  if (!saltHex || !hashHex) return false;
  const salt = Buffer.from(saltHex, "hex");
  const derived = pbkdf2Sync(password, salt, 100000, 32, "sha256");
  return derived.toString("hex") === hashHex;
}

export async function getCurrentProfileId(): Promise<string | null> {
  const session = await useSession<SessionData>(sessionConfig);
  return session.data.profileId ?? null;
}

export type CurrentUser = {
  id: string;
  email: string;
  name: string;
  credits: number;
  free_requests: number;
  photo_url: string | null;
};

export async function loadCurrentUser(): Promise<CurrentUser | null> {
  const id = await getCurrentProfileId();
  if (!id) return null;
  const r = await pool.query<CurrentUser>(
    `SELECT id, email, name, credits, free_requests, photo_url
     FROM public.profiles WHERE id = $1`,
    [id],
  );
  return r.rows[0] ?? null;
}
