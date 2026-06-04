import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState, type FormEvent } from "react";
import { meFn } from "@/lib/api/auth.functions";
import { myStatsFn, updateProfileFn } from "@/lib/api/profile.functions";
import { fileToDataUrl } from "@/lib/imageUpload";

export const Route = createFileRoute("/app/profile")({
  head: () => ({ meta: [{ title: "Profile · Goodwill Circle" }] }),
  component: Profile,
});

function Profile() {
  const qc = useQueryClient();
  const me = useQuery({ queryKey: ["me"], queryFn: () => meFn() });
  const stats = useQuery({ queryKey: ["stats"], queryFn: () => myStatsFn() });

  const [editing, setEditing] = useState(false);
  const [name, setName] = useState("");
  const [photo, setPhoto] = useState<string | null | undefined>(undefined);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    if (me.data && !editing) {
      setName(me.data.name);
      setPhoto(undefined);
    }
  }, [me.data, editing]);

  const save = useMutation({
    mutationFn: () =>
      updateProfileFn({
        data: {
          name,
          photo_url: photo === undefined ? undefined : (photo ?? ""),
        },
      }),
    onSuccess: (res) => {
      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["me"] });
        setEditing(false);
      }
    },
  });

  const onImage = async (file: File | undefined) => {
    setErr(null);
    if (!file) return;
    try {
      setPhoto(await fileToDataUrl(file, 512, 0.85));
    } catch (e: any) {
      setErr(e?.message ?? "Could not read image.");
    }
  };

  if (!me.data) return <p className="mx-auto max-w-3xl px-4 py-10 text-muted-foreground">Loading…</p>;

  const tier = characterTier(stats.data?.people_helped ?? 0);
  const currentPhoto = photo === undefined ? me.data.photo_url : photo;

  return (
    <main className="mx-auto max-w-3xl px-4 py-8 pb-24 sm:pb-10">
      <div className="flex items-center gap-5">
        {currentPhoto ? (
          <img src={currentPhoto} alt="" className="h-20 w-20 rounded-full object-cover" />
        ) : (
          <div className="grid h-20 w-20 place-items-center rounded-full bg-ember/15 font-serif text-3xl text-ember">
            {me.data.name.charAt(0).toUpperCase()}
          </div>
        )}
        <div className="min-w-0 flex-1">
          {editing ? (
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              maxLength={80}
              className="w-full max-w-xs rounded-lg border border-input bg-background px-3 py-1.5 font-serif text-2xl outline-none focus:border-ring"
            />
          ) : (
            <h1 className="font-serif text-3xl">{me.data.name}</h1>
          )}
          <p className="text-sm text-muted-foreground">{me.data.email}</p>
          <p className="mt-1 text-xs uppercase tracking-wider text-ember">{tier}</p>
        </div>
        {!editing && (
          <button
            onClick={() => setEditing(true)}
            className="rounded-full border border-border bg-card px-3 py-1.5 text-xs hover:bg-secondary"
          >
            Edit
          </button>
        )}
      </div>

      {editing && (
        <form
          onSubmit={(e: FormEvent) => {
            e.preventDefault();
            save.mutate();
          }}
          className="mt-5 space-y-3 rounded-2xl border border-border bg-card p-5"
        >
          <div className="flex flex-wrap items-center gap-3">
            <label className="cursor-pointer rounded-full border border-border bg-background px-3 py-1.5 text-xs hover:bg-secondary">
              Change photo
              <input
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => onImage(e.target.files?.[0])}
              />
            </label>
            {currentPhoto && (
              <button
                type="button"
                onClick={() => setPhoto(null)}
                className="text-xs text-muted-foreground hover:text-destructive"
              >
                Remove photo
              </button>
            )}
          </div>
          {err && <p className="text-xs text-destructive">{err}</p>}
          <div className="flex gap-2">
            <button
              type="submit"
              disabled={save.isPending}
              className="rounded-xl bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60"
            >
              {save.isPending ? "Saving…" : "Save"}
            </button>
            <button
              type="button"
              onClick={() => setEditing(false)}
              className="rounded-xl border border-border px-4 py-2 text-sm hover:bg-secondary"
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      <div className="mt-8 grid gap-4 sm:grid-cols-4">
        <Stat label="Credits" value={me.data.credits} accent />
        <Stat label="People helped" value={stats.data?.people_helped ?? 0} />
        <Stat label="Requests made" value={stats.data?.requests_made ?? 0} />
        <Stat label="Open requests" value={stats.data?.open_requests ?? 0} />
      </div>

      <h2 className="mt-10 font-serif text-2xl">Credit history</h2>
      <div className="mt-4 overflow-hidden rounded-2xl border border-border bg-card">
        {stats.data?.ledger?.length === 0 && (
          <p className="p-6 text-sm text-muted-foreground">No activity yet.</p>
        )}
        {stats.data?.ledger?.map((row: any) => (
          <div key={row.id} className="flex items-center justify-between border-b border-border px-5 py-3 text-sm last:border-b-0">
            <div>
              <p className="font-medium">{prettyReason(row.reason)}</p>
              <p className="text-xs text-muted-foreground">{new Date(row.created_at).toLocaleString()}</p>
            </div>
            <span className={"font-mono " + (row.delta > 0 ? "text-ember" : row.delta < 0 ? "text-destructive" : "text-muted-foreground")}>
              {row.delta > 0 ? "+" : ""}{row.delta}
            </span>
          </div>
        ))}
      </div>
    </main>
  );
}

function Stat({ label, value, accent }: { label: string; value: number; accent?: boolean }) {
  return (
    <div className={"rounded-2xl border border-border p-5 " + (accent ? "bg-ember/10" : "bg-card")}>
      <p className="font-serif text-3xl">{value}</p>
      <p className="mt-1 text-xs uppercase tracking-wider text-muted-foreground">{label}</p>
    </div>
  );
}

function characterTier(helped: number) {
  if (helped >= 100) return "Legend";
  if (helped >= 50) return "Beacon";
  if (helped >= 25) return "Pillar";
  if (helped >= 15) return "Guardian";
  if (helped >= 10) return "Mentor";
  if (helped >= 5) return "Advocate";
  if (helped >= 3) return "Contributor";
  if (helped >= 1) return "Helper";
  return "Seeker";
}

function prettyReason(r: string) {
  switch (r) {
    case "signup_bonus": return "Welcome bonus";
    case "free_request_used": return "First request (free)";
    case "request_created": return "Created a request";
    case "help_completed": return "Helped someone";
    default: return r;
  }
}
