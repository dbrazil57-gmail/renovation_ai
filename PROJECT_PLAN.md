# Renovision AI — Product and development roadmap
**Working name; Android first; Flutter project; 12 November 2026.**

## Product vision
A privacy-conscious home renovation visualisation app: photograph a real room, explore ideas, save/reject alternatives, crop/zoom, mask a specific region, annotate with rough drawings or Paint sketches, refine an approved version without unexpectedly changing unrelated features, and maintain a local, portable project library.

One app; consumer, tradie and enterprise feature tiers later. iOS from shared Flutter source when ready. No public release during Stage 1.

## Non-negotiable design principles
- The original uploaded photo is **immutable**; keep an unmodified source copy and derivatives.
- A user-approved image is the **locked baseline** for each subsequent edit. Never silently switch to an earlier image or regenerate the whole room when an area is selected.
- Support **Explore** (creative full-room changes) separately from **Precision Edit** (selected-area-only corrections).
- Every edit tracks input image hash/id, prompt, mask/sketch, model/provider, result, approval/rejection, and parent version.
- Preserve project choices as structured **room memory**, including locks for windows, doors, architectural openings and floor edges.
- Prefer masked image editing and compositing when supported. Crop with adequate surrounding context, then blend result back into the unmodified image. Full-room generative regeneration is *not* reliable for exact changes.
- Compare output with baseline; highlight changes outside an editable area. This is a warning, not a structural guarantee.
- Keep projects and photo files on-device; add export/import and backups. No mandatory account for basic use.
- No API keys, photos, addresses, or payment credentials in source control. No AI processing during the UI-only prototype.

## Stage 0 — Developer setup
- Windows PC: VS Code already installed. Install Git, Flutter via the official VS Code extension, GitHub account/private repo, then Android Studio/SDK/AVD.
- Verify `git --version`, `flutter doctor`, `flutter devices`, `flutter run -d chrome`, `flutter test`.
- Avoid native Windows desktop build until needed (requires full Visual Studio desktop C++ tools, separate from VS Code).
- Optional IDE AI assistant: official OpenAI Codex or GitHub Copilot; use it for **coding**, not as the app's production AI service.

## Stage 1 — UI proof of concept (no AI/server/payments)
- Responsive app shell and navigation: Explore, Projects, Library, Settings.
- Project creation, room list, sample assets, local draft data model.
- Design preference browsing: skip/save; store saved idea and feedback.
- Later in Stage 1: import photo, rotate/zoom/crop, selected-area masks, simple sketch overlay; before/after compare; branch/restore versions; export/import project.
- Acceptance: works on Chrome and Android emulator; sample design interaction works; no cloud requests; no real photo leaves device.

## Stage 2 — Persistent local library and editing
- Durable project store (e.g. SQLite-based abstraction with platform implementation); photo files stored in app-private directories, with explicit project export/import.
- Separate original, approved baseline, current candidate and rejected branches.
- Edit records: project_id, room_id, source_id, parent_version_id, selection region/mask, prompt, locks, provider, timestamp, output id, approval state.
- Validate shutdown/restart, deletion, low storage, permission changes and failed imports.
- If browser prototype uses temporary storage, warn users; Android persistence is the source of truth until robust web persistence is implemented.

## Stage 3 — AI provider experiment
- Start with manual share-to-ChatGPT/Gemini/import workflow; inspect whether full photo + precise prompt is preserved through sharing.
- Optional developer-only controlled API experiment with ONE image-edit model: compare full-image edit vs crop + mask + compositing.
- Build a provider interface: `generateDesign`, `editSelectedArea`, `capabilities`, `usageEstimate`, `cancel`.
- Customer API key is NOT the same as their ChatGPT subscription. Do not embed reusable secrets in a distributed app. Confirm provider terms and a secure relay or delegated auth before enabling bring-your-own-key in public builds.
- Prepaid generation bundles and in-app billing deferred until outcomes and costs are measured.

## Stage 4 — Claylands benchmark and quality gates
- Test with original before photos (office/dining, kitchen, exterior), with user's permission and local-only test assets.
- Cases: remove fireplace; retain broad rear windows; only fix hallway passage/wall trim; change one cabinet; only fix skirting edge; preserve camera perspective; keep previously approved lighting/furniture; integrate sketch drawn in Paint.
- For every case: record expected edit region, non-edit lock mask, baseline output, result, provider, actual charge, user rating and corrections needed.
- QA metrics: outside-region pixel/perceptual change, room geometry consistency, prompt adherence, revision rework count, generation cost, crash rate.
- A pretty output that changes unrelated walls or windows **fails** precision mode.

## Stage 5 — Android distribution to private testers
- Chrome for rapid UI iteration; Android Studio emulator for Android behavior; USB or wireless connected physical Android phone for camera/pinch/gesture/permissions.
- Use `flutter run` for debug installs, then `flutter build apk` for private APK testing. No Google Play account required to run personal-device debug builds.
- Test APK signing, package identifiers, reproducible build, permissions, data export and safe failure when AI unavailable.
- Review side-loading warnings and only share private builds with trusted testers.

## Stage 6 — Public launch
- Before public launch: security/privacy review, provider data-processing review, AI content reporting/policy review, accessibility, crash reporting with privacy controls, terms and privacy policy.
- Google Play Console developer registration, listing, screenshots, release signing, developer verification and applicable closed-testing gate.
- Build Android App Bundle (`flutter build appbundle`), submit via Play Console. Prepare one app with feature tiers and Google Play Billing for digital content.
- Pricing to test: one-room free trial, optional paid local project/pro features, prepaid generations (capped), watermark only when our paid AI service provides an unlockable preview.
- Track net unit economics: gross revenue - store fees - AI inputs/outputs/retries - infrastructure - refunds/support.

## Stage 7 — Later expansion
- Level 2 camera-aligned comparison (not live generative AR), device capability detection and fallbacks.
- Tradie features: separate clients, branded exports, job folders, controlled sharing, team review.
- Enterprise: central accounts and storage, tenancy isolation, access roles, governance/compliance, billing and audit logs.
- iOS: reuse most Flutter/UI/business logic; Mac + Xcode for iOS builds, testing and release; platform-specific camera, storage and in-app purchases adaptation.

## Initial architecture sketch
```
Flutter UI
  -> Project controller / room design state
     -> Local project repository + photo storage
     -> Edit workflow (prompt builder, crop, mask, sketch, approval)
     -> AI Provider Adapter
        -> Manual handoff/import (Stage 1-3)
        -> Secure API service / approved delegated auth (future)
     -> Export/import service
```

## Privacy/security checklist
- Make original images immutable; encryption at rest where appropriate; avoid saving photo EXIF/geolocation.
- Default local-only storage. For cloud edits, obtain informed consent before transmission and identify the provider.
- Use private code repo, `.gitignore` for sensitive files, strong GitHub MFA; do not commit tokens, test photos or release signing keys.
- Platform backups may back up app data; review Android backup rules and communicate data handling truthfully.
- Public API service must authenticate/limit generation usage and prevent abuse; do not trust client counters.
- Export and delete functions, readable data-retention disclosure, provider retention review and breach response planning before launch.

## First demo acceptance checklist
- [ ] Flutter SDK installed and `flutter doctor` runs
- [ ] Private GitHub repo created
- [ ] `flutter run -d chrome` opens Renovision demo
- [ ] Explore > Save idea > Library shows saved concept
- [ ] Projects > Create project adds a project
- [ ] `flutter test` passes
- [ ] `flutter analyze` is clean
- [ ] Android emulator starts app
- [ ] First real photo import milestone planned (not part of starter)

## Official references
- Flutter install via VS Code: https://docs.flutter.dev/install/with-vs-code
- Flutter Android setup: https://docs.flutter.dev/platform-integration/android/setup
- Git for Windows: https://git-scm.com/install/win
- GitHub private repo setup: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
- Flutter Android deploy: https://docs.flutter.dev/deployment/android
