import { createFileRoute, Link } from "@tanstack/react-router";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useState, type FormEvent } from "react";
import { joinWaitlist, getWaitlistCount } from "@/lib/api/waitlist.functions";
import heroImage from "@/assets/hero-hands.jpg";
import chainImage from "@/assets/chain.jpg";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Goodwill Circle — A self-sustaining ecosystem of kindness" },
      {
        name: "description",
        content:
          "Goodwill Circle is a pay-it-forward network where help travels in chains. Join the waitlist and help us build the antidote to social media.",
      },
      { property: "og:title", content: "Goodwill Circle — Kindness, in chains." },
      {
        property: "og:description",
        content:
          "A new kind of social network: ask for help, give help, watch goodwill ripple outward.",
      },
      { property: "og:type", content: "website" },
    ],
  }),
  component: Landing,
});

function Landing() {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <Nav />
      <Hero />
      <What />
      <How />
      <Different />
      <Chains />
      <Validate />
      <CTA />
      <Footer />
    </main>
  );
}

function Nav() {
  return (
    <header className="absolute top-0 z-20 w-full">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-6">
        <a href="#top" className="flex items-center gap-2">
          <span className="grid h-8 w-8 place-items-center rounded-full bg-primary text-primary-foreground font-serif text-lg">
            ◯
          </span>
          <span className="font-serif text-xl">Goodwill Circle</span>
        </a>
        <div className="flex items-center gap-2 text-sm">
          <Link to="/auth" className="rounded-full px-4 py-2 font-medium text-muted-foreground hover:text-foreground">
            Sign in
          </Link>
          <Link to="/app" className="rounded-full bg-primary px-4 py-2 font-medium text-primary-foreground transition hover:opacity-90">
            Open app
          </Link>
        </div>
      </div>
    </header>
  );
}

function Hero() {
  return (
    <section id="top" className="relative overflow-hidden pt-28 pb-20 md:pt-36 md:pb-32">
      <div className="mx-auto grid max-w-6xl items-center gap-12 px-6 md:grid-cols-2">
        <div>
          <span className="inline-flex items-center gap-2 rounded-full bg-secondary px-3 py-1 text-xs font-medium uppercase tracking-widest text-muted-foreground">
            <span className="h-1.5 w-1.5 rounded-full bg-ember" /> Pre-launch · Phase 0
          </span>
          <h1 className="mt-6 font-serif text-5xl leading-[1.05] md:text-7xl">
            Kindness, <em className="text-ember">in chains.</em>
          </h1>
          <p className="mt-6 max-w-lg text-lg leading-relaxed text-muted-foreground">
            Goodwill Circle is a self-sustaining ecosystem where one act of help
            sparks the next. Not likes. Not followers. Real help, traveling
            person to person.
          </p>
          <WaitlistForm />
          <SocialProof />
        </div>
        <div className="relative">
          <div className="absolute -inset-6 -z-10 rounded-[2rem] bg-gradient-to-br from-accent/40 to-primary/20 blur-2xl" />
          <img
            src={heroImage}
            alt="Many hands of different skin tones reaching toward a shared center of light"
            width={1536}
            height={1152}
            className="rounded-[1.5rem] border border-border shadow-2xl"
          />
        </div>
      </div>
    </section>
  );
}

function WaitlistForm() {
  const countQuery = useQuery({
    queryKey: ["waitlist-count"],
    queryFn: () => getWaitlistCount(),
  });
  const [email, setEmail] = useState("");
  const [name, setName] = useState("");
  const mutation = useMutation({
    mutationFn: (vars: { email: string; name: string }) =>
      joinWaitlist({ data: { email: vars.email, name: vars.name } }),
    onSuccess: () => countQuery.refetch(),
  });

  const onSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    mutation.mutate({ email, name });
  };

  if (mutation.data?.ok) {
    return (
      <div className="mt-8 rounded-2xl border border-border bg-card p-6 shadow-sm">
        <p className="font-serif text-2xl text-ember">You're in. Thank you.</p>
        <p className="mt-2 text-sm text-muted-foreground">
          You're number <strong>{mutation.data.count}</strong> in the circle. We'll be
          in touch as we open early access.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} className="mt-8 max-w-md space-y-3" id="join">
      <div className="grid gap-3 sm:grid-cols-[1fr_1.3fr]">
        <input
          type="text"
          placeholder="Your name (optional)"
          value={name}
          onChange={(e) => setName(e.target.value)}
          maxLength={100}
          className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm outline-none transition focus:border-ring"
        />
        <input
          type="email"
          required
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          maxLength={255}
          className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm outline-none transition focus:border-ring"
        />
      </div>
      <button
        type="submit"
        disabled={mutation.isPending}
        className="w-full rounded-xl bg-primary px-5 py-3.5 text-sm font-semibold text-primary-foreground transition hover:opacity-90 disabled:opacity-60"
      >
        {mutation.isPending ? "Joining…" : "Reserve my spot"}
      </button>
      {mutation.data && !mutation.data.ok && (
        <p className="text-sm text-destructive">{mutation.data.error}</p>
      )}
      <p className="text-xs text-muted-foreground">
        No spam. One email when early access opens.
      </p>
    </form>
  );
}

function SocialProof() {
  const countQuery = useQuery({
    queryKey: ["waitlist-count"],
    queryFn: () => getWaitlistCount(),
  });
  const count = countQuery.data?.count ?? 0;
  return (
    <p className="mt-6 text-sm text-muted-foreground">
      <span className="font-semibold text-foreground">{count.toLocaleString()}</span>{" "}
      kind people already on the list · target: 100+ before we build
    </p>
  );
}

function What() {
  return (
    <section className="border-t border-border bg-secondary/40 py-24">
      <div className="mx-auto max-w-4xl px-6 text-center">
        <p className="text-xs font-medium uppercase tracking-widest text-ember">
          What is Goodwill Circle
        </p>
        <h2 className="mt-4 font-serif text-4xl md:text-5xl">
          A network built on <em>help given</em>, not attention earned.
        </h2>
        <p className="mt-6 text-lg leading-relaxed text-muted-foreground">
          Anyone can ask for help — with school, work, food, health, money, a place
          to stay, or just someone to listen. Anyone can give help. Every act earns
          credits that fund the next request. The whole thing keeps itself alive.
        </p>
      </div>
    </section>
  );
}

function How() {
  const steps = [
    {
      n: "01",
      title: "Ask or offer",
      body: "Post a request, or browse the ones nearby. First request is always free.",
    },
    {
      n: "02",
      title: "Help happens",
      body: "Someone steps in. You can stay public, or keep it fully anonymous.",
    },
    {
      n: "03",
      title: "Pay it forward",
      body: "Helping earns credits. Credits fund someone else's ask. The chain grows.",
    },
  ];
  return (
    <section className="py-24">
      <div className="mx-auto max-w-6xl px-6">
        <div className="max-w-2xl">
          <p className="text-xs font-medium uppercase tracking-widest text-ember">
            How pay-it-forward works
          </p>
          <h2 className="mt-4 font-serif text-4xl md:text-5xl">
            Three steps. No middlemen.
          </h2>
        </div>
        <div className="mt-14 grid gap-6 md:grid-cols-3">
          {steps.map((s) => (
            <div
              key={s.n}
              className="rounded-2xl border border-border bg-card p-8 transition hover:-translate-y-1 hover:shadow-xl"
            >
              <p className="font-serif text-5xl text-ember/70">{s.n}</p>
              <h3 className="mt-4 font-serif text-2xl">{s.title}</h3>
              <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
                {s.body}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Different() {
  const rows = [
    ["Currency", "Likes, follows, outrage", "Help completed, lives touched"],
    ["Feed", "What's loudest", "What's kindest"],
    ["Identity", "Personal brand", "Character passport"],
    ["Reactions", "Like, love, angry, sad", "Inspired, respect, thankful"],
    ["End state", "Doomscroll", "Goodwill chain"],
  ];
  return (
    <section className="border-y border-border bg-ink py-24 text-cream">
      <div className="mx-auto max-w-5xl px-6">
        <p className="text-xs font-medium uppercase tracking-widest text-accent">
          Why it's different
        </p>
        <h2 className="mt-4 font-serif text-4xl md:text-5xl">
          The opposite of social media.
        </h2>
        <div className="mt-12 overflow-hidden rounded-2xl border border-white/10">
          <table className="w-full text-left text-sm md:text-base">
            <thead className="bg-white/5">
              <tr>
                <th className="px-6 py-4 font-medium text-cream/60"></th>
                <th className="px-6 py-4 font-medium text-cream/60">Social media</th>
                <th className="px-6 py-4 font-medium text-accent">Goodwill Circle</th>
              </tr>
            </thead>
            <tbody>
              {rows.map(([k, a, b], i) => (
                <tr key={k} className={i % 2 ? "bg-white/[0.02]" : ""}>
                  <td className="px-6 py-4 font-serif text-lg">{k}</td>
                  <td className="px-6 py-4 text-cream/70 line-through decoration-cream/30">
                    {a}
                  </td>
                  <td className="px-6 py-4 text-cream">{b}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
}

function Chains() {
  return (
    <section className="py-24">
      <div className="mx-auto grid max-w-6xl items-center gap-14 px-6 md:grid-cols-2">
        <div>
          <p className="text-xs font-medium uppercase tracking-widest text-ember">
            Why goodwill chains matter
          </p>
          <h2 className="mt-4 font-serif text-4xl md:text-5xl">
            One act of help is a story. A thousand is a movement.
          </h2>
          <p className="mt-6 text-lg leading-relaxed text-muted-foreground">
            When A helps B, and B helps C, and C helps D — we trace it.
            We show you the chain. You'll see the names (or anonymous shadows) of
            everyone your kindness ever touched, even years later.
          </p>
          <div className="mt-8 grid grid-cols-3 gap-6">
            <Stat n="23" label="People helped" />
            <Stat n="104" label="Indirect impact" />
            <Stat n="127" label="Impact radius" />
          </div>
        </div>
        <div className="relative">
          <div className="absolute -inset-4 -z-10 rounded-[2rem] bg-gradient-to-tr from-ember/30 to-accent/30 blur-2xl" />
          <img
            src={chainImage}
            alt="A glowing chain of light passing from person to person across hills at dusk"
            width={1280}
            height={896}
            loading="lazy"
            className="rounded-[1.5rem] border border-border shadow-2xl"
          />
        </div>
      </div>
    </section>
  );
}

function Stat({ n, label }: { n: string; label: string }) {
  return (
    <div>
      <p className="font-serif text-4xl text-ember">{n}</p>
      <p className="mt-1 text-xs uppercase tracking-wider text-muted-foreground">
        {label}
      </p>
    </div>
  );
}

function Validate() {
  const qs = [
    "Would you help a stranger if it cost you nothing but time?",
    "Would you share a story of someone who helped you?",
    "Would a public character record change how you behave online?",
    "Would you join a campaign — a tree drive, a blood drive, a food drive?",
  ];
  return (
    <section className="border-t border-border bg-secondary/40 py-24">
      <div className="mx-auto max-w-4xl px-6">
        <p className="text-xs font-medium uppercase tracking-widest text-ember">
          We're testing four assumptions
        </p>
        <h2 className="mt-4 font-serif text-4xl md:text-5xl">
          Tell us we're not crazy.
        </h2>
        <p className="mt-4 text-muted-foreground">
          Phase 0 is about proving people actually want this. If you'd answer
          "yes" to any of these — you're our person.
        </p>
        <ul className="mt-10 space-y-4">
          {qs.map((q, i) => (
            <li
              key={q}
              className="flex items-start gap-4 rounded-2xl border border-border bg-card p-5"
            >
              <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-ember/10 font-serif text-ember">
                {i + 1}
              </span>
              <p className="font-serif text-xl leading-snug">{q}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}

function CTA() {
  return (
    <section className="py-28">
      <div className="mx-auto max-w-3xl px-6 text-center">
        <h2 className="font-serif text-5xl md:text-6xl">
          Be one of the <em className="text-ember">first hundred.</em>
        </h2>
        <p className="mt-5 text-lg text-muted-foreground">
          We need 100+ believers before we build. After that, you'll get early
          access, free credits, and a permanent founding-member badge on your
          character passport.
        </p>
        <a
          href="#join"
          className="mt-8 inline-block rounded-full bg-primary px-8 py-4 text-base font-semibold text-primary-foreground transition hover:opacity-90"
        >
          Reserve my spot
        </a>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="border-t border-border py-10">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 text-sm text-muted-foreground md:flex-row">
        <p>© {new Date().getFullYear()} Goodwill Circle — Phase 0</p>
        <p className="font-serif italic">"The smallest act, repeated, becomes a movement."</p>
      </div>
    </footer>
  );
}
