# Renovision next steps

Current task list after the full code/conversation/design audit, 19 November
2026 (Australia/Sydney). This supersedes the older chronological work lists.
Requirements remain in [the project brief](RENOVISION_PROJECT_BRIEF.md);
[current capabilities and limits](FEATURE_STATUS.md) are recorded separately.

## Where we are

The private app already supports the core photo → analysis → prompt → multiple
concepts → select → refine → compare → save workflow, with direct internet AI
on Android and a same-view camera overlay. The user has successfully tested
phone generation and project auto-reload. The chosen Focus Canvas design stays.

Application baseline audited through `a948da0` is packaged in **1.0.12+13**,
source `3cb94c972c`. All 249 tests were rerun and passed, analyser clean, Android
release build passed in 139.1 seconds. The preceding web build also passed.
Camera handoff, history captions, room chooser/live entry, compact layouts,
themes and protected backups are now in the requested APK. Physical S21
acceptance remains. No paid API calls or user-data reset.

## 20 November feedback batch — source only

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
Next APK only on explicit request; 1.0.12 does not contain this follow-up.

## In-app walkthrough follow-up — source only

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

## Model comparison and brand preference follow-up — source only

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
- [ ] Prepare a clean adaptive launcher asset from the preferred A direction.
  Existing app icon, package/signing identity and customer data stay intact.

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

- [ ] When requested, package the 20 November source follow-up and test its
  Settings discovery, toolbar delete, model presets and 2/3 correction variations.
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

- [ ] Give portable projects stable document identity without changing original
  photo/version IDs. Preserve compatibility with old plain/protected files.
- [ ] **Open** should resume/reconnect a matching local project. **Restore a copy**
  should deliberately duplicate it. Handle conflicting/newer revisions explicitly.
- [ ] Persist Android document URI permissions and overwrite the linked destination
  when supported; handle revoked access, moved files and provider limitations.
- [ ] Reconnect browser handles safely where supported; otherwise explain/reselect
  a destination without silently creating another local project.
- [ ] Keep local autosave and portable-file status distinct. Add durable recovery
  for interrupted writes, unavailable storage and startup errors.
- [ ] Exercise restart, repeated Open, failed writes and multiple devices/copies
  using disposable fixtures before touching any real project store.

Acceptance: opening the same file twice resumes one project; restore-copy still
creates an independent project; cancelled/failed writes never lose local work.

### 3. Save the complete recipe for every generated version

- [ ] Snapshot room type, styles/custom text, palette, scope/Keep-Replace, protected
  features, generation mode, correction/brief, input images, analysis revision,
  final prompt, model/quality and concept direction into each version.
- [ ] Keep older records readable and include snapshots in portable backups.
- [ ] Add **Use these settings** and **Refine this design** actions with an obvious
  active source/mode. Do not silently change the approved baseline.
- [ ] Preserve previous analyses referenced by versions, instead of only the latest.

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
- [ ] Add a startup loading/error/recovery surface; avoid a blank launch while
  opening large eager image boxes.
- [ ] Bound image decoding/version-thumbnail work. Review web worker/background
  options for heavy image/export work; native isolates already handle some tasks.
- [ ] Plan lazy/photo-file storage only if benchmarks justify it, with a reversible,
  validated migration preserving originals, IDs, approvals and export support.

### 7. Polish hierarchy within the selected visual design

- [ ] Projects: prioritize Continue/saved projects for returning users; shorten
  discovery content and keep inspiration chiefly in Explore.
- [ ] Room: consolidate active image/baseline information; surface photos/analysis.
- [ ] Style: show current style/palette compactly; open a sheet/picker for all choices.
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
- [ ] Room/project deletion with confirmation/recovery, secondary-photo management,
  storage usage and permanent purge rules respecting version references.
- [ ] Android Share/Save to Gallery and clean comparison/overlay snapshot exports.
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

- [ ] Production identity/name/icon/signing, privacy documentation, recovery/support.
- [ ] If selling AI usage: hosted HTTPS backend, secret management, enforced credits,
  pricing/unit economics, payment validation and explicit limits.
- [ ] Physical-device matrix, release profiling, store/package review and separate
  iOS platform verification. Preserve the single shared Flutter codebase.

## Conversation coverage

| Requested item | Current outcome / remaining work |
| --- | --- |
| Inspect existing app, preserve work and data | Completed; audit-only changes, no rewrite/migration |
| Comprehensive room list, more palettes/styles | 42 types / 19 styles / 12 palettes; more illustrated examples pending |
| Multiple room images and consolidated context | Implemented; up to six originals, explicit primary/supporting roles |
| Colour selection, smarter prompt, AI photo analysis | Implemented; caching/reanalysis and historical snapshots need work |
| Modern equals contemporary; mixed styles | Combined label; blending and separate-style comparisons implemented |
| Whole-room default, clutter/floors/appliances | Implemented defaults plus optional room-specific Keep/Replace overrides |
| Multiple genuinely different concepts | 1/2/3 distinct-direction requests implemented; semantic diversity validation pending |
| Select and improve a generated design | Branching/precise correction implemented; clearer mode/settings restoration pending |
| Zoom/landscape and before/after slider | Implemented; real device acceptance continues |
| Crop handles, colours/shapes/comments | Implemented; editable saved geometry and true masks/compositing pending |
| Delete generated images | Recoverable delete/undo implemented; permanent purge/project-room deletion pending |
| Autosave shortcut, Save on exit, Save as/Open | Implemented controls; same-document reopening/Android destination retention incomplete |
| Lost work after a new localhost URL | Fixed preview origin/provided recovered copies; keep same Chrome address/profile |
| Repeated restored text | Name suffix fixed; repeated file Open can still duplicate a project |
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
| Smaller room icons, type-based Live room label | Packaged in 1.0.12; phone acceptance pending |
| Themes and settings storage/encryption TODOs | Five themes, storage details, encrypted export completed; internal encryption/OS backup policy pending |
| Competitor/review/pricing research | Dated notes retained; no fresh pricing verification or promise to undercut costs |
| Cleanup, minimal docs, Git ignore, commits | Four root/two guide documents; generated/private data ignored; local verified commits, no push |
| APKs only when requested | Honoured; no APK produced during this audit |

## Working rules for every batch

Preserve the normal Chrome profile at `http://localhost:7357`, Android app data,
original photographs, IDs, prior backups and signatures. Never clear data or
uninstall as a routine fix. No real keys/private photos in Git or project exports.
Use synthetic/disposable fixtures for failure cases. Obtain explicit consent for
paid AI requests, never retry them silently. Run relevant tests, then the required
suite/analyser for implementation changes; update these documents and commit
locally. Do not push or produce an APK without the user's request.
