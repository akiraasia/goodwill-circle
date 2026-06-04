import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { useMutation } from "@tanstack/react-query";
import { createRequestFn, CATEGORIES, LEVELS } from "@/lib/api/requests.functions";
import { fileToDataUrl } from "@/lib/imageUpload";

export const Route = createFileRoute("/app/new")({
  head: () => ({ meta: [{ title: "Ask for help · Goodwill Circle" }] }),
  component: NewRequest,
});

function NewRequest() {
  const navigate = useNavigate();
  const { user } = Route.useRouteContext();
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState<(typeof CATEGORIES)[number]>("Other");
  const [level, setLevel] = useState<(typeof LEVELS)[number]>("normal");
  const [anonymous, setAnonymous] = useState(false);
  const [mediaUrl, setMediaUrl] = useState<string | null>(null);
  const [imgError, setImgError] = useState<string | null>(null);

  const m = useMutation({
    mutationFn: () =>
      createRequestFn({
        data: { title, description, category, level, anonymous, media_url: mediaUrl ?? undefined },
      }),
    onSuccess: (res) => {
      if (res.ok) navigate({ to: "/app/requests/$id", params: { id: res.id } });
    },
  });

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    m.mutate();
  };

  const onImage = async (file: File | undefined) => {
    setImgError(null);
    if (!file) {
      setMediaUrl(null);
      return;
    }
    try {
      const data = await fileToDataUrl(file);
      setMediaUrl(data);
    } catch (err: any) {
      setImgError(err?.message ?? "Could not read image.");
    }
  };

  const cost = user.free_requests > 0 ? "free (first request)" : "10 credits";

  return (
    <main className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="font-serif text-4xl">Ask for help</h1>
      <p className="mt-2 text-muted-foreground">
        Be specific. Be honest. Someone here probably understands.
      </p>
      <p className="mt-2 text-xs text-muted-foreground">
        This request will cost you <span className="font-semibold text-ember">{cost}</span>.
      </p>
      <form onSubmit={onSubmit} className="mt-8 space-y-5 rounded-2xl border border-border bg-card p-6">
        <Field label="Title">
          <input required minLength={4} maxLength={120} value={title} onChange={(e) => setTitle(e.target.value)}
            placeholder="What do you need help with?" className={inputCls} />
        </Field>
        <Field label="Tell the story">
          <textarea required minLength={10} maxLength={2000} value={description} onChange={(e) => setDescription(e.target.value)}
            rows={6} placeholder="Context, what you've tried, what would actually help…" className={inputCls} />
        </Field>

        <Field label="Add a photo (optional)">
          {mediaUrl ? (
            <div className="relative">
              <img src={mediaUrl} alt="" className="max-h-72 w-full rounded-xl object-cover" />
              <button type="button" onClick={() => setMediaUrl(null)}
                className="absolute right-2 top-2 rounded-full bg-black/60 px-3 py-1 text-xs text-white">
                Remove
              </button>
            </div>
          ) : (
            <label className="flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-dashed border-border bg-background px-4 py-6 text-sm text-muted-foreground hover:bg-secondary/50">
              <span>📷 Choose a photo</span>
              <input type="file" accept="image/*" className="hidden"
                onChange={(e) => onImage(e.target.files?.[0])} />
            </label>
          )}
          {imgError && <p className="mt-1 text-xs text-destructive">{imgError}</p>}
        </Field>

        <div className="grid gap-5 sm:grid-cols-2">
          <Field label="Category">
            <select value={category} onChange={(e) => setCategory(e.target.value as typeof category)} className={inputCls}>
              {CATEGORIES.map((c) => <option key={c}>{c}</option>)}
            </select>
          </Field>
          <Field label="Urgency">
            <select value={level} onChange={(e) => setLevel(e.target.value as typeof level)} className={inputCls}>
              <option value="low">Low — whenever</option>
              <option value="normal">Normal</option>
              <option value="urgent">Urgent</option>
            </select>
          </Field>
        </div>
        <label className="flex items-start gap-3 rounded-xl border border-border bg-background p-3 text-sm">
          <input type="checkbox" checked={anonymous} onChange={(e) => setAnonymous(e.target.checked)} className="mt-0.5" />
          <span>
            <span className="font-medium">Post anonymously.</span>
            <span className="block text-muted-foreground">Your name and photo will not be shown.</span>
          </span>
        </label>
        {m.data && !m.data.ok && (
          <p className="text-sm text-destructive">{m.data.error}</p>
        )}
        <button type="submit" disabled={m.isPending}
          className="w-full rounded-xl bg-primary px-5 py-3.5 text-sm font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60">
          {m.isPending ? "Posting…" : "Post my request"}
        </button>
      </form>
    </main>
  );
}

const inputCls = "w-full rounded-xl border border-input bg-background px-4 py-2.5 text-sm outline-none focus:border-ring";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-medium uppercase tracking-wider text-muted-foreground">{label}</span>
      {children}
    </label>
  );
}
