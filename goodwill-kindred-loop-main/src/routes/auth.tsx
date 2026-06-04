import { createFileRoute, Link, redirect, useNavigate } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { useMutation } from "@tanstack/react-query";
import { signupFn, loginFn, meFn } from "@/lib/api/auth.functions";

export const Route = createFileRoute("/auth")({
  head: () => ({
    meta: [{ title: "Sign in · Goodwill Circle" }],
  }),
  beforeLoad: async () => {
    const me = await meFn();
    if (me) throw redirect({ to: "/app" });
  },
  component: AuthPage,
});

function AuthPage() {
  const [mode, setMode] = useState<"login" | "signup">("login");
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const m = useMutation({
    mutationFn: async () => {
      if (mode === "signup") return signupFn({ data: { name, email, password } });
      return loginFn({ data: { email, password } });
    },
    onSuccess: (res) => {
      if (res.ok) navigate({ to: "/app" });
    },
  });

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    m.mutate();
  };

  return (
    <main className="min-h-screen bg-background text-foreground">
      <div className="mx-auto flex min-h-screen max-w-md flex-col justify-center px-6 py-12">
        <Link to="/" className="mb-10 flex items-center gap-2">
          <span className="grid h-8 w-8 place-items-center rounded-full bg-primary text-primary-foreground font-serif">◯</span>
          <span className="font-serif text-xl">Goodwill Circle</span>
        </Link>
        <h1 className="font-serif text-4xl">
          {mode === "login" ? "Welcome back." : "Join the circle."}
        </h1>
        <p className="mt-2 text-muted-foreground">
          {mode === "login" ? "Sign in to ask, help, and pay it forward." : "100 credits and your first request are on us."}
        </p>
        <form onSubmit={onSubmit} className="mt-8 space-y-3">
          {mode === "signup" && (
            <input
              type="text" required maxLength={80} placeholder="Your name"
              value={name} onChange={(e) => setName(e.target.value)}
              className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm outline-none focus:border-ring"
            />
          )}
          <input
            type="email" required maxLength={255} placeholder="you@example.com"
            value={email} onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm outline-none focus:border-ring"
          />
          <input
            type="password" required minLength={8} maxLength={200} placeholder="Password (min 8 chars)"
            value={password} onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm outline-none focus:border-ring"
          />
          <button type="submit" disabled={m.isPending}
            className="w-full rounded-xl bg-primary px-5 py-3.5 text-sm font-semibold text-primary-foreground transition hover:opacity-90 disabled:opacity-60">
            {m.isPending ? "Working…" : mode === "login" ? "Sign in" : "Create account"}
          </button>
          {m.data && !m.data.ok && (
            <p className="text-sm text-destructive">{m.data.error}</p>
          )}
        </form>
        <p className="mt-6 text-sm text-muted-foreground">
          {mode === "login" ? "New here?" : "Already have an account?"}{" "}
          <button onClick={() => setMode(mode === "login" ? "signup" : "login")}
            className="font-semibold text-ember underline-offset-2 hover:underline">
            {mode === "login" ? "Create an account" : "Sign in"}
          </button>
        </p>
      </div>
    </main>
  );
}
