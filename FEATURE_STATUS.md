# Renovision feature status

**Verified source update, 20 November:** Open/resume conflict handling, per-version
settings snapshots/reuse and startup loading/Retry pass regression tests.
**All 296 tests pass**, static analysis is clean and the final release web build
passes (102.4 seconds). Android 1.0.13+14 built in 145.5 seconds from source
`f69772aaa0`; package identity, signing, permissions and bundled files are verified.
Existing platform icons remain unchanged.

The user requested more icon shapes/colours before confirmation. Six previews
are under `output/design-review/icon-refinements/`; A remains preferred so far.
Preview generation uses local vector artwork, without a model key or paid AI call.
The remaining limits below distinguish completed source from device acceptance.

Audited 19 November 2026 (Australia/Sydney) against the project brief, the
conversation and actual source through `a948da0`. This replaces superseded
implementation diaries. The product brief is unchanged.

**Assessment: a working private Android-first beta, with important gaps in
precision enforcement, persistent file linkage and larger-project performance.** Keep the
existing app and Focus Canvas interface; a rewrite is not justified.

## 20 November follow-up — included in requested 1.0.13

AI settings is now the first clearly labelled expandable card with connection
status. App appearance is a matching collapsed card below Home cover/Storage.
Saved designs have a recoverable Delete action beside crop/markup/compare;
originals remain protected and an approved baseline must be replaced before deletion.

Refine shows New design / Precise correction directly. Both allow 1/2/3 outputs:
whole-room concepts versus variations of the specified correction. The new
optional `precisionConceptCount` preference defaults to one for older projects,
separately from the whole-room count, and survives autosave/backups. Selecting
three whole-room ideas therefore does not silently turn an older correction
into three paid requests. Live camera still confirms one preview at a time.

New design briefs with few/no comments now explicitly ask for substantial
coordinated changes within the permitted scope. Analysis prompt-writing no
longer defaults to a conservative near-copy for those requests. Precise corrections
keep narrow instructions. These are improved requests, not measured quality guarantees.

New direct OpenAI connections prefer available GPT Image 2.6 Sunburst at medium
quality. Saved model/quality choices are preserved. Room design / Quick ideas /
Final detail presets change local settings only and use available account models;
generation remains separately confirmed. Gemini is also implemented as a direct
provider with a separate Google key: Nano Banana 2.1 defaults to 2K; Final detail
prefers available Nano Banana Pro/4K. Curated recommendations can be viewed
without a key. Provider switches preserve separate keys and model preferences;
Android restores the selected provider without startup requests. Gemini analysis
uses an available supported vision model and records Gemini provenance. Claude
vision is for analysis, not image output, and has no adapter in this app.
Verified account model lists now survive restart. Older saved connections retain
their known selected model; Refresh available models checks access without sending
photos or re-entering the saved key, and never silently changes a valid selection.

All **296 tests passed** and static analysis is clean. The final release web build
passed in 102.4 seconds. Walkthrough UI is shared Flutter code; physical
phone acceptance remains pending the requested package.
Seventeen new tests cover Gemini transport, key isolation/switching, session-key
expiry, offline restore, safe errors and provider-specific consent. All responses
were synthetic; no paid provider call was made. The preceding Chrome test iframe
stalled before tests; browser
interaction acceptance remains. No paid app API call was made. The requested
1.0.13 includes these changes; installed 1.0.12 does not. The user confirmed RenoVision;
Android/web/Flutter display labels are updated in source while the package ID and
storage stay unchanged. A second board of six different icons was generated with
built-in imagegen. The user's latest mark prefers first-board A (RenoVision olive
room outline and sparkle) so far; dedicated launcher artwork remains pending.

Help dialogs now link to Sample walkthroughs: Camera & photos groups Photos,
Camera and Live view; Design & refine, Image tools & compare and Save & reopen
complete the six guides. Fictional kitchen examples run without a key or camera
and make no AI/project changes. Four new tests cover navigation, returning to an
existing project without writes, small phones, landscape and 180% text size.
Compare AI models is the seventh guide, also linked from AI settings. It explains
fair manual comparisons and makes clear the four core image models are an unranked
shortlist. No paid benchmark, saved rating system or automatic ranking is present.
AI settings also offers Use fixed brief for model tests: one-output requests skip
the usual rotating concept directions. The switch is opt-in and resets off after
restart; multi-output attempts are blocked before payment. Photos must still be
reselected consistently by the tester. Normal saved room choices stay unchanged.
The comparison follow-up adds four tests for guide/settings preservation, exact
prompts across attempts, repeat requests from the original and the pre-send
multi-output guard. Live Gemini quality/access and phone acceptance remain pending.

Live naming correction: generic saved Live names and new automatic room-picker
names display the actual selected type, e.g. **Bedroom (Live)** / **Kitchen (Live)**,
not the literal word Room. They follow a later type change. An optional
`automaticLiveName` flag preserves this behaviour through saves/restores without
rewriting stored names; explicit renaming clears it. Unknown types show
Unspecified (Live) until confirmed. Existing custom names/photos are preserved.

## Source versus installed app

| Item | Verified position |
| --- | --- |
| Latest existing APK | **1.0.13+14**, source stamp `f69772aaa0`; `output/mobile-test/renovision-test-1.0.13.apk`, also `renovision-test.apk` |
| APK contents | Focus Canvas, embedded camera, manual same-view overlay, Live design and all completed source follow-ups below |
| New in 1.0.13 | AI settings discovery, visible delete, 1/2/3 correction choices, creative prompts, typed Live names, OpenAI/Gemini presets, seven help guides, fixed-brief tests, Open/resume/conflict handling, saved recipes/reuse/refine, startup Retry, Save image / Share creation |
| Last APK checks | **296 tests passed**, static analysis clean, final web release 102.4 seconds and Android release 145.5 seconds; matching signing certificate, restricted share provider and private-file exclusion verified |
| Earlier audit | Reviewed code and 11 rendered screens; documentation and private-export ignore correction only. One temporary fixture-rendering test passed. The subsequent requested APK build made no paid AI call or data migration |
| Real user evidence | User reports successful phone installation, direct AI analysis/generation, good generated designs, project auto-reload and useful comparison/camera overlay. This does not validate every newer source change |

APK SHA256:
`ED2BCFF73C2FD2F76FA8A8862C393387A3091458ED2754DE8DC7FCC3CD141E90`.
Size: 76,560,654 bytes. Signature matches 1.0.12; its checksum and rollback
packages remain unchanged. Camera hardware is optional, ARM64 is included, and
no microphone/storage-write permission or private project/credential files are
bundled. Its release-mode build uses the development signing key and example
application ID; it is a private-test package. S21 acceptance remains.

## Features present in the code

Implemented means code exists. Mocked tests and rendered layouts do not establish
provider quality, physical-camera behaviour or durable storage on every device.

| Area | What exists | Limits / unfinished work |
| --- | --- | --- |
| Projects and rooms | Local projects/rooms, rename, continue last room, saved setup progress, immutable originals | No room/project deletion or permanent storage cleanup |
| Room catalogue | 42 home/utility/outdoor types, categories/search/custom names; compact photo-backed main types | Six sample images cover five main room types, not every room/style |
| Design direction | 19 styles, 12 palettes with surface colours, custom style text, style blending or separate comparisons; Modern/Contemporary combined | Compact picker hierarchy needs improvement; selected palette may be outside the initially visible carousel |
| Guided start | Photos → Direction → Analyse/review → Final options; Finish later resumes | Room identification is not a structured AI result that automatically fills the room selector |
| Photo entry | Phone camera, gallery/multiple-photo import, embedded live preview, primary view and additional angles | Up to six original room views; reference images have no separate inspiration/material/sketch role |
| Room scope | Whole-room defaults coordinate surfaces, fittings/appliances, lighting and loose-clutter removal; optional room-specific Keep/Replace and precise correction | Fixed uncertain fittings need explicit instructions; AI compliance is not guaranteed |
| Local paint/material editing | Not implemented; existing palettes guide AI prompts and annotation tools create references | Proposed next batch: reusable surface masks and local wall recolouring without API calls; wallpaper/perspective and other finish layers follow |
| AI analysis | Sends selected photos/preferences to a vision model; saves observations, questions, editable prompt and provenance; new generated versions keep their matching analysis | Normal workspace can still require reanalysis after preference changes |
| Prompt preparation | Offline deterministic fallback, AI-written prompt option, preview/copy, current requirements/protected features, correct working/supporting-image roles | Copying text does not attach photos or automatically return external results |
| In-app AI | OpenAI/Gemini direct HTTPS with separate personal keys and saved model choices; curated image recommendations; optional OpenAI laptop relay; confirmation, progress stages/elapsed time, storage-only result retry | Gemini live account/image quality acceptance pending; no Claude/Bedrock adapter, in-flight paid-job cancellation, actual billed-cost meter or automatic output critique |
| Multiple concepts | One/two/three sequential requests from a frozen source; distinct specified material/design directions; partial successes saved | Strong difference is requested, not measured. Only exact-byte duplicate detection, no semantic diversity scoring |
| Refinement/history | Saved result selection/corrections, branches/parents, exact prompt and input IDs, immutable settings/analysis/model/quality snapshot; Saved settings / Use these settings / Refine this design; favourites/reject/approval | Older/manual/editor versions can lack a recipe; deleted source references must be restored before reuse; no automatic exact-request replay |
| Image viewing/export | Full-screen zoom/pan/pinch, landscape, before/after slider; Save image / Share creation; Android 10+ Gallery, older chooser, native share sheet; Chrome sharing/download fallback | Native/browser acceptance pending; no saved image rotation or comparison/overlay composites; sharing exports pixels only, not editable history |
| Crop/annotation | Resizable/movable crop, pen/line/arrow/rectangle/ellipse/note, colours/widths, select/move/remove and undo/redo; saved as a new reference | No enforced mask, full-frame compositing or persisted editable annotation geometry |
| Design deletion | Recoverable deletion, undo/restore, protected baseline handling | No permanent purge or comprehensive photo/storage manager |
| Camera renovation | Embedded preview/capture, saved-view comparison, manually aligned opacity/slider overlay | A flat image for a matching viewpoint; no camera-pose/depth tracking |
| Live design | Consent → one automatic reference capture/analysis → Room/style/Palette/Brief → confirmed generation → saved preview over camera → Continue to refine | Model latency remains; no continuous room scan, instant video transformation, moving-view redesign or composite/video export |
| Autosave | Debounced drafts, compact status, menu shortcut, manual save, save on normal exit, pending-request guards | Process termination can interrupt pending writes; no journaled crash/corruption recovery |
| Project files | Portable rooms/photos/designs/choices/history/recipes; Open preserves IDs, resumes unchanged matching work and offers Keep local / Open file as copy for conflicts; Restore copy is independent | Browser linkage is session-only; Android does not retain an overwrite destination; no divergent-revision merge |
| Appearance/help | Focus Canvas B, pinned preview and Room/Style/Refine/Ideas controls, desktop split view, contextual toolbars, compact text, tap/hover help with seven offline sample walkthroughs, stock/user-selectable home cover, five saved app themes | More hierarchy work and real-phone accessibility checks needed; themes are separate from renovation palettes |
| Storage/privacy | Actual local storage/origin details, diagnostics; optional password-protected portable backup; Android encrypted API-key storage | Local photo/metadata database is not encrypted by the app; OS backup policy needs an explicit decision |

## Corrections and incomplete requirements

### 1. Open/resume fixed; persistent file linkage remains

Open now validates the portable file and preserves its project/room/version/photo
IDs. Unchanged matching content resumes the existing project without duplication.
Divergent local/file revisions offer Keep local / Open file as copy / Cancel.
No existing revision is silently replaced or merged. Restore copy deliberately
remaps IDs for independent work, including saved-analysis references.
First imports publish the project last and roll back only newly staged records
on failure. Previously created duplicates are not automatically consolidated.

Chrome can reconnect a selected plain file on Open and update it during that
session. A divergent copy is not linked to the original file, and protected
backups never acquire a plaintext save link. Android still uses Create/Open
Document actions without persistent URI linkage. Same-destination Save across
restarts and comprehensive crash recovery remain unfinished.

### 2. Saved generation recipes implemented; legacy limits remain

New in-app AI generations capture detached palette/styles/scope/Keep-Replace,
protected features, brief/correction/mode/counts, saved analysis and provider/
model/quality/concept direction. Versions already retain the exact final prompt
and source/supporting IDs. Snapshot changes cannot mutate earlier history;
only allow-listed design fields enter the recipe, with no connection credentials.

History offers Saved settings, Use these settings and Refine this design. Reuse
keeps the original source; refine uses the selected result and precision mode.
It preserves the approved baseline and restores model/quality only where supported
by the connected provider. Legacy/manual/editor versions may lack recipes and are
labelled honestly. Missing/deleted source references need recovery first; stale
analysis can still need review. Exact paid request replay is not implemented.

### 3. Precision remains guidance rather than enforcement

The 20 November follow-up recommends a local paint editor as the next functional
batch: save a reusable wall selection, then try colours without generating another
room image. Wallpaper would reuse that foundation with perspective/repeat controls.
This has been reviewed and added to the backlog, not implemented in 1.0.13.
Current palettes do not recolour photo pixels, and text analysis is not a mask.

The OpenAI edit request contains images and a prompt, with no mask.
Crop/markup creates a flattened reference image; there is no stored region model,
mask transport, compositor or detection of changes outside the selection.
A prompt saying "keep the window" is useful but not a pixel lock. This is the
largest gap against the brief's controlled-editing differentiation.

### 4. Analysis should separate photo facts from design preferences

In the normal workspace, analysis matching includes the complete template
context. A new palette/style/brief can invalidate the reviewed AI prompt and
require reanalysis, or deselecting it to use the offline template. Live design
already reuses observations when tuning palette/style. Unify these behaviours:
cache visible facts by input images and regenerate the brief from current choices.
Never relabel unanalysed photos as understood or reuse incompatible photo facts.

### 5. Reliability and speed need measured larger-project tests

`main.dart` now paints startup before opening the same existing Hive boxes, with
a visible loading state and non-destructive Retry on failure. Photo bytes still
live in an eager box; a growing library can affect startup/memory. Native image preparation
and crypto use background work, but browser decode/resize/export work can still
block its UI thread. Workspace version thumbnails are eager and inactive control
tabs stay mounted. Add timing/memory measurements, journaled recovery
and bounded image loading before a storage migration. No general speed promise
has been verified on large real projects.

### 6. Camera ambitions need a separate milestone

The automatic capture/analyse/generate/overlay flow exists. It is not a spatial
scan or tracked AR. Moving the camera does not render the approved room from a
new angle. Future work includes tracking/alignment, occlusion, persistent room
geometry, bounded paid sessions, and saving an overlay composite. Keep the
working same-view path and label its limits honestly.

## Design assessment

The chosen Focus Canvas visual direction is coherent: warm panels, large images,
consistent toolbars, compact room tiles and a useful desktop split. Keep it.
The most useful next improvements are in information priority:

- Returning users: Continue and saved projects before the large discovery area.
- Room: one active-image/baseline header; avoid repeating strip/dropdown/status.
- Style: selected styles and palette in a compact summary; full choices in a picker.
- Refine: visibly distinguish creating alternatives from correcting a selected image.
- Ideas: saved versions and selection first; manual copy/import as secondary tools.
- Settings: project-specific files belong to the selected project; avoid a growing
  list of repeated export panels. Help must work by tapping on phones.

The first-view Refine controls already fit well. Do not reduce every font again
to solve hierarchy problems. Check contrast, touch sizes, keyboard, landscape,
screen readers and enlarged text on the actual phone. Full evidence and proposals:
[product/design audit](docs/PRODUCT_NOTES.md#whole-project-design-audit--19-november-2026).

## Storage and release boundaries

- Existing Hive boxes/IDs, originals, recovered projects, browser profiles and AI
  settings were preserved. No actual customer records were opened by the fixture audit.
- Plain `.renovision.json` files include private photos/metadata. Protected
  `.renovision` copies encrypt the export using AES-256-GCM and password derivation;
  they do not encrypt existing local databases. Both extensions are ignored by Git.
- Android protects the API key with Keystore and excludes its secret preference
  from OS backup. Other app data is not explicitly excluded by those backup rules;
  review OS-managed backup/transfer disclosure. No app-managed cloud sync exists.
- The personal-key test route works without a laptop. A future shared-credit
  commercial product needs its own backend, usage enforcement and billing design.
- Production application ID/name/icon/signing, privacy policy, account/credit
  handling, store submission and iOS verification are unfinished. These do not
  block the current private prototype; it is not ready for public release.

## Verification and next action

The audit checked source, tests/logs, platform files, the brief and conversation.
Eleven fixture screens were rendered at 390×844 phone / 1440×900 desktop using
real view metrics and fonts; outputs are private under `output/design-audit/`.
They are layout evidence, not an interactive Chrome/S21 acceptance run.
After the audit, all 296 tests and static analysis were rerun successfully for
the requested 1.0.13 update; final web compilation passed in 102.4 seconds.
These are automated source/build checks, not a physical-device acceptance run.

See [the ordered task list](CODEX_NEXT_STEPS.md) and
[testing/storage instructions](docs/TESTING_GUIDE.md). Validate the requested
1.0.13 update on the S21 before claiming device acceptance.
Build further phone packages only when requested.
