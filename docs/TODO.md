# rePlay — Outstanding Work

Handoff notes for the next session. Updated 2026-06-10.

Repo state: on `main`, in sync with `origin/main` at `988520e`. 39/39 tests pass, `flutter analyze` clean.

## Pending verification (carries over from the hero transitions work)

- [ ] **Manual animation check on macOS.** Run `flutter run -d macos`, then:
  - Tap a grid card with a real photo → cover image should fly into the detail header while the rest of the page cross-fades in.
  - Press back → reverse animation.
  - Toggle list view, tap a list item → same transition from the small 48×48 thumbnail.
  - Open Stats tab, tap a "Recently added" card → should fade-route into detail (no hero on the card itself yet — see below).
  - Tap a toy with no photo → should plain-fade-navigate, no hero.

  If `BorderRadius` jumps instead of interpolating, the `flightShuttleBuilder` in `toy_detail_screen.dart:_buildMainImage` is the place to look.

## Loose ends

- [ ] **Stray `package-lock.json` at repo root.** Untracked for several sessions. Flutter projects don't use it — likely left over from a tool that ran in this directory. Decide: delete, gitignore, or commit. Recommended: delete.

- [ ] **Stats screen "Recently added" cards don't hero-wrap their image.** They go through `toyDetailRoute` so they get the fade transition, but no shared-element animation. Hero-wrap them in `lib/features/stats/widgets/recently_added_card.dart` (or wherever the recently-added widget lives) using `toyImageHeroTag(toy.id)` — same pattern as `toy_card.dart`. Small follow-up to the hero transitions work.

- [ ] **Add a no-hero regression test.** The widget tests in `test/widget_test.dart` only cover the hero-present path. Add a test that mounts a toy with `imagePath: ''` and asserts `find.byType(Hero)` finds zero matching `toyImageHeroTag(id)` — protects the placeholder branch from a future regression.

- [ ] **Add a brief comment in `_navigateToDetail`** (both `inventory_screen.dart` and `stats_screen.dart`) explaining why the refresh is unconditional after the await — otherwise a future maintainer might "optimize" it back to conditional and silently break the delete-refresh path.

## Pre-existing concerns (not from the hero transitions work, surfaced during review)

- [ ] **`_navigateToCapture` in `inventory_screen.dart` (around line 349)** has the same missing-`mounted`-guard pattern that we fixed for `_navigateToDetail`. Same crash path on widget disposal during async navigation. Apply the same `if (!mounted) return;` guard.

- [ ] **Sync `File.existsSync()` on the UI thread** in `toy_card.dart:_buildImage`, `toy_list_item.dart:_buildLeading`, and `toy_detail_screen.dart:_buildMainImage`. Acceptable for a personal inventory at current scale but will start dropping frames once a single screen renders >40 toys with cold-NAND I/O. If the inventory ever grows past a few hundred items, cache `imageExists` in the provider layer so build methods never stat.

- [ ] **`flutter pub outdated` reports 56 packages with newer versions incompatible with current constraints.** Worth a dependency audit pass — `mobile_scanner`, `mobile_scanner` plugins, ML Kit, Riverpod, Drift have all moved. Run `flutter pub outdated --mode=null-safety` to see what's safe to bump, then update `pubspec.yaml` constraints + regenerate the Drift schema if needed.

## Backlog — next round of polish (motion & feel axis)

The 2026-05-29 brainstorm picked "hero transitions" as the first motion improvement. Other moments from that conversation that didn't ship:

- [ ] **List/grid entry animations** — toys fade-and-slide in as the inventory loads or filters change. Makes filter chip taps and sort changes feel alive.
- [ ] **Haptics + button feedback** — tactile feedback on save, delete, multi-select toggle. Subtle but adds intentionality to every tap.
- [ ] **Loading shimmers** — skeleton placeholders while the inventory provider loads.
- [ ] **Status badge cross-fade** — animate the status badge color/icon when a toy's status changes from active → to-donate → donated.
- [ ] **Hero between detail-screen photos** — swipe between the cover and additional photos with a shared-element animation. Currently the photo strip just swaps the main image.

## Other polish axes from the original brainstorm (not picked)

- **Theming & dark mode** — proper dark mode, system theme following, refined palette, typography pass, custom app icon
- **Empty & error states** — better empty states across screens, error recovery, retry flows
- **Detail screen polish** — improve info hierarchy, edit flow, photo viewing, history readability

## Where to find things

- Brainstorming output → `docs/superpowers/specs/2026-05-27-hero-transitions-design.md`
- Implementation plan → `docs/superpowers/plans/2026-05-27-hero-transitions.md`
- Older improvement plans (all shipped) → `docs/superpowers/plans/2026-03-*.md` and `2026-04-*.md`
- Original improvement suggestions → `docs/plans/2026-03-26-improvement-suggestions.md` (all 17 done)
