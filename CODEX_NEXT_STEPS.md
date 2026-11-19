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

Latest source baseline: `a948da0`, 249 tests passed, analyser clean, web build
passed. Latest existing phone package: **1.0.11+12**, source `5a37fa0234`.
The newer camera handoff, history captions, room chooser/live entry, compact
layouts, themes and protected-backup changes are **source only**. The audit
updated documents and ignored protected export files; it built no APK and made
no paid API calls.

## Completed audit batch

- [x] Read the brief and inspect actual source/tests/platform code.
- [x] Reconcile the substantive requests throughout the conversation with code.
- [x] Render/review 11 current phone/desktop screens using fictional fixtures.
- [x] Identify incomplete precision, per-version settings, document identity,
  analysis reuse, performance and live-camera requirements.
- [x] Replace stale status/task diaries with current capabilities and priorities.
- [x] Add `*.renovision` to Git ignores alongside plain project exports.
- [x] Preserve all local records, private images, settings and existing APKs.

## Recommended implementation order

Each numbered batch needs its own validation and local commit. This is a backlog,
not a claim that the following changes were implemented during the audit.

### 1. Deliver and accept the already completed source changes

- [ ] **Only on the user's next explicit APK request:** build a new version with
  the existing application ID/signature so it updates without uninstalling.
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

Another provider is optional. The existing OpenAI route is sufficient for the
basic app. Add Gemini/other image adapters only after comparative evidence and
provider capability/terms checks; an assistant name alone is not an image API.

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
| Design in viewer, immediately overlay, keep camera open | Flow implemented; automatic-overlay/handoff corrections are source after 1.0.11 |
| Live scan, moving-camera renovation, snapshot to refine | Still capture + generated overlay/refine exists; true tracked live transformation/composite export pending |
| Library/history captions below image | Library in 1.0.11; version-history correction source only |
| Smaller room icons, type-based Live room label | Completed in newer source; awaiting requested APK acceptance |
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
