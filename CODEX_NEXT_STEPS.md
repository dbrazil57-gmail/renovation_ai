# Renovision next steps

Current task list after the full code/conversation/design audit, updated through
22 November 2026 (Australia/Sydney). This supersedes older chronological lists.
Requirements remain in [the project brief](RENOVISION_PROJECT_BRIEF.md);
[current capabilities and limits](FEATURE_STATUS.md) are recorded separately.

## Brief completeness and Generate guidance — 22 November

- [x] Pin a live Brief % above Generate on Room / Style / Refine / Ideas, with a
  tap-to-review checklist. Keep this distinct from account/profile completion,
  camera scanning, measured photo quality or AI image-quality confidence.
- [x] Score normal designs from photo, room type, goal/scope, style, palette and
  included layout rule. A generic full-room concept is valid but has less direction;
  style plus palette can complete it without mandatory prose. Do not award points
  for extra photos, paid analysis, a provider connection or more output images.
- [x] Use a short photo/instruction/retain-rest checklist for precise correction.
  Keep actual required-input and paid-request guards; optional direction is advisory.
- [x] Fold suggestions into existing send confirmation. Refine brief returns to
  relevant controls and scrolls the workspace to them; Setup/Live route to their
  relevant step/panel. Cancel/refine sends no AI request or review acknowledgement.
- [x] Remember proceeding at >=75% per room and edit mode on this device. Suppress
  the coverage reminder, not paid consent. Show it again below 75%; always keep
  the footer checklist accessible. Reminder preference is not a project edit/export.
- [x] Treat a failed reminder-preference write as best-effort: no duplicate AI
  request, no discarded result, and the reminder remains eligible next time.
- [x] Source `65936b5efb`: **342 tests pass**, clean analysis (11.1s), Chrome
  release build (61.9s). Tests include live score edits, low-coverage proceed,
  refine/cancel without requests, 75% acknowledgement/reload/mode isolation,
  falling below threshold, blank-precision guard and preference-write failure.
- [x] Actual 390×844 Chrome check: the indicator stays visible in all four tabs,
  its checklist/refine action opens the right inputs, and typing a goal updates
  65% to 75%. Public sample, simulated picker and isolated profile only; screenshots
  and `output/brief-review-browser.log` remain ignored. Same localhost:7357 origin.
- [ ] Accept on S21 after the next requested APK; preserve published 1.0.16.

## Lighting requests and international wording — 22 November

- [x] Make selected/full-room lighting updates explicitly replace visible main
  fittings, not just add accent strips. Keep ceiling structure, protected fittings,
  existing positions and task/accent-only corrections; do not invent unseen lights.
- [x] Ask analysis to identify visible main fittings/locations separately from
  task/accent lighting. Clarify regional English aliases in analysis/generation,
  including basin bowl versus vanity cabinet/counter scope, without blind substitution.
- [x] Source `50196e8c85` passes **335 tests**, clean analysis (12.7s), and Chrome
  release compilation (56.0s). Same localhost:7357 preview; no new APK or paid AI.
- [ ] User-test real generation: old main fitting visibly replaced, protected fitting
  retained, under-vanity-only correction stays narrow. No paid test has been run.
- [ ] Proposed Language & Region setting: Australian/NZ English, UK English and
  US English first, with device suggestion/manual override and AU fallback. Use
  stable room/item IDs, regional UI labels and a captured wording profile in future
  generation recipes; preserve existing instructions and history. This setting is
  not implemented by the current shared terminology guidance.
- [ ] Additional interface languages need localized app text, platform delegates,
  dates/plurals/layout testing and reviewed translations. Do not describe an AI
  glossary or English-style choices as a translated app. Native locale/phone
  acceptance and a requested APK remain separate steps.

## Main navigation follow-up — 22 November

- [x] Put Projects first and select it initially, followed by Explore and Library.
- [x] Remove the redundant Settings bottom tab; the top-right cog opens Settings.
  Back returns to the previously selected tab. Update help ordering and Explore's
  project shortcut without changing saved projects or AI settings.
- [x] Adapt existing navigation/settings/feedback and responsive checks. Source
  `75ffe41898`; evidence is in `output/navigation-review-*.log`. No new APK or AI call.
- [x] Pass **332 tests**, clean analysis (11.2s), Chrome release build (56.5s)
  and an actual 390×844 browser check of tab order, initial Projects and cog/Back
  from all three tabs in an isolated profile. Same desktop address: localhost:7357.

## Workspace testing feedback — 22 November, source after APK 1.0.16

- [x] Confirm room analysis sends the working image plus included context photos;
  the confirmation lists the exact inputs. Uploaded rooms support six photos.
- [x] Compact palette tiles/swatches and use two columns in the full chooser.
- [x] Show ten curated common styles first, then pages of at most ten; keep
  cross-page selections and a visible selected-style summary, including regional styles.
- [x] Keep Autosave in More tools and replace its permanent footer with Generate
  on every tab. Retain pending/save-failure status, one mounted generation session,
  explicit paid confirmation, cancellation, result-save retry and exit guards.
- [x] Add saved Full room (all) / Partial scope, independent of precise correction.
  Full room includes normal surfaces/fittings updates, with disabled included-item
  controls and protected/Keep exceptions; Partial exposes individual choices.
  Preserve partial choices when switching modes and through backup/recipe reuse.
- [x] Keep existing layout/walls on by default; full-room renovation does not imply
  moving architecture. Fix item-choice writes for related room types such as Ensuite.
- [x] Collapse observations/AI prompt details initially; move manual copy/import
  under Refine. Ideas reviews/compares/selects results; a completed batch opens it.
- [x] Pass **332 tests** for source `c2d523f4c0`, including scope/backup/recipe and
  pinned-generation confirmation/cancel checks at phone width. No paid AI requests,
  customer-project edits or APK rebuild in this source follow-up.
- [x] Clean analysis (9.9s), Chrome release compilation (57.6s), and actual
  390×844 browser checks: public sample import, all four tabs, pinned Generate,
  style pagination and Partial selection. Picker is simulated; normal profile is
  untouched. Preview remains http://localhost:7357; screenshots/logs stay ignored.
- [ ] Package for S21 only when requested; keep published APK 1.0.16 unchanged.
- [ ] Refresh the affected video clips after this workspace layout is accepted;
  existing recordings still show the prior control locations. Underlying flows remain.

## Requested test APK — 21 November, 1.0.16+17

- [x] Package all completed features from shared source `aba3ee136c`, including
  room deletion/recovery, typed Live names, tap-wall recolouring/layer deletion,
  save-then-review AI finishing and seven recorded help transactions.
- [x] Pass **327 tests**, clean analysis and Android release compilation (20.4s
  after the video correction). Verify identity/signature against 1.0.15, icon A,
  public asset hashes, private-file exclusion, optional camera and restricted sharing.
- [x] Verify 64-bit ELF LOAD and APK ZIP **16KB alignment**. Runtime acceptance on
  an actual 16KB Android device/emulator remains a launch gate.
- [x] Install/launch the final APK on an isolated read-only API 37 emulator
  (4KB pages), retaining its existing project data. Native help confirms 27s
  duration, advancing frames, pause, actual seek to 25s, fullscreen and written
  fallback. Chrome release rebuild (66.3s) and actual help/seek checks pass at the
  existing localhost:7357 origin using a disposable test profile.
- [x] Replace browser-generated video timestamps after native playback exposed
  incorrect duration/frozen frames. Re-encode all seven clips as silent, zero-based
  constant-rate H.264 baseline MP4s; full-decode/timing checks pass. FFmpeg is a
  development tool only, absent from the app and source control.
- [x] Preserve published APKs 1.0.10–1.0.15 and their checksums, app identity,
  customer stores/keys, original photos and the brief. No paid AI calls or publication.
- [ ] Complete S21 acceptance: install over the current app, check existing work/
  keys, room delete/recovery, wall recolour/delete/reopen, help playback and Live.
  Test real OpenAI/Gemini output and failures separately with owner-approved spend.

Package: `output/mobile-test/renovision-test-1.0.16.apk`, alias `renovision-test.apk`.
83,668,388 bytes; SHA256
`F70B4277E1259501EB76D09EB2316E9364B9913E83FC6576A87411840F1245FF`.
This is a private-test update, not a Play production release. Further APKs need
a user request. All launch gates below remain applicable.

## Public launch review — 21 November 2026

**Decision: enough working product for a controlled beta; not ready for public
Google Play production.** The existing 327 passing tests/clean analysis are evidence
for source behaviour, not store compliance or current phone acceptance. Shared source
is `aba3ee136c`; the requested 1.0.16 package includes the latest paint/help/room
changes. Current physical-phone acceptance remains. The user confirms they have
**no Play Console account yet**.
Keep Standard with users' own OpenAI/Gemini keys as the proposed first-release scope.
The original brief remains unchanged; this is the later launch-readiness assessment.

Owner clarification after this review: **finish the app to release-candidate
standard before paying/registering for Play Console**. Do not create an account,
make a payment or invite testers now. Google-managed checkout is preferred; the
paid-download versus in-app unlock choice remains undecided. Keep the owner's
personal feedback email private using a receiving service and separate public
support mailbox/alias, rather than an email/decryption key embedded in the app.

### Launch gates, in implementation order

- [ ] **Owner setup/decisions:** when the release candidate is ready, register/verify
  Play Console; first choose individual or
  genuine organisation publishing, developer identity/support email/privacy host,
  permanent production package ID, initial countries and free/paid/unlock approach.
  A new personal account needs 12 continuously opted-in closed testers for 14 days,
  followed by a production-access application. The later test is an invited
  opt-in test, not the first downloads or a request for public star ratings.
- [ ] **AI reporting and safety:** add Report this design inside the app with real
  in-app submission, delivery status and owner review. Current saved feedback drafts
  and external email/form handoff are insufficient for the AI-content reporting rule.
  Choose a minimal reporting endpoint/service and retention policy; never send API
  keys or automatically attach private room photos. Verify provider safety/refusal paths.
- [ ] **Privacy/deletion:** publish an app-specific privacy page and link it in the
  app/listing. Map photos, prompts, provider traffic, keys, reports, sharing and SDKs
  into Data safety. Choose/disclose Android OS backup behaviour: current XML excludes
  only the two provider secret stores, not project/photo data. Add or clearly document
  permanent local deletion and trash retention; recoverable room/design deletion is
  not a purge. Review the merged legacy READ_EXTERNAL_STORAGE permission. Do not
  add broad media permissions when system pickers suffice.
- [ ] **Production identity/signing:** replace the example identity and debug release
  signing only after a migration plan. Use a private upload key/Play App Signing and
  a signed Android App Bundle, with a new version code. Target SDK 36 is already
  configured; verify the final bundle's native 16KB support, permissions and devices.
  Existing test app stays installed until portable projects are restored/checked in
  the production app. Changed identity/signature does not automatically migrate its
  private Hive data or Keystore keys; provider keys are entered again separately.
- [ ] **Phone release acceptance:** package the latest source when requested and test
  on S21 plus Android 16/16KB emulator/device: install/update/import, restart, camera,
  gallery, Live, 1/2/3 concepts, refinement, paint/recolour/delete, compare, videos,
  Gallery/share, plain/protected backup and failures. Measure larger projects, memory
  and the current 64MiB-photo/100MiB-file backup limits. Verify offline/rate-limit/
  timeout/low-storage/background behaviour without duplicate paid retries. Current
  Android file destinations are reselected, not durable Word-style overwrite links.
- [ ] **Consumer/reviewer access:** make BYO developer-key setup and separate provider
  costs clear before purchase/use; validate real OpenAI/Gemini image quality/cost.
  Supply private, valid review instructions/access so Google can test AI without
  creating/funding its own provider account. Do not embed a shared company key.
- [ ] **Commercial/store preparation:** choose paid download versus free download
  with later in-app unlock before launch; configure payments/entitlements if applicable.
  A published free app cannot simply become a paid download. Prepare descriptions,
  approved A store icon, feature graphic, real phone screenshots, content rating,
  audience/ads/access declarations and licenses. Finish real task-based help clips;
  the longer store preview video is optional. Remove prototype-facing release copy.
- [ ] **Play rollout:** upload first to internal testing, fix pre-launch findings,
  run the applicable closed test with genuine feedback, apply for production access,
  then submit for production review. Monitor Android vitals and support after release.

**Safe v1 scope:** room-photo/camera capture, AI concepts and prompt-guided refinement,
local wall recolouring, comparison, history and portable projects. Explain that AI
corrections have no enforced hard mask and Live is a generated still overlay at a
matching viewpoint. Do not market instant moving-camera VR or guaranteed pixel locks.
User RenoVision accounts, managed Pro credits, cloud sync, wallpaper, extra providers,
semantic wall segmentation and native Windows packaging can follow. Durable linked
files are desirable, but a clearly labelled, tested manual export/Open workflow can
serve v1. Full local-photo encryption is an assessment, not a blanket release rule.

Official requirements and links are in
[the current Play research](docs/PRODUCT_NOTES.md#google-play-launch-requirements--checked-21-november-2026);
[release acceptance](docs/TESTING_GUIDE.md#public-release-acceptance--21-november-review)
tracks manual evidence. No account, signing identity, key, backend, build or upload
was created/changed by this review. No paid AI calls or customer-data edits occurred.

## Apple readiness — inspected 21 November

- [x] Confirm shared Flutter/iOS project, camera/photo purpose strings, iOS-capable
  camera/gallery/video plugins and shared room/design code exist. No iOS build or
  physical iPhone acceptance has been performed.
- [ ] Implement iOS project Save/Open/backup restore: file_transfer_native.dart
  currently supports only Android.
- [ ] Implement iOS image save/share: creation_export_native.dart selects an
  unsupported implementation outside Android.
- [ ] Add persistent provider-key storage with iOS Keychain; current iOS path uses
  SessionSecretStore, losing the key on restart. Native feedback handoff also remains
  Android-only; future in-app HTTPS reporting should have a shared implementation.
- [ ] Finalize iOS display name (currently Renovision Ai), bundle ID/signing and
  permissions; build/test on macOS/Xcode and iPhone, then consider TestFlight/App Store.
  This is a port/verification batch using the shared app, not a second rewrite.

## Room management, paint and recorded help — source after 1.0.15

- [x] Replace default text-first help with recorded real-widget transactions:
  seven captioned MP4s, playback/seek/full-screen controls and written fallback.
  Use fictional samples/disposable stores; label simulated AI/camera/file pickers.
- [x] Add visible room deletion with exact-name confirmation, Undo and persistent
  Deleted rooms recovery. Retain photos/designs/settings/approvals and include
  deleted rooms in portable copies. Block deletion during active AI requests.
- [x] Save Live room type immediately even with autosave off; normalize old stored
  type labels and generic Unspecified/Live names without overwriting custom names.
- [x] Make tap-wall then colour the default local paint path. Add boundary
  sensitivity, compact reusable regions and pinned delete selected/all controls.
  Keep optional manual tools for ambiguous boundaries, not mandatory brushing.
- [x] Persist empty/edited layers through reopening; clearing saved paint can
  create a new unpainted version without changing its parent or original.
- [x] Reuse the same wall selection for replacement colours. Finish with AI saves
  a rough preview and prepares a reviewable correction; it does not call AI itself.
- [x] Make unsent local feedback explicit. The owner destination remains pending;
  no email, form submission or paid app AI call was sent during this batch.
- [x] Verify **326 tests**, clean analysis, Chrome release compilation (78.9s),
  Android Kotlin/plugins (2m 52s), seven MP4 metadata/decode/seek/timing probes,
  and documentation links. Source `aba3ee136c`; no new APK or paid app AI request.
- [x] Check actual Chrome release Help navigation, playback/pause, near-end seek,
  full-screen round trip and written fallback/disposal in an isolated profile.
- [ ] Phone acceptance of tap-wall boundaries/speed, video playback and room
  delete/restore. Keep existing data when installing a future requested update.

That source batch did not package an APK; it is now included in 1.0.16 above.
Keep published 1.0.15 and confirmed icon A unchanged;
build another package only on request. Remaining main priorities are durable
Android file linkage, reusing photo facts independently of design preferences,
enforced AI masks and representative larger-project/device/provider measurements.

## Launch walkthrough and short help videos — agreed direction, 21 November

The in-app help should feel like small sections of a real launch walkthrough:
show a person completing a task, the taps and the resulting change. The current
seven recorded demo clips are the first implementation; simulated camera/AI/file
selection does not complete the production recording requirement.

- [ ] After the release interface is stable, record real Android transactions
  using a dedicated sample project, native camera/gallery/file pickers and actual
  saved results. Keep customer projects, notifications and credentials out of footage.
- [ ] Split help into one task per clip: add a photo, choose style/palette, analyse,
  generate/select concepts, refine a result, recolour a wall, compare, save/open,
  share, and use Live design. Split combined clips where they teach different jobs.
- [ ] Aim for roughly 20–45 seconds per task, with a clear starting screen,
  readable captions, visible taps, natural pacing and a completed result. Longer
  tasks can have chapters; shorten AI waits with an explicit cut/time label rather
  than implying instant generation. Narration is optional; captions must stand alone.
- [ ] Reuse the same footage for a longer launch/onboarding walkthrough covering
  the complete journey. This is an asset plan, not a requested upload/publication.
- [ ] Review on the S21 for legibility, matching controls, replay/seek and access
  from the relevant screen. Re-record affected clips when the release UI changes.

No new APK, paid generation or store publication is requested by this clarification.

## Desktop kept current — 21 November

- [x] Rebuild shared source `aba3ee136c` for desktop/Chrome and serve it at the same
  **http://localhost:7357** address. All current room/paint/AI/help changes are included.
- [x] Add optional `-Release` to the existing launcher, with web-scoped feature
  overrides, local Flutter engine assets and a public-bundle-only static server.
  Byte-range responses fix MP4 duration/near-end seeking on desktop. No-store caching
  updates code/assets without replacing saved browser projects or settings.
- [x] Pass **327 tests**, clean analysis, eight focused responsive checks and the
  actual 1440px Chrome Settings/help/play/pause/seek/full-screen/fallback test.
  Release rebuild: 51.2s. No paid AI, customer-data edits or new APK.
- [x] Document how to restart the same preview after closing it/restarting Windows.
  The packaged native Windows companion remains separate future work.

## Confirmed A icon — 21 November, requested 1.0.15+16

- [x] User confirmed A for now: olive green, cream room outline and sparkle.
- [x] Install the existing reviewed vector artwork across the platform icon assets;
  add Android adaptive/themed resources and matching startup/header/web branding.
  All 40 files match the reviewed A candidate; no generated image/API call needed.
- [x] **315 tests pass**, icon export passes, analysis is clean, and Chrome/Android release builds pass (138.1/155.1 seconds). Source `ce6b2da600`; 77,161,254 bytes; SHA256 `E0A4487484CE5F595559201C39FAB1265F5033528A6C21856770897A8CCC3E0D`.
  Verify the compiled olive/cream icon in the APK, matching 1.0.14 certificate,
  existing app ID, private-file exclusion and unchanged previous APKs.
- [ ] Accept on S21: install over the existing app; check the launcher and header
  show A, then reopen the existing project and saved AI connection.

This selection accepts the earlier offer to apply A and provide an updated test
APK. More packages still need a request. Further icon refinement is optional;
confirmation is no longer a blocker for the current branding.

## Requested test release — 21 November, 1.0.14+15

- [x] Review unfinished conversation items against the actual source and brief.
- [x] Add manual local wall paint: polygon/brush/erase, colour strip/custom hex,
  per-wall layers, shading approximation, Undo/Redo and comparison. No provider call.
- [x] Keep source images and approvals unchanged; save a new lossless PNG and
  local-operation recipe. Bind drafts to their working image, and keep layers
  through reopening and plain/password-protected portable copies.
- [x] Add Japanese, Italian, Moroccan and Indian, plus a regional-influences
  section alongside existing styles (23 styles total; 12 palettes unchanged).
- [x] Include the previously verified Feedback draft/copy/handoff tools in this APK.
  Delivery still needs the owner's public support email or HTTPS form URL.
- [x] **315 tests pass**, analysis is clean, and Chrome/Android release builds pass (111.2/234.8 seconds). Source `ca541ef971`; package size 77,151,194 bytes;
  SHA256 `A81CCF75510CB9C497E7BDA1EF5D69A0D90E9FFEC3C8B76F4CBBCF56BE1F707B`. Existing icon, signing identity and previous APKs preserved.

Next phone test: install over the existing app without uninstalling, reopen the
existing project, try Paint walls without a key, leave/reopen a draft and save a
version. Check regional choices and Feedback draft retention. Physical performance,
real provider comparisons and actual feedback delivery are not established by mocks.
Remaining release priorities: durable document-file linkage, analysis reuse,
enforced AI edit masks and larger-project measurements. A is confirmed above.
Wallpaper, automatic wall detection, tracked AR, accounts/payments and a packaged
desktop companion are later stages, not included in this test APK.

## Feedback follow-up — source after APK 1.0.13, 20 November

- [x] Add Feedback in contextual Help and Feedback and ideas in Settings, with
  Report an issue / Suggest a feature, title/details and a report preview.
- [x] Autosave a separate device-local feedback draft; reopen it from either
  entry point. Keep failed saves open for retry; confirm deliberate draft clearing.
  Feedback text stays out of portable projects and does not change room data.
- [x] Add Copy report and public email/HTTPS-form handoff hooks. Optional diagnostics
  contain only build/platform; no automatic photos, projects, logs or AI settings.
  A handoff never claims delivery, and retains the draft. No submission API/telemetry.
- [x] Verify all 305 tests, clean analysis, Chrome release compilation (42.2 seconds)
  and Android Kotlin compilation. Source stamp `937602d939`. This source was added
  after 1.0.13 and is now included in the requested 1.0.14; no actual report sent.
- [ ] Connect the owner's support email or existing HTTPS feedback-form URL. An
  asynchronous choice is pending; both build-time contact flags currently default
  empty, so delivery is explicitly unconfigured. Do not use the private code repo.
- [ ] Verify real delivery/receipt on Chrome and S21 after contact configuration;
  check missing email client, form login/privacy settings and browser restrictions.
  Hosted forms need the user to paste/submit the copied report; there is no direct
  form POST or server receipt confirmation. See docs/TESTING_GUIDE.md.

## Verified outstanding-items batch — 20 November

Credits/approval review are available again. **All 296 tests pass**, static
analysis is clean, and the final release web build passed in 102.4 seconds.
The requested **1.0.13+14** Android package is built and verified from source
`f69772aaa0` (145.5 seconds). This batch adds:

- Open project keeps portable IDs, resumes an unchanged matching project and
  offers keep-local/open-file-copy choices for divergent work. A first import
  publishes the project last and rolls back only its newly staged data on failure.
- New generated versions capture detached settings, saved analysis,
  provider/model/quality and concept direction alongside the exact prompt.
  History offers Saved settings / Use these settings / Refine this design.
  Older versions retain their original image/prompt without guessed settings.
  Portable copies remap saved-analysis image references. Failed design-record
  writes clean up only that call's new record/image; if record cleanup fails,
  retain its image rather than leave a recoverable record with missing bytes.
- Startup paints a loading surface before storage opens, with non-destructive
  Retry on failure. Existing Hive box names and project data remain unchanged.
- Full-screen Save image / Share creation export only a sanitized PNG copy.
  Android supports Gallery and its share sheet; Chrome uses sharing/downloads.

Nine regression cases cover repeated Open/restart, conflicts, failed-import and
partial-write cleanup, immutable recipes/analysis/copy remapping, history reuse
and startup loading/Retry. Four further export cases cover the native channel,
old-Android chooser cancellation, metadata stripping/original preservation,
busy/failure/retry feedback and compact controls. Existing API/backup suites pass.
No real app AI calls or actual customer-data edits were made.

The user requested the next APK and renewed credits to finish it. Keep the
current icon unless a new one is confirmed. Old APKs remain for rollback; further
packages still require a request.

Branding: A was confirmed for now on 21 November and installed for 1.0.15. Six
earlier vector alternatives remain at
`output/design-review/icon-refinements/renovision-icon-refinements.png`, with
individual A–F SVGs. Regenerate previews with `tool/preview_brand_options.ps1`.
The 1.0.14 package retained the original platform icons. The approved candidate
at `output/design-review/icon-a-candidate/` is now applied, including the header
and startup mark. The exporter still defaults to previews; the user-confirmed
installation used `INSTALL_RENOVISION_ICON=true`.

Published `output/mobile-test/renovision-test-1.0.13.apk` and the latest alias.
Package ID/code/name, matching signing identity, ARM64/optional camera, restricted
share provider and absence of private project/key assets are verified. Size:
76,560,654 bytes; SHA256
`ED2BCFF73C2FD2F76FA8A8862C393387A3091458ED2754DE8DC7FCC3CD141E90`.
All previous APK checksums and platform icons are unchanged. Android persistent
document URI overwrites, enforced masks, lazy image storage, real Gemini
comparisons and tracked AR remain outstanding. Next: physical S21/Chrome acceptance.

## Where we are

The private app already supports the core photo → analysis → prompt → multiple
concepts → select → refine → compare → save workflow, with direct internet AI
on Android and a same-view camera overlay. The user has successfully tested
phone generation and project auto-reload. The chosen Focus Canvas design stays.

Launch direction confirmed 20 November: Standard starts with users' own developer
API keys; grow adoption before building included subscription AI/other Pro options.
Local projects/save/share need no RenoVision account. Managed credits/subscriptions
and recoverable account entitlements are later work, with no current price promise.
An optional paid desktop companion is a later milestone: phone capture/analysis/
first design, larger-screen refinement. Chrome already supports the large-screen
workspace; native Windows packaging and automatic cross-device sync are unverified.
Portable project files can transfer work now; keys stay separate on each device.

The previous **1.0.12+13** package contains camera handoff, history captions,
room chooser/live entry, compact layouts, themes and protected backups. The
requested **1.0.13+14** adds the verified 20 November batches below. Physical S21
acceptance remains; no paid API calls or user-data reset.

## 20 November feedback batch — included in requested 1.0.13

- [x] Make AI connection/models the first expandable settings card with status;
  collapse the lower-priority appearance choices into a matching card.
- [x] Add recoverable Delete beside image tools, guarding originals, approved
  baselines and active AI requests.
- [x] Expose New design / Precise correction above the brief; enable 2/3 outputs
  in both modes, keeping correction variation strictly scoped.
- [x] Store a separate precision output count with a safe one-output legacy
  default, so old three-concept settings never silently raise correction usage.
- [x] Strengthen short/blank whole-room design briefs and AI prompt-writing
  initiative, while preserving narrow corrections and explicit Keep requirements.
- [x] Add account-aware Room design / Quick ideas / Final detail model presets;
  prefer 2.6 Sunburst/medium on fresh direct connections, preserve saved choices.
- [x] Verify 258 tests and clean analysis; the preceding UI batch's web build
  passed in 74.9 seconds and was not repeated for the naming correction.
  Chrome's test iframe stalled before execution; manual browser acceptance remains.
- [x] Retain vetted model availability across restart; add explicit model refresh
  for older saved connections without resending photos or re-entering the key.
- [x] Correct automatic Live room labels to the selected type, e.g. Bedroom (Live),
  including room-picker starts and type changes. Preserve the automatic-label
  flag through save/restore; explicit custom renames stop automatic naming.
  Unknown types show Unspecified (Live), not a guessed or generic Room label.
- [x] Keep the user-confirmed RenoVision name and update source display labels;
  retain the package ID, storage and signing identity.
- [x] Generate a second six-icon preview board after rejection of the initial
  icon set; the latest marked preference is first-board A (RenoVision olive room
  outline and sparkle), preferred so far. Clean launcher assets remain pending. Preview/prompt in
  `output/design-review/brand-icons-2026-11-20-v2*`.

Gemini is now a separate direct HTTPS provider with its own Google key. The
recommended catalogue is browsable without keys: OpenAI 2.6 Sunburst/Flare and
Nano Banana 2.1/Pro. Account-listed image models are filtered to these supported
editors (older OpenAI 2.5 models remain for compatibility). Android stores each
key in its own encrypted vault; switching retains each provider's model/quality.
Gemini analysis uses an available supported vision model and the same saved
observations/editable-prompt workflow. Google requests use stateless Interactions;
neither provider automatically retries or receives the other's key.
Claude can be considered for analysis later, not as the image renderer.
Real Gemini quality/access testing remains pending the user's Google API key.
Verification: all 275 tests pass, static analysis clean, final web release build
passed (78.1 seconds), Android Kotlin compilation passed (no APK packaged).
Existing 1.0.12 APK hash and the original project brief remain unchanged. Provider
responses were mocked; no real app API request or customer-data reset was made.
The requested 1.0.13 includes this follow-up; 1.0.12 does not.

## In-app walkthrough follow-up — included in requested 1.0.13

- [x] Add Sample walkthroughs to the existing tap/hover information dialogs,
  retaining the current screen's help and Close action.
- [x] Group Camera & photos with separate Choose photos, Take a photo and Live
  view paths, then Design & refine, Image tools & compare and Save & reopen.
- [x] Provide six read-only examples using a fictional kitchen, one step at a
  time with Next/Previous/Done and progress. Reading guides needs no API key and
  makes no camera, AI or project-storage changes.
- [x] Explain paid confirmations, reference capture, same-view still overlay,
  manual prompt/image handoff, version recovery and portable-file/key boundaries.
- [x] Verify all six navigation paths, return to existing project without writes,
  existing context help, 320px phone and landscape layouts at 180% text size.
- [x] All 279 tests pass, static analysis is clean, release web build passed in
  85.2 seconds. Existing APK/brief/data retained; no new APK or paid AI request.
- [ ] Physical phone acceptance after the next explicitly requested APK.

## Model comparison and brand preference follow-up — included in requested 1.0.13

- [x] Keep the four primary image candidates: Gemini Nano Banana 2.1 / Pro and
  OpenAI GPT Image 2.6 Sunburst / Flare; account access still controls selection.
- [x] Mark recommendations as an unranked shortlist and link Settings directly
  to Compare AI models, also available in Help as the seventh sample walkthrough.
- [x] Explain fixed inputs/brief, one output per model, reselecting the original,
  manual quality/fidelity/creativity ratings and separately recorded time/cost.
- [x] Add an opt-in fixed-brief test switch in AI settings. A one-output request
  sends the prepared brief unchanged, without rotating concept directions. Block
  multi-output test requests before confirmation; preserve saved room counts.
  Reset the testing aid off at app restart and keep normal design variety intact.
- [x] Read the user's marked icon from the corrected Windows image path; its
  checksum matches the preserved first board. Record A as preferred so far.
- [x] Verify 36 focused tests, all 283 regression tests, clean analysis and final
  release web compilation (83.3 seconds). Original brief, APK checksum, images,
  credentials and launcher assets preserved. No real app AI call or APK build.
- [ ] Run real-room comparisons with the user's keys and rank by task before
  launch. No stored ratings/automatic paid benchmark or automatic ranking yet.
- [x] Prepare preview-only adaptive/vector launcher candidates and six colour/
  design alternatives. Existing launcher icons remain unchanged.
- [x] User confirmed A for now on 21 November; install it in the current source
  and requested 1.0.15 APK, preserving identity/storage. Further refinements optional.

## Completed audit batch

- [x] Read the brief and inspect actual source/tests/platform code.
- [x] Reconcile the substantive requests throughout the conversation with code.
- [x] Render/review 11 current phone/desktop screens using fictional fixtures.
- [x] Identify incomplete precision, per-version settings, document identity,
  analysis reuse, performance and live-camera requirements.
- [x] Replace stale status/task diaries with current capabilities and priorities.
- [x] Add `*.renovision` to Git ignores alongside plain project exports.
- [x] Preserve all local records, private images, settings and existing APKs.

## Completed workspace cleanup — 19 November 2026

- [x] Remove about 2.02 GB (1.89 GiB) of generated build/tool/test caches,
  superseded logs and obsolete APKs 1.0.8/1.0.9.
- [x] Keep current APK 1.0.11 plus its alias, rollback 1.0.10, the latest web build,
  application verification logs and current visual-review evidence.
- [x] Consolidate 107 legacy source/tool copies into one ignored ZIP, verifying
  every entry byte-for-byte before removing loose copies.
- [x] Confirm 14 retained-file hashes unchanged, including APKs, recovered exports,
  original brief, package configuration and local SDK/editor configuration.
- [x] Preserve all application source/assets/tests/platforms, project photos,
  local settings, browser profiles and original document/recovery archives.

Cleanup manifest: `.local_backups/cleanup-2026-11-19-refresh.json`, no unresolved
failures. Source history archive: `.local_backups/archives/`. No application-code
changes, paid AI calls or new APK. Removed caches regenerate on the next build;
rerunning the application suite solely for cleanup would recreate those caches.

## Completed requested APK — 1.0.12+13

- [x] Bump package version, rerun all 249 tests/static analysis and build Android.
- [x] Verify application ID/version, matching 1.0.11 signing identity, ARM64 support,
  optional camera, internet permission and no microphone/storage-write permission.
- [x] Check bundled assets match fictional samples and no local project/credential
  files are packaged; verify source stamp and preserve older APK checksums.
- [x] Write `output/mobile-test/renovision-test-1.0.12.apk`, its checksum and latest
  alias `renovision-test.apk`. Retain previous packages and verification records.

Source stamp `3cb94c972c`; SHA256
`CD3A047F2D84C515B279F2686B506017AB1A46199A00038A23B410799A88CB99`.
Install as an update without uninstalling. No device installation or paid generation
was performed by this build. The next action is the phone acceptance below.

## Recommended implementation order

Each numbered batch needs its own validation and local commit. This is a backlog,
not a claim that the following changes were implemented during the audit.

### 1. Accept the newly packaged source changes on S21

- [ ] Accept 1.0.14 on the phone: Settings discovery, toolbar delete, model presets,
  2/3 correction variations, Saved settings/reuse and repeated Open/conflicts.
- [x] Package and verify the requested **1.0.13+14**, including Save image / Share
  creation, all 296 tests, clean analyzer and final Chrome/Android release builds.
- [x] Build the explicitly requested **1.0.12+13** with the existing application
  ID/signature so it updates without uninstalling. Future APKs only when requested.
- [ ] On S21, check the camera result remains in the live viewer and automatically
  overlays, including delayed camera startup and keyboard opening/closing.
- [ ] Verify history captions, small room tiles, all three Camera/Photos/Live
  entry choices, typed live-room names and compact Rooms page.
- [ ] Check compact typography, enlarged system text, five themes/restart retention,
  storage details and plain/password-protected export/restore across devices.
- [ ] Open existing projects without clearing storage. Confirm images, approvals,
  drafts and Android API connection survive restart/update.

### 2. Make Open / Save a reliable document workflow

- [x] Give portable projects stable document identity without changing original
  photo/version IDs. Preserve compatibility with old plain/protected files.
- [x] **Open** resumes an unchanged matching project. **Restore a copy** duplicates
  deliberately. Divergent revisions offer Keep local / Open file as copy; no merge.
- [ ] Persist Android document URI permissions and overwrite the linked destination
  when supported; handle revoked access, moved files and provider limitations.
- [x] Reconnect a browser file handle on repeated Open without silently creating
  another project; divergent copies and protected files never link plaintext saves.
- [ ] Persist/recover browser handles across restart where supported, with permission
  recovery and clear fallback. Currently reopen/reselect the file to reconnect.
- [ ] Keep local autosave and portable-file status distinct. Add durable recovery
  for interrupted writes, unavailable storage and startup errors.
- [x] Paint startup before storage opens, with non-destructive Retry; stage first
  Open safely and clean up newly allocated failed design saves.
- [x] Exercise restart, repeated Open/conflicts, failed imports/writes and copies
  using disposable fixtures. Real multi-device file acceptance remains.

Acceptance: opening the same file twice resumes one project; restore-copy still
creates an independent project; cancelled/failed writes never lose local work.

### 3. Save the complete recipe for every generated version

- [x] Snapshot room type, styles/custom text, palette, scope/Keep-Replace, protected
  features, generation mode, correction/brief, input images, analysis revision,
  final prompt, model/quality and concept direction into each version.
- [x] Keep older records readable and include snapshots in portable backups.
- [x] Add **Use these settings** and **Refine this design** actions with an obvious
  active source/mode. Do not silently change the approved baseline.
- [x] Preserve previous analyses referenced by versions, instead of only the latest.

Acceptance: an older option can be reopened with its exact saved choices, and a
new child changes only the intended instruction while retaining its provenance.

### 4. Separate photo understanding from design drafting; benchmark quality

- [ ] Cache observed room facts by primary/supporting images and analysis version.
  Rebuild the design brief from current preferences without unnecessary reanalysis.
- [ ] Keep consent, conflicting Keep/Replace checks and stale-image protection.
- [ ] Add optional structured room-type suggestion with confidence and confirmation.
- [ ] Benchmark a real kitchen/office case: one concept, three materially distinct
  concepts, mixed styles, new palette, updated appliances/flooring and a narrow edit.
- [ ] Record time spent preparing/uploading/waiting/saving, model/quality, actual
  provider usage where available, adherence and diversity. No claims of "best"
  or cheaper models until measured on identical inputs.
- [ ] Consider output critique/perceptual similarity checks before automatically
  claiming options are different. Never automatically repeat billed requests.

OpenAI and Gemini adapters are implemented. Compare identical real-room inputs
with explicit consent before claiming one is best or cheaper. Further providers
remain optional; an assistant name alone is not an image API.

### 5. Implement genuine controlled precision editing

- [x] Review competitor paint/material tools and inspect our existing editor on
  20 November. Record a local-finishes-first design in docs/PRODUCT_NOTES.md;
  the local paint implementation followed on 21 November.
- [x] Local wall paint on an original or saved AI design.
  Select once with polygon/brush/eraser, correct edges and exclude foreground
  objects; reuse that mask for palette trials without AI calls or a key.
- [x] Preserve shading/texture where feasible; add per-wall colours, swatch picking,
  undo/redo, source-design comparison and explicit Save version. Keep the image
  visible with compact area/colour controls on the paint screen.
- [x] Persist source-bound masks/layers and local-edit provenance through autosave,
  history and plain/protected project copies. Preserve original/generation records;
  fresh crops/new designs do not inherit another image's paint draft.
- [x] Verify zero provider calls and decoded pixel equality outside the manual
  selection in lossless full-frame output, plus eraser exclusions/indexed PNGs.
  Keep originals/approved baselines unchanged.
- [ ] Benchmark Chrome/S21 preview/export and visually check tricky edges,
  reflections and dark/light changes. The preview is an approximate colour trial.
- [ ] Follow with local wallpaper: sample import, repeat scale/rotation/offset,
  perspective and foreground exclusions; then evaluate floor/cabinet finishes.
- [x] Add local colour/edge tap-selection and reuse accepted masks, without a paid
  model on each colour tap. Semantic selection and tricky-boundary refinement remain.

Shared foundations for subsequent AI region editing:

- [ ] Persist editable region/annotation geometry and distinguish markup guidance
  from an edit mask. Keep original references intact.
- [ ] Add supported mask transport with correct image dimensions/orientation.
- [ ] Composite region edits into the full original where feasible and flag changes
  outside the selected area. Expose the limitation if preservation is uncertain.
- [ ] Benchmark the brief's window/doorway/cabinet/floor-plan examples. Add image
  rotation as a separate non-destructive edit if still needed.

Acceptance: the returned full-frame correction preserves pixels outside the
allowed edit/composite region, or clearly flags that it cannot guarantee this.
Prompt wording alone does not meet this acceptance condition.

### 6. Measure and improve larger-project performance

- [ ] Time startup/route first paint, editor preview, API image preparation and
  plain/protected backup operations on representative S21 and Chrome projects.
- [x] Add startup loading/error Retry before opening existing Hive boxes (1.0.13).
  Eager image loading and journaled crash recovery still need separate work.
- [ ] Bound image decoding/version-thumbnail work. Review web worker/background
  options for heavy image/export work; native isolates already handle some tasks.
- [ ] Plan lazy/photo-file storage only if benchmarks justify it, with a reversible,
  validated migration preserving originals, IDs, approvals and export support.

### 7. Polish hierarchy within the selected visual design

- [ ] Projects: prioritize Continue/saved projects for returning users; shorten
  discovery content and keep inspiration chiefly in Explore.
- [ ] Room: consolidate active image/baseline information; surface photos/analysis.
- [ ] Style: show current style/palette compactly; open a sheet/picker for all choices.
- [x] Add base style and cultural/regional influence choices, including
  Japanese and Italian, alongside existing custom text and Modern/Contemporary.
- [ ] Refine: distinguish **Create concepts** from **Refine selected design** and
  show source/mode without opening an advanced accordion.
- [ ] Ideas: history/selection before secondary manual-AI copy/import controls.
- [ ] Review Explore/Library naming, short room labels and singular/plural captions.
- [ ] Keep touch targets, tap-accessible help and system text scaling. Test contrast,
  semantics/screen readers, keyboard and portrait/landscape, not only fewer scrolls.

See the [screen-by-screen design assessment](docs/PRODUCT_NOTES.md#whole-project-design-audit--19-november-2026).

### 8. Finish library/export/privacy management

- [ ] Typed inspiration/material/sketch/plan reference attachments, separately
  labelled from other angles of the real room; apply sample presets to an existing room.
- [ ] Broader illustrated room/style samples; optional material/options design boards.
- [x] Room deletion with typed confirmation, Undo and persistent recovery.
- [ ] Project deletion, secondary-photo management,
  storage usage and permanent purge rules respecting version references.
- [x] Add Save image / Share creation in the full-screen viewer: Android 10+
  Gallery, older Android chooser, native share sheet; Chrome sharing/download
  fallback. Only a sanitized PNG is exported; original/project/key data stays intact.
- [ ] Accept save/share on the S21 and Chrome; add comparison/overlay composites.
- [ ] Decide Android OS backup/device-transfer policy for photos/metadata; protect
  credentials independently and explain the resulting behaviour.
- [ ] Assess local database/photo encryption, key recovery and safe migration. Current
  password protection is for portable backups, not the internal store.

### 9. Advance live-camera capability as a separate milestone

- [ ] Measure and polish the existing consent/capture/analyse/generate/overlay flow.
- [ ] Save clean camera/design composites and explicit alignment metadata.
- [ ] Investigate tracked surface preview, pose/depth/occlusion and viewpoint mismatch.
- [ ] Only then assess consistent whole-room moving-view rendering and bounded
  paid live sessions/partial previews. No fake scan percentage or instant-video claim.

### 10. Public release later

- [ ] Validate Standard BYO-key adoption and onboarding before investing in
  managed subscription AI credits/Pro services. No launch price is set.
- [ ] Test the modest side-income proposition: introductory A$4.99 vs A$9.99
  one-off Standard unlock, with AI billed separately, against real tester value,
  onboarding friction and support costs. Prices are hypotheses, not implemented.
- [x] Refresh public DecAI, Renovate AI Studio and Remodel AI cost models on
  20 November: subscriptions, allowances/credits, annual offers and AU iOS
  benchmarks, with separate Remodel AI product identities. Research is in
  docs/PRODUCT_NOTES.md under Pricing review; no app pricing or APK change.
- [ ] Verify exact Australian Android paywall offers/renewals, quotas/top-ups and
  cross-device rights; benchmark total cost per accepted room before pricing.
- [ ] Later, assess recoverable accounts, server-verified purchases/allowances
  and bounded company-funded AI. Keep local creation/save/share account-free.
- [ ] Assess an optional paid Windows companion using the shared Flutter app;
  validate packaging, native files/keys and paid entitlement before release.
  Keep portable-file transfer separate from any later automatic cloud sync.

- [ ] Production package/signing, privacy documentation and recovery/support;
  current display name and icon A are confirmed.
- [ ] If selling AI usage: hosted HTTPS backend, secret management, enforced credits,
  pricing/unit economics, payment validation and explicit limits.
- [ ] Physical-device matrix, release profiling, store/package review and separate
  iOS platform verification. Preserve the single shared Flutter codebase.

## Conversation coverage

| Requested item | Current outcome / remaining work |
| --- | --- |
| Inspect existing app, preserve work and data | Completed; audit-only changes, no rewrite/migration |
| Comprehensive room list, more palettes/styles | 42 types / 23 styles / 12 palettes; more illustrated examples pending |
| Multiple room images and consolidated context | Implemented; up to six originals, explicit primary/supporting roles |
| Colour selection, smarter prompt, AI photo analysis | Implemented with per-generation analysis/settings snapshots; facts caching/reanalysis needs work |
| Change paint/wallpaper without regenerating a room | Manual paint in 1.0.14; source now adds local tap-selection and persistent layer deletion; semantic boundaries and wallpaper/perspective remain |
| Japanese/Italian and other regional influences | Japanese/Italian/Moroccan/Indian added, grouped with existing regional styles; custom text remains |
| Modern equals contemporary; mixed styles | Combined label; blending and separate-style comparisons implemented |
| Whole-room default, clutter/floors/appliances | Implemented defaults plus optional room-specific Keep/Replace overrides |
| Multiple genuinely different concepts | 1/2/3 distinct-direction requests implemented; semantic diversity validation pending |
| Select and improve a generated design | Branching/precise correction, explicit modes and saved settings reuse/refinement implemented |
| Zoom/landscape and before/after slider | Implemented; real device acceptance continues |
| Crop handles, colours/shapes/comments | Implemented; editable saved geometry and true masks/compositing pending |
| Delete generated images and rooms | Recoverable design deletion and typed room deletion/restore implemented; permanent purge/project deletion pending |
| Autosave shortcut, Save on exit, Save as/Open | Open resumes matching work with explicit conflict choices; persistent Android destination retention incomplete |
| Lost work after a new localhost URL | Fixed preview origin/provided recovered copies; keep same Chrome address/profile |
| Repeated restored text | Suffix fixed; unchanged repeat Open now resumes one project; Restore copy deliberately duplicates |
| Direct phone API, no laptop | Implemented; user reports success; Android key encrypted separately |
| Different copy prompts for assistants | One provider-neutral manual handoff retained; no extra provider needed for it |
| Visible AI progress and faster editor | Stages/elapsed/preview work implemented; large-project benchmarks pending |
| First-room workflow, compact text/help/toolbars | Implemented; focused hierarchy/accessibility polish pending |
| New look B / all controls close to image | Focus Canvas implemented; compact selected-style/palette summary pending |
| Stock/custom home image | Implemented; separate from last-opened project/image |
| Camera/gallery as primary inputs | Implemented, plus Live design choice in room setup |
| Design in viewer, immediately overlay, keep camera open | Automatic-overlay/handoff corrections packaged in 1.0.12; phone acceptance pending |
| Live scan, moving-camera renovation, snapshot to refine | Still capture + generated overlay/refine exists; true tracked live transformation/composite export pending |
| Library/history captions below image | Both packaged in 1.0.12; phone acceptance pending |
| Smaller room icons, type-based Live room label | Compact icons in 1.0.12; final type-based automatic naming in requested 1.0.13; phone acceptance pending |
| Themes and settings storage/encryption TODOs | Five themes, storage details, encrypted export completed; internal encryption/OS backup policy pending |
| Competitor/review/pricing research | Public pricing refreshed 20 November for DecAI/Renovate AI/Remodel AI; currencies/platforms/allowances separated; Android checkout and own cost/value testing pending |
| Online feature/issue feedback | Form, saved drafts, copy and email/form handoff hooks included in 1.0.14; owner's delivery address/URL and real receipt test pending |
| Video-style walkthroughs | Seven recordings of real app transactions with sample data; eight guides, playback and written fallback; physical Android playback acceptance remains |
| Cleanup, minimal docs, Git ignore, commits | Four root/two guide documents; generated/private data ignored; local verified commits, no push |
| APKs only when requested | Honoured; A selection accepts the offered updated 1.0.15 APK; further builds need a request |

## Working rules for every batch

Preserve the normal Chrome profile at `http://localhost:7357`, Android app data,
original photographs, IDs, prior backups and signatures. Never clear data or
uninstall as a routine fix. No real keys/private photos in Git or project exports.
Use synthetic/disposable fixtures for failure cases. Obtain explicit consent for
paid AI requests, never retry them silently. Run relevant tests, then the required
suite/analyser for implementation changes; update these documents and commit
locally. Do not push or produce an APK without the user's request.
