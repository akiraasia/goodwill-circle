import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { listRequestsFn, CATEGORIES, deleteRequestFn, type FeedRequest } from "@/lib/api/requests.functions";
import { listStoriesFn, toggleReactionFn, deleteStoryFn, type Story } from "@/lib/api/social.functions";
import { meFn } from "@/lib/api/auth.functions";

export const Route = createFileRoute("/app/")({
  head: () => ({ meta: [{ title: "Feed · Goodwill Circle" }] }),
  component: Feed,
});

function Feed() {
  const [category, setCategory] = useState<string>("All");
  const [openStory, setOpenStory] = useState<Story | null>(null);
  const qc = useQueryClient();

  const me = useQuery({ queryKey: ["me"], queryFn: () => meFn() });
  const stories = useQuery({ queryKey: ["stories"], queryFn: () => listStoriesFn() });
  const q = useQuery({
    queryKey: ["requests", category],
    queryFn: () => listRequestsFn({ data: { category } }),
  });

  const react = useMutation({
    mutationFn: (id: string) => toggleReactionFn({ data: { request_id: id, type: "cheer" } }),
    onMutate: async (id) => {
      await qc.cancelQueries({ queryKey: ["requests", category] });
      const prev = qc.getQueryData<FeedRequest[]>(["requests", category]);
      qc.setQueryData<FeedRequest[]>(["requests", category], (old) =>
        old?.map((r) =>
          r.id === id
            ? {
                ...r,
                i_reacted: !r.i_reacted,
                reaction_count: r.reaction_count + (r.i_reacted ? -1 : 1),
              }
            : r,
        ),
      );
      return { prev };
    },
    onError: (_e, _id, ctx) => ctx?.prev && qc.setQueryData(["requests", category], ctx.prev),
  });

  const removeRequest = useMutation({
    mutationFn: (id: string) => deleteRequestFn({ data: { id } }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["requests"] }),
  });

  return (
    <main className="mx-auto max-w-2xl px-4 py-6 pb-24 sm:pb-8">
      <StoriesStrip
        stories={stories.data ?? []}
        meId={me.data?.id}
        onOpen={setOpenStory}
      />

      <div className="mt-6 -mx-4 overflow-x-auto px-4 sm:mx-0 sm:px-0">
        <div className="flex gap-2 pb-1">
          {["All", ...CATEGORIES].map((c) => (
            <button
              key={c}
              onClick={() => setCategory(c)}
              className={
                "shrink-0 rounded-full border px-3 py-1.5 text-xs transition " +
                (category === c
                  ? "border-ember bg-ember text-primary-foreground"
                  : "border-border bg-card text-muted-foreground hover:bg-secondary")
              }
            >
              {c}
            </button>
          ))}
        </div>
      </div>

      <div className="mt-6 space-y-5">
        {q.isLoading && <p className="text-muted-foreground">Loading…</p>}
        {q.data?.length === 0 && (
          <div className="rounded-2xl border border-dashed border-border bg-card p-10 text-center">
            <p className="font-serif text-2xl">Nothing here yet.</p>
            <p className="mt-2 text-sm text-muted-foreground">Be the first to ask, or post a story.</p>
          </div>
        )}
        {q.data?.map((r) => (
          <PostCard
            key={r.id}
            r={r}
            onReact={() => react.mutate(r.id)}
            onDelete={() => {
              if (confirm("Delete this request? This cannot be undone.")) removeRequest.mutate(r.id);
            }}
          />
        ))}
      </div>

      {openStory && (
        <StoryViewer
          story={openStory}
          isMine={openStory.profile_id === me.data?.id}
          onClose={() => setOpenStory(null)}
          onDelete={() => {
            deleteStoryFn({ data: { id: openStory.id } }).then(() => {
              qc.invalidateQueries({ queryKey: ["stories"] });
              setOpenStory(null);
            });
          }}
        />
      )}
    </main>
  );
}

function StoriesStrip({
  stories, meId, onOpen,
}: { stories: Story[]; meId?: string; onOpen: (s: Story) => void }) {
  return (
    <div className="-mx-4 overflow-x-auto px-4 sm:mx-0 sm:px-0">
      <div className="flex items-start gap-4">
        <Link to="/app/stories/new" className="group flex w-16 shrink-0 flex-col items-center gap-1.5">
          <span className="grid h-16 w-16 place-items-center rounded-full border-2 border-dashed border-ember/60 bg-card text-2xl text-ember transition group-hover:scale-105">
            +
          </span>
          <span className="text-[10px] uppercase tracking-wider text-muted-foreground">Your story</span>
        </Link>
        {stories.length === 0 && (
          <p className="self-center text-sm text-muted-foreground">
            Share a moment of goodwill.
          </p>
        )}
        {stories.map((s) => (
          <button
            key={s.id}
            onClick={() => onOpen(s)}
            className="group flex w-16 shrink-0 flex-col items-center gap-1.5"
          >
            <span className="rounded-full bg-gradient-to-tr from-ember via-primary to-accent p-[2px] transition group-hover:scale-105">
              <span
                className="grid h-[60px] w-[60px] place-items-center overflow-hidden rounded-full border-2 border-background bg-card font-serif text-lg text-ember"
                style={
                  s.media_url
                    ? { backgroundImage: `url(${s.media_url})`, backgroundSize: "cover", backgroundPosition: "center" }
                    : undefined
                }
              >
                {!s.media_url && s.author_name.charAt(0).toUpperCase()}
              </span>
            </span>
            <span className="line-clamp-1 max-w-[64px] text-[10px] text-muted-foreground">
              {s.profile_id === meId ? "You" : s.author_name.split(" ")[0]}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}

function StoryViewer({
  story, isMine, onClose, onDelete,
}: { story: Story; isMine: boolean; onClose: () => void; onDelete: () => void }) {
  return (
    <div onClick={onClose} className="fixed inset-0 z-50 grid place-items-center bg-black/80 p-4 backdrop-blur-sm">
      <div
        onClick={(e) => e.stopPropagation()}
        className="relative aspect-[9/16] w-full max-w-sm overflow-hidden rounded-2xl bg-neutral-900 text-white shadow-2xl"
      >
        {story.media_url ? (
          <img src={story.media_url} alt="" className="h-full w-full object-cover" />
        ) : (
          <div className="grid h-full place-items-center bg-gradient-to-br from-ember via-primary to-accent p-8 text-center font-serif text-3xl leading-tight">
            {story.body}
          </div>
        )}
        <div className="absolute inset-x-0 top-0 flex items-center gap-2 bg-gradient-to-b from-black/60 to-transparent p-4 text-sm">
          <Link
            to="/app/u/$id"
            params={{ id: story.profile_id }}
            className="flex items-center gap-2"
            onClick={onClose}
          >
            <span className="grid h-8 w-8 place-items-center rounded-full bg-white/20 font-serif">
              {story.author_name.charAt(0)}
            </span>
            <span className="font-medium">{story.author_name}</span>
          </Link>
          <span className="ml-auto text-xs opacity-70">{timeAgo(story.created_at)}</span>
        </div>
        {story.media_url && story.body && (
          <p className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/80 to-transparent p-4 pb-16 text-sm">
            {story.body}
          </p>
        )}
        <div className="absolute right-2 top-14 flex flex-col gap-2">
          {isMine && (
            <button
              onClick={() => confirm("Delete this story?") && onDelete()}
              className="rounded-full bg-black/40 px-3 py-1 text-xs"
            >
              Delete
            </button>
          )}
        </div>
        <button onClick={onClose} className="absolute right-2 top-2 grid h-8 w-8 place-items-center rounded-full bg-black/40 text-white">
          ×
        </button>
      </div>
    </div>
  );
}

function PostCard({ r, onReact, onDelete }: { r: FeedRequest; onReact: () => void; onDelete: () => void }) {
  const urgent = r.level === "urgent";
  const helped = r.status === "helped";
  const initial = r.anonymous ? "?" : (r.author_name ?? "?").charAt(0).toUpperCase();
  const [menu, setMenu] = useState(false);

  return (
    <article className="overflow-hidden rounded-2xl border border-border bg-card">
      <header className="flex items-center gap-3 px-4 py-3">
        {r.anonymous || !r.author_id ? (
          <span className="grid h-9 w-9 place-items-center rounded-full bg-secondary font-serif text-sm">
            {initial}
          </span>
        ) : (
          <Link to="/app/u/$id" params={{ id: r.author_id }} className="grid h-9 w-9 place-items-center rounded-full bg-secondary font-serif text-sm hover:bg-secondary/70">
            {initial}
          </Link>
        )}
        <div className="min-w-0">
          {r.anonymous || !r.author_id ? (
            <p className="truncate text-sm font-medium">Anonymous</p>
          ) : (
            <Link to="/app/u/$id" params={{ id: r.author_id }} className="truncate text-sm font-medium hover:underline">
              {r.author_name}
            </Link>
          )}
          <p className="text-xs text-muted-foreground">{r.category} · {timeAgo(r.created_at)}</p>
        </div>
        <div className="ml-auto flex items-center gap-1.5">
          {urgent && <span className="rounded-full bg-destructive/10 px-2 py-0.5 text-[10px] font-semibold text-destructive">Urgent</span>}
          {helped && <span className="rounded-full bg-accent/40 px-2 py-0.5 text-[10px] font-semibold">Helped</span>}
          {r.is_mine && (
            <div className="relative">
              <button onClick={() => setMenu((m) => !m)} className="grid h-7 w-7 place-items-center rounded-full text-muted-foreground hover:bg-secondary">
                ⋯
              </button>
              {menu && (
                <div className="absolute right-0 top-8 z-10 w-32 overflow-hidden rounded-xl border border-border bg-card shadow-lg">
                  <button
                    onClick={() => { setMenu(false); onDelete(); }}
                    className="block w-full px-3 py-2 text-left text-xs text-destructive hover:bg-secondary"
                  >
                    Delete
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </header>

      {r.media_url && (
        <Link to="/app/requests/$id" params={{ id: r.id }} className="block bg-black">
          <img src={r.media_url} alt="" className="max-h-[520px] w-full object-cover" />
        </Link>
      )}

      <div className="flex items-center gap-4 px-4 pt-3 text-sm">
        <button
          onClick={onReact}
          className={
            "flex items-center gap-1.5 transition active:scale-90 " +
            (r.i_reacted ? "text-ember" : "text-muted-foreground hover:text-foreground")
          }
        >
          <span className="text-lg leading-none">{r.i_reacted ? "♥" : "♡"}</span>
          <span className="text-xs font-medium">{r.reaction_count}</span>
        </button>
        <Link to="/app/requests/$id" params={{ id: r.id }} className="flex items-center gap-1.5 text-muted-foreground hover:text-foreground">
          <span className="text-lg leading-none">◌</span>
          <span className="text-xs font-medium">{r.comment_count}</span>
        </Link>
        <Link to="/app/requests/$id" params={{ id: r.id }} className="ml-auto text-xs font-medium text-ember hover:underline">
          {r.status === "open" ? "I can help →" : "Open thread →"}
        </Link>
      </div>

      <Link to="/app/requests/$id" params={{ id: r.id }} className="block px-4 pb-4 pt-2">
        <h3 className="font-serif text-xl leading-snug">{r.title}</h3>
        <p className="mt-1 line-clamp-3 text-sm text-muted-foreground">{r.description}</p>
      </Link>
    </article>
  );
}

function timeAgo(iso: string) {
  const s = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  return `${Math.floor(s / 86400)}d`;
}
