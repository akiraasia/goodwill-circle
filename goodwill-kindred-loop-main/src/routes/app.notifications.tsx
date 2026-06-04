import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { listNotificationsFn, markAllReadFn } from "@/lib/api/profile.functions";

export const Route = createFileRoute("/app/notifications")({
  head: () => ({ meta: [{ title: "Inbox · Goodwill Circle" }] }),
  component: Inbox,
});

function Inbox() {
  const qc = useQueryClient();
  const q = useQuery({ queryKey: ["notifications"], queryFn: () => listNotificationsFn() });
  const m = useMutation({
    mutationFn: () => markAllReadFn(),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["notifications"] });
      qc.invalidateQueries({ queryKey: ["unread"] });
    },
  });

  return (
    <main className="mx-auto max-w-2xl px-4 py-10">
      <div className="flex items-center justify-between">
        <h1 className="font-serif text-4xl">Inbox</h1>
        <button onClick={() => m.mutate()} className="text-sm text-ember hover:underline">
          Mark all read
        </button>
      </div>

      <div className="mt-6 space-y-3">
        {q.data?.length === 0 && (
          <p className="rounded-2xl border border-dashed border-border bg-card p-8 text-center text-muted-foreground">
            Nothing yet. Help someone and watch this fill up.
          </p>
        )}
        {q.data?.map((n: any) => (
          <Link
            key={n.id}
            to={n.link ?? "/app"}
            className={
              "block rounded-xl border p-4 transition hover:-translate-y-0.5 hover:shadow-md " +
              (n.read ? "border-border bg-card" : "border-ember/40 bg-ember/5")
            }
          >
            <div className="flex items-start justify-between gap-3">
              <p className="text-sm">{n.message}</p>
              <span className="shrink-0 text-xs text-muted-foreground">
                {new Date(n.created_at).toLocaleDateString()}
              </span>
            </div>
          </Link>
        ))}
      </div>
    </main>
  );
}
