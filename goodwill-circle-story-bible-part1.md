# GOODWILL CIRCLE
## Complete Interactive Story Bible — Part 1 of 5
### World · Timeline · Player · Virtue System

---

## HOW THIS BIBLE IS ORGANIZED

Given the scale of what's being built, this document is delivered in five parts:

- **Part 1 (this file):** World, Timeline, Player, Virtue System
- **Part 2:** Regions (10–15, fully detailed)
- **Part 3:** Companions (10) and Antagonists
- **Part 4:** Main Story — 12 chapters, full VN scripts, symbolic encounters, real-world app integration
- **Part 5:** Endings catalog, NPC database, Item database, Visual/Sound design bibles, JSON schema

Everything is designed to be internally consistent — names, dates, and locations introduced here will recur exactly across the later parts so writers and engineers can cross-reference safely.

---

# SECTION 1 — THE WORLD

## 1.1 Name of the World

**Emberfold** — a temperate, mid-sized continent-island, roughly the size of the British Isles, ringed by the **Quiet Sea** to the west and the shallow, warm **Lantern Straits** to the east. The name comes from the old belief that the land was folded into shape by embers falling from a dying star — a soft, domestic creation myth rather than a violent one, setting the tone for the whole game.

## 1.2 Creation Myth: "The Last Ember and the First Hearth"

Long before people, the sky held a second sun called **Vael**, an old and tired star that had given its light for longer than counting. Vael grew cold and began to crumble, and as it did, it wept embers down into the dark.

Most embers died in the void. But some fell into the Quiet Sea and did not go out. They sank to the seafloor and kept glowing, stubborn as a coal in ash, until the sea itself grew warm around them and the warmth pushed the land up out of the water — folded, wrinkled, uneven, the way a blanket folds when someone pulls it up over themselves at night.

The last ember, the biggest of them, did not sink. It caught in the crook of two mountains and stayed there, burning low and steady. People say this is why the valley between **Mount Ilse** and **Mount Corrow** is always a little warmer than it should be, why crops grow there even in early frost, and why the old Emberfolk built their first hearth-fire from a coal they swore was "borrowed" from that very ember, carried down the mountain in a clay jar by a nameless woman remembered only as **the First Keeper**.

The creation myth's central metaphor, taught to every child: *a dying thing can still give warmth to something new, if it's willing to fall toward someone instead of into nothing.* This directly seeds the game's pay-it-forward theme — help is not infinite by nature, but it becomes infinite when passed on.

There is no single creator god. Emberfolk religion (see 1.9) is built around **tending**, not worship — the ember must be *fed*, not *praised*.

## 1.3 History (Broad Strokes — full detail in Section 2 Timeline)

Three broad ages:

1. **The Kindling Age** — scattered clans, survival, first hearths, first laws of hospitality (a stranger must be fed before questioned — this becomes a running cultural rule).
2. **The Woven Age** — clans link by marriage, trade, and shared festivals; first roads; first written language (**Ashglyphs**); rise of city-states around natural hot springs.
3. **The Ledger Age** (current) — a mercantile, increasingly individualistic era. Cities grew rich, but a slow social fraying set in: people stopped needing each other for survival, and with that need went a lot of the old hospitality customs. This is the era the game is set in, and it is the *current crisis* (see 1.14).

## 1.4 Culture

Emberfolk culture centers on **debt of kindness**, called locally a **glowdebt** — not a financial concept but a social one. If someone helps you, custom holds you don't repay them directly (that would insult the gift) — you "pass the glow" to someone else. This is a real, lived custom with etiquette, superstition, and generational drift, and it is the direct cultural ancestor of the in-game (and real-world) Goodwill Circle mechanic.

Key cultural touchstones:
- **Hospitality-first law:** feed or shelter a stranger before asking their business. Widely honored in villages, increasingly ignored in the capital — a visible marker of the "current crisis."
- **Naming days, not birthdays:** Emberfolk celebrate the day they were *named* (usually 7 days after birth, when a child's temperament first shows), not the day they were born, reflecting a belief that who you become matters more than the fact you exist.
- **The Quiet Hour:** every settlement observes one hour after sunset where shops close and people are expected to sit with family or neighbors — increasingly abandoned in cities, treasured in villages.
- **Storyswapping:** formal social ritual where two strangers trade one true personal story before any business or negotiation. Player will encounter this constantly and can choose to engage sincerely or brush past it (with relationship consequences).

## 1.5 Architecture

- **Villages:** round, thatch-and-timber homes with deliberately low doorways (you must bow slightly to enter anyone's home — humility built into the architecture itself).
- **Market towns:** stone and timber, built around a central **hearthsquare** with a permanently lit communal fire that must never go out (tending it is a rotating civic duty — a literal, physical embodiment of "keeping the ember alive").
- **The capital, Ledgerhall City:** the odd one out — tall, glass-and-brass towers, an obsession with visible wealth, "counting-spires" where merchant guilds track trade. Deliberately colder, more angular, more impressive and less human than everywhere else. This is where the fraying is worst.
- **Sacred/liminal sites:** built low, round, and windowless-but-skylit, always facing the two mountains from the creation myth.

## 1.6 Economy

Dual economy:
- **The Ledger** — formal currency (**hearthmarks**, small clay-and-copper discs) used for trade, taxes, rent.
- **The Glow** — informal, unenforceable, but socially binding reputation economy tracking who has helped whom. No official record exists; it lives in gossip, memory, and community trust. Player's core stats (see Virtue System) are effectively the game's dramatization of the Glow economy. Tension between Ledger-thinking and Glow-thinking is a major thematic engine — Ledgerhall City runs almost entirely on Ledger logic and has all but forgotten the Glow, which is part of the crisis.

## 1.7 Transportation

- **Foot and cart** in villages.
- **Rivercraft** — flat barges along the **Sillow River**, the main trade artery, poled by professional **river-callers** who sing schedules and news to riverside towns (a good vector for gossip/exposition and a job the player might briefly take up).
- **Steam-lanterns** — a new, expensive, coal-and-glass rail technology only in Ledgerhall City; symbol of the Ledger Age's disconnect from the old ways, resented by rural regions who feel left behind (real social tension, not cartoonish).

## 1.8 Food

Warm, communal, stew-and-bread culture. Signature dishes:
- **Emberbread** — a slow-baked, faintly sweet flatbread traditionally torn and shared, never cut with a knife (cutting shared bread is a real social faux pas).
- **Keeper's Stew** — a stew where every household adds one ingredient over the week; by the time it's served it represents an entire neighborhood's contribution. A natural in-fiction metaphor for collective care, and a strong candidate for a real "Heart Encounter" cooking mini-game.
- **Straitfish** — smoked fish from the Lantern Straits, a delicacy inland, plain fare on the coast — good vector for regional economic contrast.

## 1.9 Religion — "Tending," not Worship

No pantheon, no clergy hierarchy. Instead, small community roles called **Keepers** (echoing the First Keeper myth) — ordinary people, usually elected informally by respect rather than institution, responsible for tending a settlement's hearthfire, resolving small disputes, and remembering community history orally. Being a Keeper is a duty, not a privilege — it is explicitly *not* glamorous, and reluctant Keepers are common and beloved archetypes (good companion material).

Core tenet, taught to children as a rhyme:
*"Not the fire, but the feeding. Not the flame, but who it's for."*

## 1.10 Festivals

- **Kindling Eve** (once a year, start of winter): everyone extinguishes their home fire and must ask a neighbor for a light to restart it — enforced, ritualized dependence, deliberately uncomfortable for prideful people.
- **The Long Table** (harvest): every street sets up one continuous table down its length; no one eats at their own table, only at a stranger's.
- **Naming Days** (personal, not fixed calendar): whole-street celebration when a child of the block is named.
- **The Hush** (spring, solemn): a full day of silence to remember the dead of the **Cracking Winter** (see Timeline) — no music, no markets, only visiting.

## 1.11 Legends

- **The First Keeper** (creation myth figure) — said to still walk the mountain passes helping lost travelers; sightings are treated the way ghost stories are, half-believed, comforting rather than frightening.
- **The Debt-Eater** — a folkloric monster said to appear to people who take and take without ever passing kindness on; not a real monster but a moral fable told to children (and, notably, quietly *not* believed by adults — a good texture detail: this is a story for children, not literal theology, which keeps the tone from becoming superstitious/heavy).
- **The Weeping Bridge of Corrow** — a real, ordinary stone bridge where legend says if you help a stranger cross it, you'll be helped at your own hardest crossing. No magic is confirmed to be real here; it's left ambiguous, which suits the tone.

## 1.12 Languages

- **Common Hearth-tongue** — the spoken and written language of daily life, used across all regions with local dialects.
- **Ashglyphs** — an older written script, angular, soot-and-ash based (originally written by finger in cooled ash before ink), now ceremonial/historical, still used on monuments, gravestones, and Keeper record-scrolls. Player will need help translating Ashglyphs in a couple of puzzles.

## 1.13 Weather

Emberfold has mild, wet winters and warm, golden-hour-heavy summers — a deliberately cozy climate. The one exception is the recurring **Grey Damp**, a weeks-long fog that settles over the Sillow river valley in late autumn, historically associated with isolation, low mood, and (per the Cracking Winter, Timeline 2.6) real tragedy — narratively useful as a mechanism for forcing found-family closeness scenes.

## 1.14 Magic System

Deliberately *soft and ambiguous* magic, in the Ghibli tradition — never mechanized, never a combat resource.

- **Emberlight**: a very small, real phenomenon where certain old hearthfires (never new ones) glow faintly blue at the edges when a genuinely selfless act has recently occurred nearby. Scientifically unexplained in-world; some call it superstition, some treat it as fact. The player will witness it directly at key emotional beats, which is the game's way of "keeping score" on found virtue without ever putting a hard number on screen.
- No spellcasting, no player-controlled magic. Magic exists only as environmental *response* to genuine kindness, never as a tool the player wields.

## 1.15 Natural Wonders

- **The Two Mountains, Ilse and Corrow** — the creation-myth peaks; visible from nearly everywhere, a constant compass point.
- **The Glasslake** — an unnaturally still lake said to reflect not the sky but "what's true," used narratively as a mirror-encounter location (a character sees themselves honestly here).
- **The Hollow Orchard** — an old, half-wild apple orchard that blooms twice a year instead of once; nobody knows why; a beloved make-out/reflection spot for NPCs and a recurring date-scene location for companion routes.

## 1.16 Hidden Places

- **The Underhearth** — a real network of old tunnels beneath Ledgerhall City, originally built to move heat from a natural vent to warm the first buildings, now mostly forgotten, home to a small community of people the Ledger economy left behind. Major late-game location.
- **The Quiet Chapel of Corrow** — unmarked on any map, keeps no Keeper, visited only by word of mouth; a place people go to say things out loud they can't say to another person yet. No mechanics attached — purely a place for a wordless, beautiful scene.

## 1.17 Current Crisis

The Ledger Age has quietly hollowed out the old mutual-aid customs. Formally, nothing is wrong — trade is up, Ledgerhall City is richer than ever. Informally: fewer people answer a knock at the door, glowdebts go unpaid and unnoticed, Keepers are aging out with no one willing to take the (unpaid, thankless) role, and loneliness is rising in a world that used to consider isolation nearly impossible. There is no villain causing this — it is a slow, structural, believable social drift, which is the whole point. The antagonists (Part 3) will each represent a different *human, sympathetic* response to this drift, rather than a cause of it.

---

# SECTION 2 — TIMELINE

*(Every entry includes cause, consequence, historical importance, key figures, and political/social effects, as required. Dates are given in Emberfold's calendar, "Years of the Ember," abbreviated Y.E., counted from the founding of the first permanent hearthsquare.)*

### Y.E. 0 — The First Hearth Is Lit
**Cause:** The First Keeper carries a coal down from the mountain crook (per creation myth) and lights the first communal fire in what will become the village of **Corrowmere**.
**Consequence:** Nomadic clans in the valley begin to settle permanently around the fire rather than following herds.
**Historical importance:** Marks Year Zero of the calendar; the hearthsquare becomes the template for every settlement afterward.
**Key figures:** The First Keeper (name lost to history — this anonymity is intentional and thematically important: the founding act of the whole culture was performed by someone who is *not* remembered as a hero, only as an act).
**Political/social effects:** Establishes the "tending duty" as the seed of all later Keeper roles.

### Y.E. 40 — The Hospitality Law is spoken into custom
**Cause:** A hard winter (unnamed, predates written record) in which several travelling clans nearly died being turned away from settled hearths.
**Consequence:** Corrowmere's Keepers publicly declare that any stranger must be fed and sheltered one night before being asked their business or turned away.
**Historical importance:** First recorded social law of Emberfold; still binding by custom (not written law) in the present day.
**Social effects:** Becomes the foundation of the "glowdebt" economy — the first recorded act of helping-without-immediate-repayment.

### Y.E. 112 — The Woven Age begins: the Three Clans Accord
**Cause:** Three rival valley clans (Corrow, Ilse, and the river-clan Sillow) go to the edge of open conflict over grazing rights.
**Consequence:** Instead of war, the clans' Keepers negotiate the first intermarriage accord and shared festival calendar — the origin of the Long Table festival.
**Key figures:** **Keeper Rennet of Corrow**, **Keeper Aveline of Ilse**, and **River-caller Tobb of Sillow** — the three are still referenced in modern oaths ("by Rennet, Aveline, and Tobb").
**Political effects:** Establishes the precedent that Emberfold resolves conflict through shared meals and mutual obligation rather than combat — directly sets up the game's "no combat" design philosophy in-fiction.

### Y.E. 160 — Ashglyphs are formalized
**Cause:** Trade between the Three Clans requires reliable record-keeping (who owes whom hospitality, whose harvest is whose).
**Consequence:** The soot-and-ash finger-script is standardized by early Keepers into the first written Ashglyphs.
**Historical importance:** Enables the Timeline itself to exist in writing from this point forward; earlier entries are oral-tradition reconstructions.

### Y.E. 240 — Founding of Ledgerhall (later Ledgerhall City)
**Cause:** A trade outpost at the mouth of the Sillow River grows rapidly due to sea access to the Lantern Straits.
**Consequence:** Wealth concentrates there faster than anywhere else in Emberfold.
**Key figures:** **Merchant-Keeper Osrin Vale**, the first person to hold a Keeper's title primarily because of wealth rather than trust — a quiet, deliberate historical turning point.
**Social effects:** First recorded instance of a Keeper role being *bought* rather than earned; sows the earliest seed of the Ledger/Glow tension.

### Y.E. 310 — The Cracking Winter
**Cause:** An unusually long and severe Grey Damp fog season coincides with crop failure across the Sillow valley.
**Consequence:** Without modern stores, hundreds die of cold and hunger over one winter — the single greatest tragedy in Emberfold's recorded history.
**Historical importance:** Origin of The Hush festival (see 1.10). Also the origin of the modern glowdebt custom being taken *seriously* rather than casually — survivors organized the first formal mutual-aid rotations, ancestor of the modern Keeper hearthfire-tending duty.
**Key figures:** **Maren Hollowfield**, a minor historical figure (a baker, not a leader) credited with organizing door-to-door food-sharing during the worst month; she refused any formal Keeper title, insisting "I only knocked on doors." This humility becomes a celebrated ideal — Emberfold reveres reluctant, quiet helpers over proclaimed heroes, again reinforcing the game's "nobody is a chosen one" ethos.
**Social effects:** The Cracking Winter is the emotional bedrock of Emberfold identity — "we survived because we fed each other" is a phrase still used today, including sarcastically by cynics in Ledgerhall City, which is a useful piece of modern-day dialogue texture.

### Y.E. 402 — Steam-lanterns arrive
**Cause:** A traveling engineer from across the Lantern Straits (external contact — first confirmed contact with peoples beyond Emberfold) introduces coal-rail technology.
**Consequence:** Ledgerhall City industrializes rapidly; rural regions do not, and cannot easily afford to.
**Political effects:** First major wealth/technology gap between capital and countryside; regional resentment begins here and is still current in the game's present day.

### Y.E. 455–470 — The Ledger Age formally begins
**Cause:** Ledgerhall's wealth and administrative reach grows to the point it can informally set trade terms for the whole continent.
**Consequence:** Hearthmark currency becomes near-universal even in villages that historically bartered.
**Social effects:** Beginning of the modern "fraying" — the slow decline in glowdebt culture as formal currency makes debts feel settleable and closed rather than open and ongoing (a "you paid me, we're done" mentality replacing "I'll pass it on").

### Y.E. 505 (10 years before game start) — The Keeper Shortage becomes publicly acknowledged
**Cause:** A generation raised more on Ledger logic than Glow logic reaches adulthood; fewer young people are willing to take up unpaid Keeper duties.
**Consequence:** Several villages report their hearthfires going untended for the first time in recorded memory (though none has fully gone out — yet).
**Historical importance:** This is treated, in-world, the way a real society treats a slow demographic or civic crisis — debated, argued about, not agreed upon, no single villain.
**Key figures:** **Elder Fennwick**, an aging Keeper in the region of **Millbrook** (introduced fully in Part 2), publicly warns the regional council that "a fire tended by no one is still a fire — until, one day, it isn't." This line recurs as a piece of in-game folklore/foreshadowing.

### Y.E. 515 — PRESENT DAY — Chapter 1 begins
The player is an ordinary young adult in the town of **Millbrook** (full detail in Part 2), living amid this slow social fraying, about to have an unremarkable day interrupted by one small act that starts everything.

---

# SECTION 3 — REGIONS
*(Full 10–15 region breakdown, with history, architecture, food, culture, NPCs, problems, festivals, secrets, buildings, landscape, and art direction, is delivered in Part 2 — this keeps each region genuinely detailed rather than compressed into short entries here.)*

Regions to be covered in Part 2, confirmed and locked in for continuity:
1. Millbrook (player's home region)
2. Corrowmere (spiritual/historical heart, site of the First Hearth)
3. Ilsecrest (mountain region, Keeper traditions strongest here)
4. Ledgerhall City (the capital, site of "current crisis")
5. The Sillow Riverlands
6. The Lantern Coast (Straitfish fishing communities)
7. The Hollow Orchard Valley
8. The Underhearth (hidden, beneath Ledgerhall)
9. Greywick (Grey Damp fog region, isolated, melancholic but warm)
10. The Glasslake shore
11. Farrow's Reach (poorest farming region, resentful of steam-lantern wealth gap)
12. The Ashglyph Archive district (scholar/record-keeper town)

---

# SECTION 4 — THE PLAYER

## 4.1 Identity

Name: **customizable**, default suggestion **"Wren"** (gender-neutral, easy to voice-act around without gendered pronouns in ambient dialogue if the studio wants full customization).

Age: 19–22 (flexible; old enough to be independent, young enough to still be figuring out who they are).

**The player is explicitly not chosen, not prophesied, not special.** No NPC will ever say "you're the only one who can do this." Where the story needs the player to act, it will always be because they happened to be there, not because they were destined to be.

## 4.2 Personality (default, before player choices reshape it)

Curious but conflict-avoidant. Quietly observant. Has a habit of noticing small things about people (a nervous tic, a favorite mug, a name they wince at) — this is coded into how the player character is written to speak, and gives natural hooks for "Observe" heart-encounter actions. Not naturally confident; growth into confidence is a possible arc, not a given one.

## 4.3 Background

Grew up in Millbrook. Parent(s) run(s) the town's small **repair shop** (mends everything from kettles to cart wheels) — establishing early, diegetically, that "fixing things" runs in the player's blood without making them a chosen-one mechanic. The player has been helping in the shop since childhood, which is the source of the "Repair" heart-encounter verb being a player strength by default.

## 4.4 Family

- **Parent, Isla/Isham Thorne** (gender mirrors player's if desired, or fixed — recommend fixed as **Isla Thorne** for VO simplicity): runs the repair shop, warm but overworked, quietly worried about the shop's future as Ledger-economy competitors undercut small repair work with cheap imported goods (a lived, human version of the "current crisis").
- **Grandparent, "Gran Mossy" Thorne:** lives with the family, was a reluctant Keeper decades ago and quit after the Keeper Shortage debates got ugly (see Timeline Y.E. 505) — a wound that will matter later, since the story will eventually ask the player to consider taking up Keeper-adjacent responsibility themselves.
- No sibling by default (keeps focus tight); an optional younger cousin, **Bren**, can be toggled in for players who want a mentee-figure dynamic.

## 4.5 Friends (see Companions, Part 3, for full profiles)
Two childhood friends already established before Chapter 1 begins, to avoid the game feeling like the player has no life before the story starts:
- **Cael**, a river-caller apprentice (companion #1)
- **Nib**, works the Millbrook market stalls, sharp-tongued, secretly anxious (companion #2)

## 4.6 Dreams

Default (player-adjustable via early dialogue): the player doesn't have a grand dream yet, and is a little embarrassed about that in a world that expects young adults to "have a path." This unresolved, ordinary uncertainty is deliberate — it's a much more common, relatable throughline than a chosen destiny, and it resolves differently depending on virtue/companion choices (see Endings, Part 5).

## 4.7 Weaknesses

- Conflict-avoidant to a fault; default dialogue options often include a "duck the question" choice that has real, tracked social cost.
- A tendency to help *too* readily even at personal cost — this is not framed as pure virtue; it can tip into the Compassion-without-Discipline drawback described in the Virtue System.
- Financially unglamorous — the repair shop is barely getting by, and money is a real, recurring pressure, not a video-game abstraction.

## 4.8 Possessions

- **A patched leather tool-roll** inherited from Gran Mossy, containing basic repair tools — the game's core "inventory anchor" item, present in nearly every era of the story.
- **A single hearthmark coin**, kept, never spent — a habit picked up from Isla, who calls it "the coin you don't spend," symbolizing the idea that not everything of value should enter the Ledger economy.

## 4.9 Character Arc

Broad shape (branches heavily by playstyle — full branching detailed in Part 4):
Ordinary, avoidant young person → drawn into small acts of help almost by accident → begins to notice the Glow economy is dying around them → must decide, gradually, whether to become the kind of person who tends things (a Keeper in spirit if not in title) → by the end, has either grown into quiet responsibility, burned out and needs to learn a boundary lesson, or found a third, personal path the game doesn't moralize about.

## 4.10 Possible Future Paths (feeds into Endings, Part 5)

- Becomes Millbrook's youngest Keeper in generations.
- Leaves to carry the "passing the glow" idea to Ledgerhall City itself.
- Chooses an ordinary, quiet life and is shown, movingly, that this is not a lesser ending.
- Burns out from over-helping and the story honors that as a real, valid, recoverable arc rather than a failure state.

---

# SECTION 5 — THE VIRTUE SYSTEM

## 5.1 Design Philosophy

No virtue is simply "good." Every virtue has a believable shadow side when taken to an extreme, and NPCs react to *excess* as realistically as they react to *lack*. Virtues are tracked as a **wheel**, not a bar — meaning the interesting state is not "high everything" but a *shape*, a personality. Two players with the same total virtue "points" but different distributions will get noticeably different scenes, reactions, and endings.

## 5.2 The Seven Virtues

### Compassion
**Represents:** care for others' suffering, willingness to help.
**Rewards:** trust, softened NPC defenses, access to the deepest Heart Encounter resolutions.
**Shadow side:** Compassion without Discipline becomes **self-erasure** — NPCs (especially Isla and Gran Mossy) will start to worry aloud about the player, and some companions will gently (or not so gently) call it out. A high-Compassion/low-Discipline player can trigger a specific mid-game "burnout" arc.

### Wisdom
**Represents:** pattern recognition, learning from mistakes, understanding *why* before acting.
**Rewards:** unlocks dialogue options that see through manipulation or misunderstanding; unlocks Ashglyph translation puzzles faster.
**Shadow side:** Wisdom without Compassion curdles into **detached analysis** — the player becomes the person who always has the correct read on a situation but never warms it with kindness; some NPCs will find this player character cold and pull away.

### Hope
**Represents:** belief that things can get better, willingness to try even without guarantee.
**Rewards:** Emberlight (the game's soft magic) responds most visibly around high-Hope players; unlocks the most optimistic dialogue and ending branches.
**Shadow side:** Hope without Wisdom becomes **naivety** — a high-Hope/low-Wisdom player can be manipulated by well-meaning-but-wrong or outright self-serving NPCs (see Antagonists, Part 3) and won't get warning dialogue that a Wisdom-balanced player would.

### Justice
**Represents:** fairness, standing up against wrongdoing, refusing double standards.
**Rewards:** unlocks confrontation-based resolutions to Heart Encounters (the "Protect" verb leans on Justice); NPCs who've been wronged specifically seek the player out.
**Shadow side:** Justice without Humility hardens into **righteousness** — a high-Justice/low-Humility player becomes someone who is technically correct but insufferable to be around; several NPCs have unique "tired of being lectured" dialogue gated behind this combination.

### Discipline
**Represents:** follow-through, consistency, boundaries, sustainability of care.
**Rewards:** unlocks the "Repair" and "Wait" verbs' deepest options; the repair-shop storyline (family arc) leans heavily on Discipline.
**Shadow side:** Discipline without Compassion calcifies into **rigidity** — an unwillingness to bend rules even when kindness plainly calls for it; the game will present at least one Heart Encounter (Part 4) that a high-Discipline/low-Compassion player will *fail* by being technically correct and emotionally wrong.

### Humility
**Represents:** not needing credit, comfort with being ordinary, listening more than speaking.
**Rewards:** the game's rarest and most treasured NPC reactions are gated behind Humility, echoing Maren Hollowfield ("I only knocked on doors") — the game deliberately rewards *not* seeking recognition.
**Shadow side:** Humility without Justice collapses into **self-erasure of a different kind** — an unwillingness to advocate for yourself or call out real wrongs, mistaken for saintliness but actually a failure to protect yourself or others.

### Creativity
**Represents:** unconventional problem-solving, art, play, seeing new uses for old things.
**Rewards:** unlocks alternate, often gentler solutions to puzzles and Heart Encounters that bypass a "correct" answer entirely; strongly tied to the repair-shop and Hollow Orchard storylines.
**Shadow side:** Creativity without Discipline becomes **avoidance dressed as invention** — using clever workarounds to dodge a hard conversation instead of having it; at least one companion (Part 3) will directly call this out if the player leans on it too often with them specifically.

## 5.3 How Virtues Are Tracked (Design Note for Engineers)

Not a simple sum. Each virtue is stored as an integer 0–10. Certain dialogue/encounter outcomes check **combinations**, not single stats (e.g., `Compassion >= 7 AND Discipline <= 3` triggers the burnout arc flag). Full flag/variable list will be specified in the JSON schema (Part 5), but designers should build every major scene assuming *shape* matters more than *total*.

## 5.4 Virtue Wheel Visual Reference (for concept artists)

Circular wheel, seven wedges, warm palette (embers, not neons) — recommend muted terracotta (Compassion), deep indigo (Wisdom), warm gold (Hope), rust red (Justice), slate blue-grey (Discipline), soft moss green (Humility), dusty violet (Creativity). Wedge fill rises from center; a thin "shadow ring" on the outer edge of any wedge above 7 subtly darkens to visually cue the player (without a popup) that they may be tipping into a shadow-side state.

---

*End of Part 1. Part 2 will cover all Regions in full detail (history, architecture, food, culture, NPCs, problems, festivals, secrets, buildings, landscape, art direction) for Millbrook, Corrowmere, Ilsecrest, Ledgerhall City, and the remaining 8 regions listed in Section 3.*
