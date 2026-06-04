import { createFileRoute, Link, Outlet, redirect, useNavigate, useRouter } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { meFn, logoutFn } from "@/lib/api/auth.functions";
import { unreadCountFn } from "@/lib/api/profile.functions";

export const Route = createFileRoute("/app")({
  beforeLoad: async () => {
    const me = await meFn();
    if (!me) throw redirect({ to: "/auth" });
    return { user: me };
  },
  component: AppLayout,
});

function AppLayout() {
  const { user } = Route.useRouteContext();
  const qc = useQueryClient();
  const router = useRouter();
  const navigate = useNavigate();
  const meQuery = useQuery({ queryKey: ["me"], queryFn: () => meFn(), initialData: user });
  const unread = useQuery({ queryKey: ["unread"], queryFn: () => unreadCountFn(), refetchInterval: 30_000 });
  const logout = useMutation({
    mutationFn: () => logoutFn(),
    onSuccess: async () => {
      qc.clear();
      await router.invalidate();
      navigate({ to: "/auth" });
    },
  });

  const me = meQuery.data ?? user;
  const unreadCount = unread.data?.count ?? 0;

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="sticky top-0 z-30 border-b border-border bg-background/85 backdrop-blur">
        <nav className="mx-auto flex max-w-2xl items-center justify-between gap-3 px-4 py-3">
          <Link to="/app" className="flex items-center gap-2">
            <span className="grid h-7 w-7 place-items-center rounded-full bg-primary text-primary-foreground font-serif text-sm">◯</span>
            <span className="font-serif text-lg">Goodwill</span>
          </Link>

          <div className="hidden items-center gap-1 text-sm sm:flex">
            <NavLink to="/app">Feed</NavLink>
            <NavLink to="/app/new">Ask</NavLink>
            <NavLink to="/app/helpers">Helpers</NavLink>
            <NavLink to="/app/notifications">
              <span className="relative">
                Inbox
                {unreadCount > 0 && (
                  <span className="absolute -right-3 -top-1 grid h-4 min-w-4 place-items-center rounded-full bg-ember px-1 text-[10px] font-bold text-primary-foreground">
                    {unreadCount}
                  </span>
                )}
              </span>
            </NavLink>
            <NavLink to="/app/profile">Profile</NavLink>
          </div>

          <div className="flex items-center gap-2">
            <span className="rounded-full bg-secondary px-3 py-1 text-xs font-medium whitespace-nowrap">
              <span className="text-ember">●</span> {me?.credits ?? 0}
            </span>
            <button onClick={() => logout.mutate()} className="hidden text-xs text-muted-foreground hover:text-foreground sm:inline">
              Sign out
            </button>
            <Link to="/app/profile" className="sm:hidden">
              {me?.photo_url ? (
                <img src={me.photo_url} alt="" className="h-8 w-8 rounded-full object-cover" />
              ) : (
                <span className="grid h-8 w-8 place-items-center rounded-full bg-secondary font-serif text-xs">
                  {me?.name?.charAt(0).toUpperCase()}
                </span>
              )}
            </Link>
          </div>
        </nav>
      </header>

      <Outlet />

      {/* Mobile bottom nav */}
      <nav className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-background/95 backdrop-blur sm:hidden">
        <div className="mx-auto grid max-w-2xl grid-cols-5">
          <BottomLink to="/app" label="Feed" icon="◯" />
          <BottomLink to="/app/helpers" label="Helpers" icon="✦" />
          <BottomCenter />
          <BottomLink to="/app/notifications" label="Inbox" icon="◌" badge={unreadCount} />
          <BottomLink to="/app/profile" label="You" icon="◈" />
        </div>
      </nav>
    </div>
  );
}

function NavLink({ to, children }: { to: string; children: React.ReactNode }) {
  return (
    <Link
      to={to}
      className="rounded-full px-3 py-1.5 text-muted-foreground transition hover:bg-secondary hover:text-foreground"
      activeProps={{ className: "rounded-full px-3 py-1.5 bg-secondary text-foreground font-medium" }}
      activeOptions={{ exact: to === "/app" }}
    >
      {children}
    </Link>
  );
}

function BottomLink({ to, label, icon, badge }: { to: string; label: string; icon: string; badge?: number }) {
  return (
    <Link
      to={to}
      className="flex flex-col items-center gap-0.5 py-2 text-[10px] text-muted-foreground"
      activeProps={{ className: "flex flex-col items-center gap-0.5 py-2 text-[10px] text-ember font-semibold" }}
      activeOptions={{ exact: to === "/app" }}
    >
      <span className="relative text-lg leading-none">
        {icon}
        {badge && badge > 0 ? (
          <span className="absolute -right-2 -top-1 grid h-3.5 min-w-3.5 place-items-center rounded-full bg-ember px-1 text-[9px] font-bold text-primary-foreground">
            {badge}
          </span>
        ) : null}
      </span>
      {label}
    </Link>
  );
}

function BottomCenter() {
  return (
    <Link
      to="/app/new"
      className="flex flex-col items-center gap-0.5 py-1.5 text-[10px] text-muted-foreground"
    >
      <span className="grid h-9 w-9 place-items-center rounded-full bg-primary text-lg text-primary-foreground shadow-lg">
        +
      </span>
      Ask
    </Link>
  );
}
