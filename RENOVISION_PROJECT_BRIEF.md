# Renovision AI — project brief for Codex

## Project purpose
Android-first, Flutter-based AI renovation visualisation and project-management application. Develop on Windows, test primarily with Flutter web in Chrome and Android emulator, then a real Android device. Retain a shared Flutter codebase for eventual iOS deployment. This is a free Stage 1 proof of concept, not yet a Play Store release.

## Current working situation
- Existing Flutter project: `C:\Dev\renovision_ai` (Windows).
- Flutter launches in Chrome with `flutter run -d chrome`.
- A previous Stage 1 upgrade was added and partly worked; inspect the **actual current repository** before editing. Do not assume files or code match the original zip.
- User prefers substantial but validated development batches, computer testing first, Android second.
- User has VS Code; Codex may be available through the official VS Code extension signed into ChatGPT.

## Product structure and business intent
- One app with progressive feature tiers, not separate apps: homeowner/amateur first, tradie/small business later, larger teams/enterprise eventually.
- Free Stage 1 prototype; explore a free one-room trial, potential ~AUD 5 homeowner purchase, credit packs/subscriptions for later tiers. Never offer uncapped paid AI usage.
- Core product differentiation: precise controlled changes in *real* rooms, preserving protected details, alongside swiping to save/reject, refinement and project history. Emphasise high quality and reliable results over flashy but inaccurate renders.
- No payment integration, hosting purchase, or Play Store setup required yet.

## Major app modes
1. **Explore Ideas**: Import/take room photo, specify room type or style, generate/import multiple concepts, swipe left/right to reject/keep and save favourites.
2. **Precision Edit**: Select an approved image, zoom/pan/crop to focus on a small area, brush/select a mask, sketch/annotate or import rough Paint drawings, type a narrow edit instruction, preserve unaffected parts.
3. **Project Library**: Homes, rooms, immutable original images, approved baselines, version history, branched design options, prompts, protected features, likes/dislikes, before/after comparison and export eventually.
4. **Camera**: Level 1 photo capture/redesign first. Level 2 camera-aligned overlay to compare a previously generated view later. Do NOT promise or build full live AR/video transformation at Stage 1.

## Critical lessons from user's Claylands renovation
Claylands is the user's real test renovation project. They will use the original before photographs to test the app. Prior ChatGPT redesigns repeatedly modified unrelated architecture when the user requested one small change. Examples:
- Office: retain large wide existing windows, layout and camera viewpoint. Remove fireplace/hearth and potentially convert to cupboard/coat storage; use warm charcoal and walnut joinery and glass folding doors. Subsequent requests frequently changed only the passage/doorway, wall edge, skirting or one minor component.
- Kitchen: preserve agreed cabinetry/island design and replace only specifically requested elements; a brochure image replacement was missed in earlier revisions.
- Floor plans: unwanted movement of unrelated bedrooms and rooms when a small change was requested.
- Exterior and games room: localised modifications such as deck/fence details, pool-table rotation, seating or TV-wall adjustments while retaining everything else.
- User uploaded crude MS Paint plans/sketches and asked to have AI interpret, review or apply those directly; support sketches and overlaid markings.

## Non-negotiable data and editing principles
- Never overwrite the original photo; keep an immutable original and save edited/generated images as new versions.
- Distinguish exploratory full-room creativity from precise local correction.
- Provide selectable region/mask, crop/zoom and a clear `change only selected area` workflow. For precise editing, prefer region-specific edits or compositor-based replacement where feasible over full-scene regeneration.
- Track approved/locked baseline images and prompt/annotation history; allow branching and restoring an earlier concept.
- Lock elements (windows, doors, etc.) as a user intention, but do not promise the AI will preserve them perfectly. Detect and visually flag unintended changes outside selection when technically feasible.
- Treat generated imagery as **visual concepts**, never as verified buildable designs, measurements or engineering plans.
- User should be able to compare before/after, like/dislike, annotate, crop, and save refinements locally.

## Privacy and AI
- Local-first: store project metadata, photographs, generated results, prompts, sketches and edits on user's device, by default. Minimise or avoid compulsory accounts and unnecessary personal data.
- The first working AI handoff can be manual: prepare prompt + image, open customer's ChatGPT/Gemini app or other supported workflow, and import resulting image back; clearly explain limitations of automation and handoff.
- Customer-supplied developer API key is a possible later option. A standard ChatGPT subscription does NOT automatically grant ordinary OpenAI API usage; do not embed API keys in distributed mobile source. Use secure arrangements and provider terms review.
- Later option: prepaid AI generations with a secure backend and usage limits, controlled by the app. Don't incur cloud costs during local prototype testing unless explicitly approved.
- Photos sent to cloud image models leave the device; disclose and obtain consent, strip unnecessary location metadata when applicable.

## Development guidelines
- **Read the existing Flutter project first**, especially `lib/`, `pubspec.yaml`, `test/` and any `CODEX_NEXT_STEPS.md` or `README.md`. Preserve working code and local user data. Do not overwrite the project with a generic template.
- Work in coherent feature batches, run `flutter analyze` and `flutter test`, and test `flutter run -d chrome` where possible. Explain required manual browser and Android tests.
- Keep code modular for future iOS and provider integrations.
- Beware that Flutter web and Android differ in local file APIs and persistence. Use platform-compatible storage and describe limits honestly. Do not treat browser storage as guaranteed permanent; eventually add export/import.
- Avoid destructive cleanup or deleting project/local image data without explicit approval. Use Git commits after verified milestones.
- Do not claim image masks prevent changes until tested empirically.

## First useful development milestone
From the current working code, finish reliable project/room creation, photo import, immutable original storage, pinch/scroll zoom, non-destructive crop and sketch/selection overlay, locally saved version records, before/after comparison and favourites. Then test a realistic Claylands office-photo editing flow, starting with manual AI handoff and reimport. Fix actual usability problems identified by the user before adding payment or automatic AI.
