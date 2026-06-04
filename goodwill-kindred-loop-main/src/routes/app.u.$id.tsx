import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { getPublicProfileFn } from "@/lib/api/profile.functions";

export const Route = createFileRoute("/app/u/$id")({
  head: () => ({ meta: [{ title: "Profile · Goodwill Circle" }] }),
  component: PublicProfile,
});

function PublicProfile() {
  const { id } = Route.useParams();
  const q = useQuery({ queryKey: ["profile", id], queryFn: () => getPublicProfileFn({ data: { id } }) });

  if (q.isLoading) return <p className="mx-auto max-w-2xl px-4 py-10 text-muted-foreground">Loading…</p>;
  if (!q.data) return (
    <main className="mx-auto max-w-2xl px-4 py-10">
      <p>Profile not found.</p>
      <Link to="/app" className="text-ember underline">Back to feed</Link>
    </main>
  );

  const { profile, requests_made, people_helped, requests } = q.data;

  return (
    <main className="mx-auto max-w-2xl px-4 py-8 pb-24 sm:pb-10">
      <Link to="/app" className="text-sm text-muted-foreground hover:text-foreground">← Back</Link>

      <div className="mt-4 flex items-center gap-5">
        {profile.photo_url ? (
          <img src={profile.photo_url} alt="" className="h-20 w-20 rounded-full object-cover" />
        ) : (
          <div className="grid h-20 w-20 place-items-center rounded-full bg-ember/15 font-serif text-3xl text-ember">
            {profile.name.charAt(0).toUpperCase()}
          </div>
        )}
        <div>
          <h1 className="font-serif text-3xl">{profile.name}</h1>
          <p className="text-xs text-muted-foreground">
            Joined {new Date(profile.created_at).toLocaleDateString()}
          </p>
        </div>
      </div>

      <div className="mt-6 grid grid-cols-2 gap-3">
        <div className="rounded-2xl border border-border bg-card p-4">
          <p className="font-serif text-2xl">{people_helped}</p>
          <p className="text-xs uppercase tracking-wider text-muted-foreground">People helped</p>
        </div>
        <div className="rounded-2xl border border-border bg-card p-4">
          <p className="font-serif text-2xl">{requests_made}</p>
          <p className="text-xs uppercase tracking-wider text-muted-foreground">Requests posted</p>
        </div>
      </div>

      <h2 className="mt-10 font-serif text-2xl">Recent requests</h2>
      <div className="mt-4 space-y-3">
        {requests.length === 0 && (
          <p className="text-sm text-muted-foreground">No public requests yet.</p>
        )}
        {requests.map((r: any) => (
          <Link
            key={r.id}
            to="/app/requests/$id"
            params={{ id: r.id }}
            className="block rounded-xl border border-border bg-card p-4 transition hover:-translate-y-0.5 hover:shadow"
          >
            <div className="flex items-center gap-2 text-xs">
              <span className="rounded-full bg-secondary px-2 py-0.5 font-medium">{r.category}</span>
              {r.level === "urgent" && (
                <span className="rounded-full bg-destructive/10 px-2 py-0.5 font-medium text-destructive">Urgent</span>
              )}
              {r.status === "helped" && (
                <span className="rounded-full bg-accent/40 px-2 py-0.5 font-medium">Helped</span>
              )}
              <span className="ml-auto text-muted-foreground">{new Date(r.created_at).toLocaleDateString()}</span>
            </div>
            <p className="mt-2 font-serif text-lg leading-snug">{r.title}</p>
          </Link>
        ))}
      </div>
    </main>
  );
}
