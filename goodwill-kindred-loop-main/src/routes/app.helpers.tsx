import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { topHelpersFn } from "@/lib/api/profile.functions";

export const Route = createFileRoute("/app/helpers")({
  head: () => ({ meta: [{ title: "Top helpers · Goodwill Circle" }] }),
  component: Helpers,
});

function Helpers() {
  const q = useQuery({ queryKey: ["helpers"], queryFn: () => topHelpersFn() });

  return (
    <main className="mx-auto max-w-2xl px-4 py-8 pb-24 sm:pb-10">
      <h1 className="font-serif text-4xl">Top helpers</h1>
      <p className="mt-2 text-sm text-muted-foreground">
        The people most often stepping in for others.
      </p>

      <div className="mt-8 overflow-hidden rounded-2xl border border-border bg-card">
        {q.isLoading && <p className="p-6 text-sm text-muted-foreground">Loading…</p>}
        {q.data?.length === 0 && (
          <p className="p-6 text-sm text-muted-foreground">No one has helped yet. Be the first.</p>
        )}
        {q.data?.map((h, i) => (
          <Link
            key={h.id}
            to="/app/u/$id"
            params={{ id: h.id }}
            className="flex items-center gap-4 border-b border-border px-5 py-3.5 transition last:border-b-0 hover:bg-secondary/40"
          >
            <span
              className={
                "grid h-7 w-7 place-items-center rounded-full text-xs font-bold " +
                (i === 0
                  ? "bg-ember text-primary-foreground"
                  : i < 3
                    ? "bg-accent/50 text-foreground"
                    : "bg-secondary text-muted-foreground")
              }
            >
              {i + 1}
            </span>
            {h.photo_url ? (
              <img src={h.photo_url} alt="" className="h-10 w-10 rounded-full object-cover" />
            ) : (
              <span className="grid h-10 w-10 place-items-center rounded-full bg-secondary font-serif">
                {h.name.charAt(0).toUpperCase()}
              </span>
            )}
            <div className="min-w-0 flex-1">
              <p className="truncate font-medium">{h.name}</p>
              <p className="text-xs text-muted-foreground">
                {h.people_helped} {h.people_helped === 1 ? "person" : "people"} helped
              </p>
            </div>
            <span className="text-xs text-ember">→</span>
          </Link>
        ))}
      </div>
    </main>
  );
}
