# Renovision feature status

Audited 19 November 2026 (Australia/Sydney) against the project brief, the
conversation and actual source through `a948da0`. This replaces superseded
implementation diaries. The product brief is unchanged.

**Assessment: a working private Android-first beta, with important gaps in
precision, project-file reopening and reproducible design history.** Keep the
existing app and Focus Canvas interface; a rewrite is not justified.

## 20 November follow-up — source after APK 1.0.12

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

All **275 tests passed** and static analysis is clean. The final release web build
passed in 78.1 seconds; Android Kotlin compilation passed without packaging an APK.
Seventeen new tests cover Gemini transport, key isolation/switching, session-key
expiry, offline restore, safe errors and provider-specific consent. All responses
were synthetic; no paid provider call was made. The preceding Chrome test iframe
stalled before tests; browser
interaction acceptance remains. No new APK or app API call for this follow-up. The
installed 1.0.12 does not contain these changes. The user confirmed RenoVision;
Android/web/Flutter display labels are updated in source while the package ID and
storage stay unchanged. A second board of six different icons was generated with
built-in imagegen after the first set was rejected; launcher assets await selection.

Live naming correction: generic saved Live names and new automatic room-picker
names display the actual selected type, e.g. **Bedroom (Live)** / **Kitchen (Live)**,
not the literal word Room. They follow a later type change. An optional
`automaticLiveName` flag preserves this behaviour through saves/restores without
rewriting stored names; explicit renaming clears it. Unknown types show
Unspecified (Live) until confirmed. Existing custom names/photos are preserved.

## Source versus installed app

| Item | Verified position |
| --- | --- |
| Latest existing APK | **1.0.12+13**, source stamp `3cb94c972c`; `output/mobile-test/renovision-test-1.0.12.apk`, also `renovision-test.apk` |
| APK contents | Focus Canvas, embedded camera, manual same-view overlay, Live design and all completed source follow-ups below |
| New in 1.0.12 | Camera-result handoff/automatic overlay fixes, version-history captions, smaller photo-backed room chooser, Live design from room selection, simpler Rooms page, typed live-room labels, compact typography, five app themes, storage details and protected backups |
| Last APK checks | **249 tests rerun and passed**, static analysis clean, Android release build passed in 139.1 seconds; source follow-up above has 258 passing tests |
| Earlier audit | Reviewed code and 11 rendered screens; documentation and private-export ignore correction only. One temporary fixture-rendering test passed. The subsequent requested APK build made no paid AI call or data migration |
| Real user evidence | User reports successful phone installation, direct AI analysis/generation, good generated designs, project auto-reload and useful comparison/camera overlay. This does not validate every newer source change |

APK SHA256:
`CD3A047F2D84C515B279F2686B506017AB1A46199A00038A23B410799A88CB99`.
Size: 76,231,742 bytes. Signature matches 1.0.11; its checksum and rollback
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
| AI analysis | Sends selected photos and preferences to a vision model; saves observations, questions, editable AI-written prompt and provenance | Latest analysis only; normal workspace can require reanalysis after preference changes |
| Prompt preparation | Offline deterministic fallback, AI-written prompt option, preview/copy, current requirements/protected features, correct working/supporting-image roles | Copying text does not attach photos or automatically return external results |
| In-app AI | OpenAI/Gemini direct HTTPS with separate personal keys and saved model choices; curated image recommendations; optional OpenAI laptop relay; confirmation, progress stages/elapsed time, storage-only result retry | Gemini live account/image quality acceptance pending; no Claude/Bedrock adapter, in-flight paid-job cancellation, actual billed-cost meter or automatic output critique |
| Multiple concepts | One/two/three sequential requests from a frozen source; distinct specified material/design directions; partial successes saved | Strong difference is requested, not measured. Only exact-byte duplicate detection, no semantic diversity scoring |
| Refinement/history | Select saved result, narrow correction field, branches/parents, exact prompt and source/supporting IDs, model/request ID, favourites/reject/approval | Full structured settings and the matching analysis are not frozen per version |
| Image viewing | Full-screen zoom/pan/pinch, device landscape, before/after slider, image export | Image rotation as a saved edit, share sheet and Save to Gallery are absent |
| Crop/annotation | Resizable/movable crop, pen/line/arrow/rectangle/ellipse/note, colours/widths, select/move/remove and undo/redo; saved as a new reference | No enforced mask, full-frame compositing or persisted editable annotation geometry |
| Design deletion | Recoverable deletion, undo/restore, protected baseline handling | No permanent purge or comprehensive photo/storage manager |
| Camera renovation | Embedded preview/capture, saved-view comparison, manually aligned opacity/slider overlay | A flat image for a matching viewpoint; no camera-pose/depth tracking |
| Live design | Consent → one automatic reference capture/analysis → Room/style/Palette/Brief → confirmed generation → saved preview over camera → Continue to refine | Model latency remains; no continuous room scan, instant video transformation, moving-view redesign or composite/video export |
| Autosave | Debounced drafts, compact status, menu shortcut, manual save, save on normal exit, pending-request guards | Process termination can interrupt pending writes; no journaled crash/corruption recovery |
| Project files | Portable project with all rooms/photos/designs/current room choices/history; Open, Save, Save as, Restore | Open currently imports a fresh local copy; browser linkage is session-only, Android does not retain an overwrite destination |
| Appearance/help | Focus Canvas B, pinned preview and Room/Style/Refine/Ideas controls, desktop split view, contextual toolbars, compact text, tap/hover help, stock/user-selectable home cover, five saved app themes | More hierarchy work and real-phone accessibility checks needed; themes are separate from renovation palettes |
| Storage/privacy | Actual local storage/origin details, diagnostics; optional password-protected portable backup; Android encrypted API-key storage | Local photo/metadata database is not encrypted by the app; OS backup policy needs an explicit decision |

## Corrections and incomplete requirements

### 1. Open project must resume predictably

`RestoreProjectButton` uses `RenovisionStore.restoreBackup` for Open as well as
Restore. Restore deliberately remaps IDs and adds a separate copy. Opening the
same file repeatedly therefore creates multiple local projects. Removing the
repeated `(restored)` suffix fixed the name, not this document-identity issue.
`ProjectDocuments` prevents two local copies writing to the same destination,
but does not reconnect the existing local project.

Chrome can update a selected file while its handle remains linked in the running
session. Android uses system Create/Open Document actions without persistent
URI linkage. Save is therefore not yet the same-document workflow of Word.
Local autosave still works independently. Preserve legacy files/IDs while adding
an explicit **Open/resume existing** versus **Restore a separate copy** decision.

### 2. Every saved design needs its own complete settings

`DesignVersion` stores the image, exact prompt, source/parent/supporting IDs,
provider/model and request ID. Room preferences and the latest analysis are
stored on the room. Selecting an old design does not restore its original
structured palette/styles/scope/Keep-Replace, analysis revision or image quality.
Quality may appear in its title but is not a dedicated version field. Add a
backward-compatible immutable generation snapshot and keep the final prompt.

### 3. Precision remains guidance rather than enforcement

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

`main.dart` opens both eager Hive boxes before `runApp`; photo bytes live in the
photo box. A growing library can affect startup/memory. Native image preparation
and crypto use background work, but browser decode/resize/export work can still
block its UI thread. Workspace version thumbnails are eager and inactive control
tabs stay mounted. Add timing/memory measurements, safe startup error handling
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
The suite/analyser were not repeated for documentation-only changes, but all 249
tests and static analysis were rerun successfully for the subsequent requested
1.0.12 Android build. The earlier web result remains separate evidence.

See [the ordered task list](CODEX_NEXT_STEPS.md) and
[testing/storage instructions](docs/TESTING_GUIDE.md). APK 1.0.12 now packages the
completed source changes; validate them on the S21 before claiming device acceptance.
Build further phone packages only when requested.
