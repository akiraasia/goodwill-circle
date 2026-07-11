# Goodwill Circle — Chatbot + Card Fixes

Three tightly coupled changes: (1) fix card UI & credits, (2) add a contextual AI chatbot per help request, (3) add a global navigation chatbot on the feed. All AI is powered by **Firebase AI Logic (Gemini Developer API)** — the Flutter package `firebase_ai`.

---

## Scope Summary

| # | What | Where |
|---|------|--------|
| 1 | Remove "38 joined" pill from community cards | `request_card.dart` |
| 2 | Fix credits display: show `+N credits` always (not "joined") | `request_card.dart` |
| 3 | Fix `helperCount` / `helpieCount` display removed — restore the stat chips | `request_card.dart` |
| 4 | Verify credit transfer flows from helper → helpee on completion | `request_repository.dart` / `complete_connection` RPC |
| 5 | Per-request AI chatbot (contextual, description-grounded) | new `HelpChatScreen` |
| 6 | Global navigation chatbot on feed (FAB or persistent button) | `requests_screen.dart` |

---

## User Review Required

> [!IMPORTANT]
> **Credit Transfer** — The `complete_connection` Supabase RPC is responsible for awarding goodwill credits. We will add diagnostic logging to confirm credits flow from helpee→helper on completion. If the RPC is broken, a Supabase migration may be needed (out of Flutter scope). Please confirm whether the issue is client-side (display only) or server-side (RPC not awarding credits).

> [!IMPORTANT]
> **Firebase Project Setup** — Using `firebase_ai` requires:
> 1. A Firebase project linked to this Flutter app (`google-services.json` / `GoogleService-Info.plist`)
> 2. Running `npx firebase-tools init ailogic` once to provision Gemini Developer API
> Do you already have Firebase set up in this project, or do we need to configure it from scratch?

> [!WARNING]
> **`firebase_ai` adds ~2MB** to app bundle. The `firebase_core` and `firebase_auth` packages must also be added. If the project already uses Supabase Auth only, we'll use anonymous Firebase Auth solely for the AI calls — no user data stored in Firebase.

---

## Open Questions

> [!IMPORTANT]
> 1. **"joined" pill**: The "38 joined" badge appears in `_ImpactPill` when `isCommunityRequest == true`. Should community requests show **nothing** in that pill, or show `+N credits` like non-community requests?
> 2. **Helper/Helpee count chips**: Were they previously visible on the card and then accidentally removed? Should they appear as small stat chips (e.g., "2 helpers · 1 helpee") under the description?
> 3. **Chatbot per request**: Should the chatbot button appear as an icon button on each card, or open automatically when tapping the card title?
> 4. **Global chatbot**: Should the global bot be a persistent floating button (different from the existing "New Request" FAB), or a chat icon in the top-right of the feed header?

---

## Proposed Changes

### 1. Card UI Fixes — `_ImpactPill`

#### [MODIFY] [request_card.dart](file:///c:/Users/admin/Desktop/goodwill%20circle/lib/features/requests/widgets/request_card.dart)

**Problem (line 444–451):** When `isCommunityRequest == true`, the pill shows `'${request.volunteersCount} joined'` — this is the "38 joined" badge to remove.

**Fix:** Always show `+${request.goodwillReward}` credits pill. Remove the `isCommunityRequest` branch from `_ImpactPill`.

```dart
// Before
_ImpactPill(
  label: isUrgent && !isCommunityRequest
      ? 'URGENT'
      : isCommunityRequest
      ? '${request.volunteersCount} joined'   // ← DELETE THIS BRANCH
      : '+${request.goodwillReward}',
  urgent: isUrgent && !isCommunityRequest,
),

// After
_ImpactPill(
  label: isUrgent ? 'URGENT' : '+${request.goodwillReward}',
  urgent: isUrgent,
),
```

---

### 2. Restore Helper/Helpee Count Chips

#### [MODIFY] [request_card.dart](file:///c:/Users/admin/Desktop/goodwill%20circle/lib/features/requests/widgets/request_card.dart)

Add small stat row chips below the description (before the action buttons) showing helper and helpee counts. This was previously available via the `helperCount`/`helpieCount` model fields but not surfaced in the UI.

```dart
// Add after description/tags block, before action buttons:
if (request.helperCount > 0 || request.helpieCount > 0)
  Wrap(
    spacing: 6,
    children: [
      if (request.helperCount > 0)
        _StatChip(icon: Icons.volunteer_activism, label: '${request.helperCount} helper${request.helperCount != 1 ? 's' : ''}'),
      if (request.helpieCount > 0)
        _StatChip(icon: Icons.person_outline, label: '${request.helpieCount} helpee${request.helpieCount != 1 ? 's' : ''}'),
    ],
  ),
```

Add a new `_StatChip` private widget (similar to `_TagPill`).

---

### 3. Credit Transfer Verification + Chat Bot Button on Card

#### [MODIFY] [request_card.dart](file:///c:/Users/admin/Desktop/goodwill%20circle/lib/features/requests/widgets/request_card.dart)

Add an AI chatbot icon button next to the existing support (heart) button. Tapping it opens `HelpChatScreen` with the request's `title`, `description`, and `category` pre-loaded as context.

```dart
// In the stats Wrap row, alongside the heart button:
InkWell(
  onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => HelpChatScreen(request: request),
  )),
  child: const Padding(
    padding: EdgeInsets.all(4),
    child: Icon(Icons.smart_toy_outlined, size: 16),
  ),
),
```

---

### 4. Per-Request AI Chatbot Screen

#### [NEW] [help_chat_screen.dart](file:///c:/Users/admin/Desktop/goodwill%20circle/lib/features/requests/widgets/help_chat_screen.dart)

A full-screen chat UI that:
- Initializes Firebase AI with `FirebaseAI.googleAI()` using `gemini-flash-latest`
- Builds a **system prompt** from the help request: title, description, category, difficulty, tags
- Maintains a multi-turn chat session with `model.startChat(history: [systemHistory])`
- Streams responses using `generateContentStream` for a typing effect
- Shows a loading skeleton while first response generates

**System Prompt Template:**
```
You are a helpful assistant for the Goodwill Circle community platform.
A user has posted a help request with these details:
- Title: {title}
- Category: {category}
- Description: {description}
- Tags: {tags}

Answer questions about how to help, what resources might be relevant, 
or how to navigate the Goodwill Circle platform for this specific need.
Keep responses concise and actionable.
```

---

### 5. Global Navigation Chatbot on Feed

#### [MODIFY] [requests_screen.dart](file:///c:/Users/admin/Desktop/goodwill%20circle/lib/features/requests/requests_screen.dart)

Add a **chat FAB** that opens `AppChatScreen` — a general Goodwill Circle navigation assistant. It will be positioned above the existing "New Request" FAB using a `Column` of FABs.

#### [NEW] [app_chat_screen.dart](file:///c:/Users/admin/Desktop/goodwill%20circle/lib/shared/widgets/app_chat_screen.dart)

General app navigation chatbot that knows about Goodwill Circle's features:
- How to post a help request
- How to join a request as helper/helpee
- What goodwill credits are and how they're earned
- How the Connection Hub works
- What community starter requests are
- NGO agenda items and certificates

**System Prompt:**
```
You are Goodwill, an AI assistant for the Goodwill Circle community app.
Goodwill Circle is a platform where people ask for and offer help (goodwill loops).
You help users:
- Navigate the app features (requests feed, agenda, profile, trust/verification)
- Understand how goodwill credits work (earned by helping, spent on urgent requests)
- Join help requests as helper or helpee
- Understand community starter requests and NGO agenda items
- Use the Connection Hub to coordinate with helpers/helpees
Keep answers friendly, short, and actionable.
```

---

### 6. Firebase AI Setup

#### [MODIFY] [pubspec.yaml](file:///c:/Users/admin/Desktop/goodwill%20circle/pubspec.yaml)

```yaml
dependencies:
  firebase_core: ^4.0.0
  firebase_auth: ^6.0.0
  firebase_ai: ^3.0.0
```

#### [MODIFY] [main.dart](file:///c:/Users/admin/Desktop/goodwill%20circle/lib/main.dart)

Add `Firebase.initializeApp()` call before `runApp`. Use anonymous Firebase Auth for AI calls only (Supabase handles app auth).

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` after changes.
- Run `flutter build apk --debug` to confirm no compile errors.

### Manual Verification
1. Open the feed — community request cards should **not** show "38 joined", should show "+N credits" pill.
2. Helper and helpee count chips appear when counts > 0.
3. Tapping the bot icon on a request card opens the contextual chat.
4. The chat responds with advice relevant to the request description.
5. Tapping the global chat FAB opens the app navigation chatbot.
6. Complete a help request → check if goodwill credits appear in profile (server-side confirmation).
