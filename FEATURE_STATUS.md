# Renovision feature status

Updated 16 November 2026. Product requirements: RENOVISION_PROJECT_BRIEF.md.
"Implemented" means present in code, not necessarily verified on a real device.

Manual-copy follow-up: removed the cosmetic ChatGPT/Gemini selector; both had
copied the same text. One Copy AI prompt action now explains that external apps
need the photos attached separately. It does not select an in-app provider.
OpenAI remains the sole implemented generation integration. Sixteen affected
scope/palette tests pass and static analysis is clean. Preview: `3e9db65669`.

Restore-name follow-up: repeated restores now use a single `(restored)` suffix,
including when an older backup name already contains several. Existing project
names/data are not changed automatically. Eight backup/restore tests pass;
Flutter analysis is clean. Current preview build: `6d3bbc05cd`.

Android follow-up: 125 VM/widget tests passed, final static analysis clean, and
eight file tests passed including chooser cancellation. Preview build `01649b08ae`
uses the same local URL. These are not Android device acceptance results.

Platform requirement: Android phones are the product target; Chrome is a temporary
development preview. The shared Flutter UI/storage/workflows use conditional file
adapters. Android chooser-only exports are no longer treated as reusable file
handles, preventing background autosave from reopening a chooser. App-local
autosave remains active. Persistent Android document updates and camera/lifecycle
acceptance tests remain outstanding. Release INTERNET permission is now present;
production HTTPS AI transport is still unimplemented. Flutter doctor finds SDK
36.0.0 but missing command-line tools and unknown licence status; no Android
build/device success is claimed.

Latest guided-room/project-file batch: all 124 VM/widget tests pass; Flutter
analysis is clean. The final served build is `0adf905de0`. New rooms
open a four-step setup (photos, direction, analysis/review, final options), with
saved progress, Finish later and a workspace shortcut to reopen setup. Existing
rooms still open their workspace. Generation stays explicit; disconnected users
can finish setup without analysis. Photos and preferences use the same prompt
builder in setup and the workspace.

Projects now has Open project; project pages and room save controls offer Save
project/Save project as. Portable .renovision.json files include all rooms,
originals, versions, prompts, analysis, choices and setup progress. Open adds a
local project copy, preserving existing records. Chrome file handles let Save
update the chosen file and Autosave write later changes while linked. Writes
are serialised, failures retain local work, and only one project copy may stay
linked to the same file. Reopen the file after restarting to reconnect its disk
destination. Other file providers may download copies rather than update them.

The local relay address, pairing code and selected model/quality are remembered
in this browser's private settings, never in project exports. Startup reconnects
using only the local health endpoint. A stopped/restarted relay may require its
new code; provider keys remain in the relay. Always use http://localhost:7357.
The user confirmed automatic project reload in their normal Chrome profile.

Web release build passed; final static analysis is tracked with the task notes.
Direct isolated Chrome checks verified desktop/phone gallery, Settings and Open
project. A desktop browser check created a disposable project, imported a fictional
photo, opened guided setup and saved/parsed a complete project through a real
browser-sandbox file handle. It did not exercise the Windows picker. The separate Chrome widget
test harness stalled at startup; its runs are not counted as passed. VM/widget
tests use fake file providers and AI responses. Real Windows picker/restart and
live AI image adherence still need a user test; no paid calls were made here.

Earlier simplified-flow batch: all 113 tests pass and Flutter analysis is clean.
Whole-room design now supplies a coordinated design direction without mandatory
checkboxes. Detailed choices are optional Advanced overrides. Precise correction
uses a separately saved instruction field, without reapplying whole-room text,
style, palette or replacement choices; Keep protections still apply. Both briefs
and saved overrides survive backup/restore. These tests use simulated AI; live
visual adherence still needs testing. Earlier mode-retention notes below describe
the prior implementation and are superseded by this behaviour.

16 November startup/Settings batch: all 111 VM/widget tests pass, including
saved-room startup discovery and draft-safe Settings navigation. Analysis is
clean and the updated web build passes. Large-photo performance still needs user testing.
Crop/sketch now open before preview decoding, reuse an engine-decoded 1600px
preview, and decode original resolution only on saving. Loading/saving states are
visible. Real large-photo timings remain unmeasured; full-resolution saving still
uses synchronous Dart processing and can pause Chrome during encoding.
Isolated Chrome screenshots show the gallery at desktop and phone widths;
this is a rendering check, not real-user persistence, Android or live AI validation.
Existing user data was not opened, cleared or migrated during these checks.

16 November status retest: all 111 automated tests passed again and Flutter
analysis reported no issues. Isolated Chrome checks verified gallery controls
at 1440px and 390px widths and navigation to Settings at both widths with AI connection
and Restore controls. These checks do not exercise a paid provider or establish
restart durability in the user's existing browser profile.

Separate saving investigation: four cached browser-origin project copies were
recovered and validated; original cache files were not modified. See
docs/TESTING_GUIDE.md#recovered-projects. Restart durability in the user's normal Chrome profile
still needs the stable-address manual check.

## Implemented

Button-feedback correction: copy/generation validation now opens a dialog;
the conflicting Precise + All request is also blocked before paid analysis.
Sixteen targeted scope/generation tests pass and Flutter analysis is clean.

Precision follow-up: 29 focused workflow/scope/analysis/prompt tests pass,
including an explicit precision edit from an approved design with source bytes,
parent and requested scope checked. Mode switching preserves previous choices;
the UI now explains clearing unrelated requests for a narrow correction. Visual
preservation remains unverified against a live provider and is not mask-enforced.

| Feature | Status / practical limit |
| --- | --- |
| Explore, Projects, Library, Settings | Working app navigation |
| Projects and rooms | Create named projects and rooms |
| Saved-work startup | Existing projects open on Projects rather than an empty Explore feed. A photo-based Continue card finds the last opened room (or a room from older records); it opens the approved design/primary photo. Autosave preference remains in the existing local store |
| Visual room creation | 42 home/utility/outdoor space choices with search, seven category groups, editable names and stable IDs. Includes specific bedrooms, ensuite/powder room, pantry, wardrobe, entry/stairs, garage/workshop and outdoor areas; original IDs remain readable |
| Sample inspiration | Six bundled AI-created fictional examples across kitchen, bathroom, living, bedroom and office; full room/style filters and a separate full-catalogue chooser. Use this style applies preferences to a new room using the user's photos; no sample is imported or generation triggered |
| Rename projects/rooms | Pencil control in each project/room header; names update without changing IDs, photos or history |
| Photo import | Gallery/file picker; originals saved separately |
| Multiple room photos | Up to six views per room, bulk upload at creation or later, and a persistent primary-view choice |
| Combined AI context | Working image first, other room angles as optional supporting inputs; all input views previewed before consent and tracked in version metadata |
| Colour palettes | 12 coordinated presets with named swatches, hex references and suggested surfaces; choose in the inspiration direction chooser, after uploading photos or in the workspace |
| Visible palette controls | Palette panel appears above room photos; choose directly from the swatch strip or open the full chooser |
| Saved colour direction | Palette preference persists with the room, survives backup/restore and enters copied / in-app AI prompts; previous versions retain the palette text used in their saved prompt |
| Design style choices | 19 styles including one Modern / Contemporary choice, plus Other text; legacy selections remain readable |
| Renovation scope checklist | Shared flooring/cabinetry/surface/lighting/removal choices follow room type; optional floor finish and other removal instructions; autosaved and backed up |
| Optional tidy/staging | Explicit checkbox requests removal of freestanding bins, washing-up and incidental clutter; retains protected items, functional fittings, architecture and outside view |
| Whole-room versus precise mode | Clearer labels; an All/everything request in precise mode is blocked for copying/generation until the user switches mode or provides a specific correction. Whole-room All becomes a coordinated brief |
| Room-specific Keep / Replace | Editable room type with legacy name-based suggestion; subtypes reuse existing profiles, with nursery/pantry/storage/garage/outdoor items added. Powder rooms omit bath/shower; dining and media omit unrelated furniture. Hidden choices remain saved and excluded from prompts |
| Scope-aware prepared prompts | Distinguishes a coordinated renovation from a precision correction, handles "nothing to retain", respects layout/style/palette priorities and asks for missing photos |
| Prompt preview | Shows the selected AI prompt plus current requirements, or clearly labelled local text |
| Room photo analysis | Connected vision model describes visible features and uncertainties and drafts a prompt; tested with simulated provider responses, live quality unverified |
| Editable AI prompt | Review, edit, autosave and explicitly select the prompt for generation; stale-photo/preferences checks block outdated use; provenance and input IDs retained in backups |
| Analysis included in design brief | With the reviewed AI prompt selected, copied/generated text also includes saved photo observations, labelled as fallible context. Current user requirements and working photo take priority; stale analysis is blocked. Follow-up: 13 focused tests, analysis and web build pass; live quality unverified |
| Draft autosave | Local saves for instructions, protections, styles, scope/details and mode; visible saving/saved/failure state, manual retry and pending-save handling on normal back navigation |
| Local persistence | Hive metadata and image boxes; isolated file-reopen tests pass |
| Visible save controls | Design page keeps Autosave and save status. Its Settings gear holds Save now, Save and close and Save as; normal room exit still saves pending drafts. Global Settings exposes project backups and Restore |
| Save as | In room Settings: named independent project copy, current-image PNG and full project backup; supporting Chrome uses a file-location chooser, otherwise downloads/native flow. Settings project backups flush an active draft first; real chooser interaction needs testing |
| Browser exit protection | Pending-draft warning on refresh/close plus best-effort flush; browser shutdown cannot guarantee completion |
| Stable Chrome testing | Fixed localhost:7357 web-server launcher; normal Chrome profile; Settings build/origin/counts and explicit write/read diagnostic; recovered older test backups available |
| Immutable originals | Edit/generation flows create separate images and versions |
| Image viewing | Workspace zoom/pan |
| Crop | Rectangular crop saved as a new reference |
| Sketch / markup | Draw on a copy; reset and undo strokes |
| Version history | Select versions, branch edits and track parent IDs |
| Approved baseline | Explicit approval retained when reopening a room |
| Favourites / pass | Buttons, swipe review and favourites Library |
| Review status | History labels distinguish passed, pending and favourite designs; review menu can return an idea to Explore |
| Before / after | Slider comparison against original; differing crops may not align |
| Room instructions | Save requested changes and protected-feature text |
| Explore / Precision modes | Different prompts; precision is not technically enforced |
| Manual AI handoff | Copy prompt and import external result |
| In-app OpenAI integration | Local relay, private key entry, consent, new-version saving and failure handling; tested with simulated responses only |
| AI setup location | Settings > AI connection and models. Provider keys stay in the PC relay. The browser remembers its local relay code/address and model/quality separately from project files; startup checks the running relay |
| In-app image-model testing | Connected relay advertises its configured model plus GPT Image 2.5 and 2.6 Sunburst / Flare, with low/medium/high quality; selection is local and confirmation freezes settings. Default is still 2.5 Sunburst/low. Actual account access, quality and costs remain unverified |
| Pending image protection | Image card stays alive while scrolling/collapsing; normal Back and Save and close wait while a request or received unsaved result is pending. Browser shutdown remains best-effort |
| AI edit metadata | Source image ID, parent, prompt, provider/model and request ID |
| Image download | Metadata-free PNG copy of selected image; originals remain intact |
| Project backup | Versioned .renovision.json file with exact photo bytes, instructions, versions, approvals, favourites and AI edit metadata |
| Backup restore | Validates photo checksums/references; adds a new project with remapped IDs, without replacing existing projects |
| Clearer local workflow | Current-image badges, optional collapsed AI controls, backup and download controls |

Backups include original photo metadata and should be kept private. Prototype
limits: 64 MB total photo bytes / 100 MB backup file. Browser download requests
do not prove a file was kept: check the downloaded file and test restoring it.
File transfer targets Chrome and Android; native Windows desktop export is not
implemented. Android file choosers and camera capture need device testing.

Multi-view AI creates one design from the working viewpoint; it does not create a
measured 3D reconstruction, panoramic stitch or guaranteed consistent geometry.
AI request limits: seven input images maximum (a design + six room originals),
18 MB per image and 36 MB total before metadata removal/resizing. All views count
toward provider input usage. Live multi-view design quality remains unverified.
New backups use format version 2; the updated app also restores version 1 backups.

Palette choices: Warm neutrals, Charcoal & walnut, Sage & oak, Coastal blues,
Navy & stone, Earthy terracotta, Soft monochrome, White & oak, Forest & cream,
Soft blush & brass, Greige & black, Deep blue & copper, or No palette preference.
Palettes guide future designs, not existing-photo recolouring or exact paint-brand
matching. Protected features and precision edit boundaries take priority. Older
rooms/backups without this optional preference remain readable.

## Implemented but awaiting live/manual verification

- The user's saved test example in the existing Chrome profile/address.
- Real browser download, file chooser and restore behaviour.
- Chrome persistence after closing/reopening the actual user app session.
- Live OpenAI generation: user currently has a subscription/login, not an API key.
- Android build, emulator/device, photo permissions/camera, file save/restore,
  interrupted picker recovery and restart persistence.
- Automated Chrome tests previously stalled during Flutter bootstrap; passing
  VM/widget tests and a web build do not establish interactive browser behaviour.

## Not implemented yet

- Benchmark the new preview loading with large photos; make full-resolution
  save processing non-blocking on Chrome. Current encoding can still pause the UI.

- More sample images (six examples currently cover five of 42 space types),
  application of sample presets to an existing room and typed inspiration-image inputs.

- In-flight analysis cancellation and full historical analysis records (only the latest room analysis is retained).
- Multiple generated design options in one requested batch, with selection and
  refinement from the chosen option. See docs/PRODUCT_NOTES.md#ai-design-workflow.

- Brush/selectable edit masks with saved mask geometry.
- Structured locks for windows, doors, floor edges and other room features.
- Crop + masked edit + compositing into the unchanged full-room image.
- Outside-region change detection and visual warnings.
- Separate reference/result types and editable sketch/annotation history.
- Dedicated Paint/sketch reference attachment workflow (ordinary images can be imported).
- Rotation, eraser and brush controls.
- Delete projects/rooms and versions; review filters and richer rejected-version management.
- Stronger protection against browser/process shutdown and persistent backup scheduling.
- Comprehensive startup/storage corruption, low-space and interrupted-import recovery.
- Persistent Android AI connection settings / secure production backend.
- Guaranteed encrypted-at-rest photo storage.

## Deferred beyond private Stage 1 testing

- Payments, credits/subscriptions, purchase verification and production billing.
- Public hosting, customer authentication and public API service.
- Play Store release, signing/distribution and launch compliance work.
- Camera-aligned overlays and live AR/video transformation.
- Tradie/client/job features, branded exports and team/enterprise roles.
- iOS build/device verification and release.

No API key is needed for local photo, version, download or backup work. See
docs/TESTING_GUIDE.md#ai-test-setup when ready to test provider calls, and CODEX_NEXT_STEPS.md for
the next acceptance checks.
