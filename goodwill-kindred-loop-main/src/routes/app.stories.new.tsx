import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { createStoryFn } from "@/lib/api/social.functions";
import { fileToDataUrl } from "@/lib/imageUpload";

export const Route = createFileRoute("/app/stories/new")({
  head: () => ({ meta: [{ title: "Share a story · Goodwill Circle" }] }),
  component: NewStory,
});

function NewStory() {
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [body, setBody] = useState("");
  const [mediaUrl, setMediaUrl] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const m = useMutation({
    mutationFn: () =>
      createStoryFn({
        data: { body: body.trim() || undefined, media_url: mediaUrl ?? undefined },
      }),
    onSuccess: (res) => {
      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["stories"] });
        navigate({ to: "/app" });
      }
    },
  });

  const onImage = async (file: File | undefined) => {
    setErr(null);
    if (!file) return setMediaUrl(null);
    try {
      setMediaUrl(await fileToDataUrl(file));
    } catch (e: any) {
      setErr(e?.message ?? "Could not read image.");
    }
  };

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!body.trim() && !mediaUrl) {
      setErr("Add a photo or write something.");
      return;
    }
    m.mutate();
  };

  return (
    <main className="mx-auto max-w-lg px-4 py-10">
      <h1 className="font-serif text-4xl">Share a story</h1>
      <p className="mt-2 text-muted-foreground">
        A small moment of goodwill — gone in 24 hours.
      </p>

      <form onSubmit={onSubmit} className="mt-8 space-y-4 rounded-2xl border border-border bg-card p-6">
        {mediaUrl ? (
          <div className="relative">
            <img src={mediaUrl} alt="" className="max-h-80 w-full rounded-xl object-cover" />
            <button type="button" onClick={() => setMediaUrl(null)}
              className="absolute right-2 top-2 rounded-full bg-black/60 px-3 py-1 text-xs text-white">
              Remove
            </button>
          </div>
        ) : (
          <label className="flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-dashed border-border bg-background px-4 py-8 text-sm text-muted-foreground hover:bg-secondary/50">
            <span>📷 Add a photo (optional)</span>
            <input type="file" accept="image/*" className="hidden"
              onChange={(e) => onImage(e.target.files?.[0])} />
          </label>
        )}

        <textarea value={body} onChange={(e) => setBody(e.target.value)} maxLength={280} rows={4}
          placeholder="Say something kind…"
          className="w-full rounded-xl border border-input bg-background px-4 py-2.5 text-sm outline-none focus:border-ring" />
        <p className="text-right text-[10px] text-muted-foreground">{body.length}/280</p>

        {(err || (m.data && !m.data.ok)) && (
          <p className="text-sm text-destructive">{err ?? (m.data && !m.data.ok && m.data.error)}</p>
        )}

        <button type="submit" disabled={m.isPending}
          className="w-full rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60">
          {m.isPending ? "Sharing…" : "Share story"}
        </button>
      </form>
    </main>
  );
}
