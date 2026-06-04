import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useState, type FormEvent } from "react";
import { getRequestFn, completeHelpFn, deleteRequestFn } from "@/lib/api/requests.functions";
import { listCommentsFn, addCommentFn, toggleReactionFn } from "@/lib/api/social.functions";

export const Route = createFileRoute("/app/requests/$id")({
  head: () => ({ meta: [{ title: "Request · Goodwill Circle" }] }),
  component: RequestDetail,
});

function RequestDetail() {
  const { id } = Route.useParams();
  const qc = useQueryClient();
  const navigate = useNavigate();
  const q = useQuery({ queryKey: ["request", id], queryFn: () => getRequestFn({ data: { id } }) });
  const comments = useQuery({
    queryKey: ["comments", id],
    queryFn: () => listCommentsFn({ data: { request_id: id } }),
  });
  const [message, setMessage] = useState("");
  const [commentText, setCommentText] = useState("");

  const help = useMutation({
    mutationFn: () => completeHelpFn({ data: { request_id: id, message } }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["request", id] });
      qc.invalidateQueries({ queryKey: ["me"] });
      qc.invalidateQueries({ queryKey: ["requests"] });
      setMessage("");
    },
  });

  const react = useMutation({
    mutationFn: () => toggleReactionFn({ data: { request_id: id, type: "cheer" } }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["request", id] });
      qc.invalidateQueries({ queryKey: ["requests"] });
    },
  });

  const addC = useMutation({
    mutationFn: () => addCommentFn({ data: { request_id: id, body: commentText.trim() } }),
    onSuccess: (res) => {
      if (res.ok) {
        setCommentText("");
        qc.invalidateQueries({ queryKey: ["comments", id] });
        qc.invalidateQueries({ queryKey: ["request", id] });
        qc.invalidateQueries({ queryKey: ["requests"] });
      }
    },
  });

  const remove = useMutation({
    mutationFn: () => deleteRequestFn({ data: { id } }),
    onSuccess: (res) => {
      if (res.ok) {
        qc.invalidateQueries({ queryKey: ["requests"] });
        navigate({ to: "/app" });
      }
    },
  });

  if (q.isLoading) return <p className="mx-auto max-w-2xl px-4 py-10 text-muted-foreground">Loading…</p>;
  if (!q.data) return (
    <main className="mx-auto max-w-2xl px-4 py-10">
      <p>Request not found.</p>
      <Link to="/app" className="text-ember underline">Back to feed</Link>
    </main>
  );
  const { request, completions } = q.data;
  const initial = request.anonymous ? "?" : (request.author_name ?? "?").charAt(0).toUpperCase();

  return (
    <main className="mx-auto max-w-2xl px-4 py-6 pb-24 sm:pb-10">
      <Link to="/app" className="text-sm text-muted-foreground hover:text-foreground">← Back to feed</Link>

      <article className="mt-4 overflow-hidden rounded-2xl border border-border bg-card">
        <header className="flex items-center gap-3 px-5 py-3.5">
          {request.anonymous ? (
            <span className="grid h-10 w-10 place-items-center rounded-full bg-secondary font-serif">{initial}</span>
          ) : (
            <Link to="/app/u/$id" params={{ id: request.profile_id }} className="grid h-10 w-10 place-items-center rounded-full bg-secondary font-serif hover:bg-secondary/70">
              {initial}
            </Link>
          )}
          <div className="min-w-0 flex-1">
            {request.anonymous ? (
              <p className="text-sm font-medium">Anonymous</p>
            ) : (
              <Link to="/app/u/$id" params={{ id: request.profile_id }} className="text-sm font-medium hover:underline">
                {request.author_name}
              </Link>
            )}
            <p className="text-xs text-muted-foreground">
              {request.category} · {request.level === "urgent" ? "Urgent" : request.level}
            </p>
          </div>
          {request.status === "helped" && (
            <span className="rounded-full bg-accent/40 px-2.5 py-1 text-xs font-medium">Helped</span>
          )}
          {request.is_mine && (
            <button
              onClick={() => confirm("Delete this request? This cannot be undone.") && remove.mutate()}
              className="text-xs text-muted-foreground hover:text-destructive"
            >
              Delete
            </button>
          )}
        </header>

        {request.media_url && (
          <img src={request.media_url} alt="" className="max-h-[600px] w-full bg-black object-cover" />
        )}

        <div className="flex items-center gap-5 px-5 pt-3 text-sm">
          <button
            onClick={() => react.mutate()}
            className={
              "flex items-center gap-1.5 transition active:scale-90 " +
              (request.i_reacted ? "text-ember" : "text-muted-foreground hover:text-foreground")
            }
          >
            <span className="text-xl leading-none">{request.i_reacted ? "♥" : "♡"}</span>
            <span className="text-xs font-medium">{request.reaction_count}</span>
          </button>
          <span className="flex items-center gap-1.5 text-muted-foreground">
            <span className="text-lg leading-none">◌</span>
            <span className="text-xs font-medium">{request.comment_count}</span>
          </span>
        </div>

        <div className="px-5 pb-5 pt-2">
          <h1 className="font-serif text-3xl leading-tight">{request.title}</h1>
          <p className="mt-3 whitespace-pre-wrap text-sm leading-relaxed text-foreground/90">{request.description}</p>
        </div>
      </article>

      {request.can_help ? (
        <div className="mt-6 rounded-2xl border border-border bg-card p-6">
          <h2 className="font-serif text-2xl">I can help with this</h2>
          <p className="mt-1 text-sm text-muted-foreground">You'll earn +15 credits. Leave a short note if you'd like.</p>
          <textarea value={message} onChange={(e) => setMessage(e.target.value)} maxLength={500} rows={3}
            placeholder="What you did, what you can offer, how to reach you…"
            className="mt-4 w-full rounded-xl border border-input bg-background px-4 py-2.5 text-sm outline-none focus:border-ring" />
          {help.data && !help.data.ok && <p className="mt-2 text-sm text-destructive">{help.data.error}</p>}
          <button onClick={() => help.mutate()} disabled={help.isPending}
            className="mt-3 rounded-xl bg-primary px-5 py-2.5 text-sm font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60">
            {help.isPending ? "Recording…" : "I helped"}
          </button>
        </div>
      ) : request.is_mine ? (
        <p className="mt-6 rounded-2xl border border-dashed border-border bg-secondary/40 p-6 text-sm text-muted-foreground">
          This is your request. You'll be notified when someone helps.
        </p>
      ) : null}

      <section className="mt-8">
        <h3 className="font-serif text-2xl">Comments</h3>
        <CommentForm
          value={commentText}
          onChange={setCommentText}
          onSubmit={(e) => {
            e.preventDefault();
            if (commentText.trim()) addC.mutate();
          }}
          pending={addC.isPending}
        />
        <div className="mt-4 space-y-3">
          {comments.data?.length === 0 && <p className="text-sm text-muted-foreground">Be the first to say something kind.</p>}
          {comments.data?.map((c) => (
            <div key={c.id} className="rounded-xl border border-border bg-card p-3">
              <div className="flex items-center justify-between text-sm">
                <span className="font-medium">{c.author_name}</span>
                <span className="text-xs text-muted-foreground">{timeAgo(c.created_at)}</span>
              </div>
              <p className="mt-1 whitespace-pre-wrap text-sm">{c.body}</p>
            </div>
          ))}
        </div>
      </section>

      <h3 className="mt-10 font-serif text-2xl">Helpers ({completions.length})</h3>
      <div className="mt-4 space-y-3">
        {completions.length === 0 && <p className="text-sm text-muted-foreground">No one has stepped in yet.</p>}
        {completions.map((c: any) => (
          <div key={c.id} className="rounded-xl border border-border bg-card p-4">
            <div className="flex items-center justify-between text-sm">
              <span className="font-medium">{c.helper_name}</span>
              <span className="text-xs text-muted-foreground">{new Date(c.completed_at).toLocaleString()}</span>
            </div>
            {c.message && <p className="mt-2 text-sm text-muted-foreground">{c.message}</p>}
          </div>
        ))}
      </div>
    </main>
  );
}

function CommentForm({
  value, onChange, onSubmit, pending,
}: { value: string; onChange: (v: string) => void; onSubmit: (e: FormEvent) => void; pending: boolean }) {
  return (
    <form onSubmit={onSubmit} className="mt-3 flex gap-2">
      <input value={value} onChange={(e) => onChange(e.target.value)} maxLength={500}
        placeholder="Add a comment…"
        className="flex-1 rounded-xl border border-input bg-background px-4 py-2.5 text-sm outline-none focus:border-ring" />
      <button type="submit" disabled={pending || !value.trim()}
        className="rounded-xl bg-primary px-4 py-2.5 text-sm font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-50">
        Post
      </button>
    </form>
  );
}

function timeAgo(iso: string) {
  const s = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  return `${Math.floor(s / 86400)}d`;
}
