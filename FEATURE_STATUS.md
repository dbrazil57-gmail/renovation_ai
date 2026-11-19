# Renovision feature status

Updated 19 November 2026. Product requirements: RENOVISION_PROJECT_BRIEF.md.
"Implemented" means present in code, not necessarily verified on a real device.

Room chooser polish (source after APK 1.0.11): compact icons/text/inputs and
narrower margins; adaptive one-to-three-column tiles keep long labels readable.
Main room types use bundled example-photo backgrounds; other spaces use small
icons. Illustrations never change room preferences or become project images.
All 42 space types/search/categories remain. No new APK or local-data changes.
All 230 tests pass and static analysis is clean, including narrow-phone long-label
checks at normal and enlarged text sizes. Existing APK checksum is unchanged.

Version-history caption correction (source after APK 1.0.11): Ideas > Version
history now shows the title and version details below a wider preview. Actions
wrap separately, leaving the caption the card width. Full details are available
on hover/long-press; image zoom, selection, favourites and recoverable deletion
are retained. Small version-strip labels now use two lines and scale their
height with system text size. No data/settings changes or new APK built.
All 228 tests pass and static analysis is clean; APK 1.0.11 checksum unchanged.

Camera handoff correction (source after APK 1.0.11): **Design in live camera**
now keeps the main camera-design journey in Live design, with analysis/options
and results in the viewer. Compare reuses its saved reference without capturing
another photo; Live view captures after consent. The old workspace editor is a
separate toolbar action. Saved results request an immediate overlay, or wait for
camera readiness, with a persistent viewer toggle. Keyboard insets no longer
reset it; genuinely resizing/backgrounding still resets alignment. **Continue
to refine** explicitly opens precision editing of the selected saved version,
preserving the whole-room brief. No new APK built for this correction.
All 226 tests pass, including 16 Live design tests; static analysis clean and
web release compilation passed. Existing APK 1.0.11 checksum is unchanged.

Latest requested test APK: **1.0.11+12**, source `5a37fa0234`, at
`output/mobile-test/renovision-test-1.0.11.apk` (also `renovision-test.apk`).
Includes same-viewer Live design and all Projects/Library/camera-entry refinements.
All 220 tests pass; analysis clean; Android release build passed in 102.3 seconds.
Package/version/signature verified against 1.0.10 for an in-place update. Camera
hardware optional, no microphone/storage write permission, only app sample assets
bundled. Existing APKs retained and 1.0.10 hash unchanged. No local work/settings
cleared or real AI calls made. Physical S21 acceptance remains pending.
SHA256: `D698CE3EC2CDB9E340E063BE40A3279F63C35EE1268A379F66C38EC37EBC11AE`.

Projects/Library polish (included in 1.0.11): Saved projects
uses a compact heading with hover/tap information instead of inline paragraphs;
Create project/Open project file actions are grouped. Restore-copy remains in
Settings, and saved project rows open directly. File import stays available and
is explicitly distinguished from the local list. Favourite previews have readable
captions beneath their images, full title/project/room tooltips, full-screen image
viewing and separate edit/delete controls. Phone layout is one column, wide
layout two; rows load lazily. Camera entry says Continue to camera; gallery says
Continue to photos; an undecided source says Continue before source selection.
No data/settings changes. Packaged in APK 1.0.11. 220 tests pass, static analysis clean;
file-open preservation, capture cancellation, large text, image/edit navigation
and lazy image loading covered. Normal Chrome/S21 visual acceptance remains.
Web release build passed; existing APK 1.0.10 checksum verified unchanged.

Live design (included in APK 1.0.11, 19 November): project entry works
without previously importing a room photo. Start and analyse confirms one automatic
reference capture + paid analysis. The camera stays open; Room/style, Palette and
Brief panels sit below it. Generate/Update preview separately confirms exactly one
image request, even for a room normally configured for three concepts. Palette
changes reuse that reference's observations, without another analysis. Received
previews autosave as versions; Save and continue opens the selected result in the
existing workspace. Original photos/approval/model and quality settings persist.
Reference/analysis/image save retries reuse received data without duplicate calls.
Backgrounding cancels preparation and resets overlays; pending paid results remain
guarded. Narrow/large-text progress overflow fixed. All 215 tests pass (ten new
mocked Live design tests), analysis clean. No real AI calls; now packaged in 1.0.11.
Web release compilation also passed; APK 1.0.10 checksum verified unchanged.
Normal Chrome/S21 acceptance remains. Instant generation, partial-image streaming,
spatial room scanning and movement tracking are not implemented; this stays a
same-view image overlay. Bounded paid live sessions remain a future option.

Previous test APK: **1.0.10+11**, source `a18caebdc6`, at
`output/mobile-test/renovision-test-1.0.10.apk` and `renovision-test.apk`.
Includes embedded camera capture/design/compare/manual overlay and the home-cover
picker. All 205 tests pass, analysis clean; Android release build passed in
142.0 seconds. Package/version and signature verified against 1.0.9 for an
in-place update. Camera hardware optional; microphone/storage write permissions
absent. Bundled image assets match the fictional app samples only. Prior APKs
1.0.8/1.0.9 retained; no user data or local AI settings cleared. S21 camera/rotation,
overlay alignment, restart durability and real provider quality remain user tests.
SHA256: `42B3918E587901CD949F9A5873A2305A1E9BC0F611A0CC2D6083BD19E8E331F4`.

Home cover correction (19 November source, after APK 1.0.9): the opening hero
previously displayed the most recently opened room's primary photo. It now uses
the bundled fictional coastal living-room sample by default. Wallpaper control
on the banner and Settings > Home cover offer six app examples and saved project
photos/designs, plus Use default. The explicit choice persists on this device
and no longer follows room navigation. Missing/deleted choices fall back to an
app sample. No real room photo is added to bundled assets, deleted or overwritten;
project/AI settings and resume behaviour are preserved. Packaged in APK 1.0.10.
Validation: 205 tests pass, including six cover/default/persistence/failure/layout
checks, with clean static analysis. Banner content can grow for large text instead
of clipping its controls on narrow phones.
Web release build passed. Normal Chrome and S21 visual acceptance remain manual.

19 November camera source update (not packaged in APK 1.0.9): embedded live
preview, still capture/retake, immutable room-photo saving, capture-to-design
navigation, frozen before/after slider and an opt-in manual live overlay.
Only in-app designs with a recorded source for the chosen saved view are offered.
Align the original ghost image, then show the design and adjust opacity; moving
breaks alignment. Backgrounding/rotation resets the overlay. Permission errors
offer retry; camera resources close on background/exit. Save failures retain the
capture for local retry or explicit discard. Six-photo limits remain. Project
exports include captures/designs/provenance; connection credentials stay separate.
No continuous frame upload, automatic AI spending or tracked AR. Packaged in 1.0.10.
Camera lifecycle/storage/widget tests use synthetic photos and fake devices;
physical S21 camera/rotation, normal Chrome permissions and provider quality
remain manual acceptance checks. See the camera test checklist.
Validation: **199 tests pass** (14 camera tests), static analysis clean, web
release compilation passed. Isolated Chrome widget tests stalled during Flutter
bootstrap before any test ran, with browser runtime errors; cancelled that run.
This is not a passing browser/camera acceptance result. Existing 1.0.9 APK hash
is unchanged.
Android's release manifest task also passed: camera permission present, camera
hardware optional, unused microphone/external-storage write permissions removed. This
checks native permission merging without packaging an APK or testing hardware.

Folder cleanup, 19 November: removed 7.38 GiB of generated builds/caches, stale
SDK download, temporary preview profiles/tooling and old diagnostic logs.
31 older browser-preview profiles archived rather than deleted. App source,
assets, tests, native platform projects, local settings, recovered projects,
original document/source backups, important images and APKs 1.0.8/1.0.9 retained.
125 protected file hashes verified unchanged; current Chrome profile preserved.
No app-code changes, new APK, AI calls or repeat build/test run during cleanup.
APK 1.0.9 retains its validated 185-test result; runtime phone acceptance remains
the user's next test. Cache deletion means the next build regenerates its outputs.

Previous APK: **1.0.9+10**, source `d67b148d3f`. All 185 tests passed;
static analysis clean. Universal APK built in 104.2 seconds at
`output/mobile-test/renovision-test-1.0.9.apk` (also `renovision-test.apk`).
Package/version verified and signing certificate matches 1.0.8 for an in-place
update. Includes Focus Canvas, compact controls, Autosave menu, camera/gallery,
post-analysis counts and distinct-concept briefs. Further crop/markup compaction,
expandable bottom-sheet gestures remain planned. Camera source work above is
newer than this APK.
No user data cleared and no paid AI calls made by the agent. Real S21 acceptance
and actual AI image diversity remain user tests.

Selected B / Focus Canvas (included in APK 1.0.9): camera-first Projects
home with Take photo / Choose photos, saved-room Continue and four photographic
room-type shortcuts (all 42 choices remain in the picker). Warm charcoal app bar
and canvas, olive actions and light control panels replace the previous teal UI.
The workspace keeps its image/tools/version strip visible and shows one retained
Room / Style / Refine / Ideas panel at a time; desktop uses an image/control split.
Refine puts the instruction and compact paid-count/generation controls first;
edit mode, protections and prompt preview remain available below. Selected saved
designs open on Refine; the explicit Refine selected design tool enters precision
mode without overwriting the whole-room brief. Analysis has a continuation shortcut.
Drafts, pending AI/save state, original photos, approvals and project files retain
their existing storage and request paths. Image loading now has visible feedback.
APK 1.0.8 does not include this layout or the later Autosave/distinct-design
changes; update to 1.0.9. Native widget renders inspected with fictional
photos; physical S21 and normal Chrome acceptance remain user checks.
Validation: 185 automated tests cover current features, compact/narrow/large-text
layouts, panel/draft retention and phone/desktop resize state. Static analysis
is clean. The isolated web demo compiled; native widget review captures were
inspected. Headless browser captures were blank, so browser visual acceptance
has not been claimed. No paid provider requests or real photo changes made.

Distinct multi-design briefs (included in APK 1.0.9): alternatives now use
Clean & architectural, Warm & tactile and Bold & sculptural material/form/lighting
directions. Each multi-image prompt includes the planned alternatives and asks
for visibly different major renovation decisions within authorised scope; plants,
ornaments or exposure changes are explicitly insufficient. Keep choices, style,
palette and layout restrictions retain priority. Single results and precision
retain their existing request flow; no extra API calls, automatic retries or
charges are introduced. Visual diversity is requested, not verified automatically;
only byte-identical output detection exists. A real provider test is still needed.
APK 1.0.8 retains the earlier concept directions; 1.0.9 includes this correction.
Static analysis clean and all 180 automated tests pass, including distinct
planned briefs, scope protections, sequential generation and partial saves.

Autosave menu shortcut (included in APK 1.0.9): the room workspace and
guided setup expose a checked More tools > Autosave item on desktop and phone.
The workspace's large Autosave switch/card is replaced by a compact save-status
line and help icon. Full save controls remain in Room settings. Existing global
preference storage, debounce and save-on-exit behaviour are retained. Failed
preference writes keep the previous setting and show a message.
Static analysis clean; all 179 tests pass, including menu persistence/failure,
phone/desktop placement and existing save/exit flows.

Previous APK: **1.0.8+9**, source `3e62d1b14e`, includes the post-analysis
redesign choices. Static analysis clean; all 176 tests pass. Universal APK built
in 72.3 seconds at `output/mobile-test/renovision-test-1.0.8.apk` (also the latest
alias). Package/version checked; signing certificate matches 1.0.7 for an update
without uninstalling. No real-camera or paid AI calls were made by the agent.
HOMLY/Forma redesign examples are separate previews, not part of this APK.

Post-analysis redesign choices (included in APK 1.0.8): a current
whole-room analysis now offers 1 design / 2 ideas / 3 ideas. The choice uses the
existing saved concept count; it does not generate images or invalidate the
analysis. Guided setup's next action is Choose redesign options; multi-image
generation labels show the requested count. Existing per-request confirmation,
sequential generation, gallery selection and saved version history are reused.
Stale analysis and precise correction do not offer this whole-room chooser.
APK 1.0.7 does not contain these changes; update to 1.0.8 to test them.
Static analysis is clean and all 176 tests pass, including count persistence,
no paid generation on selection, analysis freshness and reviewed-prompt sending.

Previous mobile test build: version 1.0.7+8, source `fa1e8d0319`. Static analysis
clean and all 175 tests passed. Universal APK built in 75.3 seconds at
`output/mobile-test/renovision-test-1.0.7.apk` (also `renovision-test.apk`).
Package/version verified; certificate matches 1.0.6 for an in-place update.
Includes the phone camera/gallery changes below. HOMLY/Forma layout, embedded
camera preview and live renovation overlay are not implemented in this build.
No physical-device acceptance or real provider requests were performed here.

Phone photo entry update (18 November, source only): project screens show Take
photo and Choose photos; room setup and the workspace's Room photos card now
support taking additional camera photos as well as choosing several existing
device photos. Sample-design starts offer a camera/gallery source choice.
Camera capture reuses the native still-camera picker, validates size and copies
photo bytes into existing room storage. Cancellation/failure preserves originals.
These are local photo inputs, not automatic AI uploads or a live camera overlay.
Packaged in requested 1.0.7 APK; physical S21 acceptance and picker process-kill recovery
remain to be checked. All 175 automated tests passed, including camera/gallery
routing, cancellation/failure and persistence on reopening the local store.

Camera Renovation View: first prototype implemented in 19 November source as
described above. Saved capture/design comparison and manual same-view blending
are available; moving-camera tracking and instantaneous whole-room transformation
remain research goals. This supersedes the earlier still-camera-only source path.

Contextual toolbars (1.0.6+7 / `3ffefb376a`): shared icons/order across project,
room setup/workspace, editors, viewing/comparison and relevant root/settings
screens. Irrelevant actions are omitted; temporary unavailable actions disable.
More tools holds extra actions in the same order on narrow screens. Existing
body actions remain; Save and Settings use the current storage/draft flows.
172 tests pass and static analysis is clean. Phone overflow, disabled actions,
toolbar saving, retained setup edits, editor Undo and comparison reset are covered;
physical S21 visual verification is still a manual check.
Universal 1.0.6 APK built and signature verified against 1.0.5; version code 7
supports installation over the current app with the same package identity.

Compact UI/help (1.0.5+6 / `7944f6f4ea`): optional explanations moved from repeated
paragraphs into info icons on project saving, palettes, styles and workspace/
generation controls. Desktop hover shows details; tap/keyboard opens a scrollable
panel. Project saving retains buttons and compact success feedback; failures,
action-required status, progress and AI paid-request consent remain visible.
First-step room-photo guidance remains visible. All 166 tests pass, including
hover/phone/keyboard accessibility and no accidental saves or switch changes.
Physical S21 visual verification remains pending.
Universal 1.0.5 APK built and signature verified against 1.0.4; same package and
higher version code 6 support installation over the current app without uninstalling.

Recoverable design deletion (1.0.4+5 / `55b1bf7204`): generated-gallery, Explore
and favourite delete buttons plus Delete design in version-history menus.
Confirmation, Undo and Deleted designs/Restore preserve originals, child/analysis
references and backups. Approved baselines require choosing another baseline
before deleting; deletion is blocked during AI work. Deleted records and bytes
remain recoverable in local storage and portable project files; permanent purge
is not implemented. Current selection safely falls back on deletion. All 160
tests passed; static analysis clean. Physical S21 verification remains a user test.
Universal 1.0.4 APK built; signature verified against 1.0.3, unchanged package
identity and higher version code 5 for installation over the existing app.

Multiple concepts (1.0.3+4 / `a198a37712`): style chips blend influences in one
design; this is now explained alongside concrete visual style cues. Multiple
design ideas adds 2/3 sequential concepts and optional separate-style comparison,
with explicit paid-request count, one frozen starting image and individual saved
versions/prompts. Gallery images open full screen and Use this design selects
the next working image without baseline approval. Earlier results survive
partial failures; Stop after this image blocks later requests, and save retries
are local only. Exact-file duplicates warn without paid replacements. Batch
settings autosave/export with rooms. 152 tests passed; static analysis clean.
Actual model adherence and visual novelty remain user checks, not guarantees.
The universal 1.0.3 APK is built; signature verified against 1.0.2 with the same
package identity and higher version code 4 for in-place installation.

Crop/markup update (1.0.2+3, source `e7b7ed2e66`): crop corners and edges can be
dragged, and the existing box can be moved. Markup supports pen/line/arrow/
rectangle/ellipse/text notes, multiple colours and widths, multiple objects,
selection/moving, note editing, recolouring, whole-object removal and undo/redo.
Full-resolution reference export leaves the original untouched and strips source
metadata. Marks/notes flatten on save; persistent editable layer history is not
implemented. All 143 tests pass; static analysis clean. Physical-phone acceptance
of these editor changes remains pending; no provider requests were needed.
The universal 1.0.2 APK is built; signature verified against 1.0.1, with unchanged
package identity and higher version code 3 for in-place installation.

Phone viewer update: version 1.0.1+2 / source `4d0ef665b2` adds full-screen
viewing from generated results, working images, Explore, saved version thumbnails
and favourites. Supports pinch zoom/pan, double-tap zoom/fit, zoom buttons and
reset. Full image bytes are used for detail viewing; portrait/landscape adapt
without modifying the source or changing approval/history. Android Auto rotate
must be enabled for physical rotation. Latest regression suite: 140 tests passed,
including gesture/rotation/data-preservation checks and a guided generation
result-viewing flow; static analysis clean. User installed the earlier APK on
their Samsung S21; the new physical-device viewer check is pending.
The version 1.0.1 universal APK is built and its signature/update compatibility
verified against 1.0.0. No new native screenshot check was possible because the
existing emulator did not respond to inspection; it was not wiped or reinstalled.

18 November direct API update: personal OpenAI keys now work without a PC relay.
Settings > AI connection and models > Internet API checks model access, then
analysis and generation send actual photos/prompts directly to api.openai.com
over HTTPS. Android saves the key encrypted using Android Keystore and excludes
its ciphertext from device backup/transfer. Keys are excluded from project files;
Chrome direct keys last only for the current session. Disconnect removes the key.
No automatic paid retries or redirect forwarding. Six new mocked tests cover
transport, metadata cleanup, privacy, restoration, failures and phone key entry;
135 total regression tests passed. Real API and physical-phone checks remain.
Build `9d222d5de2` built and installed over the emulator app without deleting data;
the saved project and new Internet API form are visible. Static analysis is clean.
Earlier relay-only statements below describe the previous development route.

User subsequently reported the direct API test worked. A signed, release-mode
universal APK is prepared at `output/mobile-test/renovision-test.apk` for private
phone installation (same source build). Signature verified; physical-device
acceptance remains pending. Existing app/emulator data were not changed for this
packaging step. Installation instructions are in the testing guide.

18 November progress/Android resume batch: 129 automated tests passed; final
static analysis is clean. New fixed
AI activity strips in workspace/setup show elapsed time and real client phases,
terminal errors and local-save failures; no percentage is fabricated. Retry-saving
does not resend a generation request. Current source build: `a793f4c30b`.

Android x86-64 debug build now installed and launched on the existing emulator
after a non-wiping cold boot. Screenshots/accessibility dumps verified initial
navigation and system file-picker presentation; a saved room workspace was then
observed. This supersedes earlier "not installed" notes, but is not complete
Android acceptance. Camera, real AI, controlled import/save/restart and keyboard
checks remain. The emulator test project survived the reboot. Windows Chrome
projects and source files were not cleared. Provider relay must be restarted
privately after the reboot; no paid AI requests were made by these checks.

Current regroup: core design/generation/saving works in the Chrome preview,
including user-tested AI results. The new elapsed/stage display is implemented;
durable recovery of an in-flight AI job after app/process restart is still
missing. The proposed refinement panel and wide desktop workspace remain
unimplemented.

Earlier Android setup history (superseded by installation above): initial build failed on an incomplete NDK
download. The official required NDK has now been checksum-verified and installed,
with the incomplete installer preserved; the retry also installed SDK platforms
36 and 35 and CMake 3.22.1. The retry now successfully produced the x86-64 debug
APK in 320.3 seconds. Android acceptance remains incomplete. A private copy of the saved
project is in emulator Downloads; PC originals and browser data are unchanged.

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
| Crop | Draw, resize with corner/edge handles, move and reset the box; save a separate cropped reference |
| Sketch / markup | Multiple coloured pen strokes, lines, arrows, rectangles, ellipses and editable text notes; three widths, select/move/recolour/remove, undo/redo; flattened reference on save |
| Version history | Select versions, branch edits and track parent IDs |
| Approved baseline | Explicit approval retained when reopening a room |
| Favourites / pass | Buttons, swipe review and favourites Library |
| Review status | History labels distinguish passed, pending and favourite designs; review menu can return an idea to Explore |
| Before / after | Slider comparison against original; differing crops may not align |
| Room instructions | Save requested changes and protected-feature text |
| Explore / Precision modes | Different prompts; precision is not technically enforced |
| Manual AI handoff | Copy prompt and import external result |
| In-app OpenAI integration | Direct HTTPS with personal API key, or optional development relay; consent, new-version saving and failure handling. New transport tested with simulated responses; user real-key verification pending |
| AI setup location | Settings > AI connection and models > Internet API. Android Keystore-backed encrypted key storage; browser session memory only. Keys never enter project exports. Laptop relay remains optional |
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
- Image rotation and pixel-level erasing (whole-mark removal and line widths are implemented).
- Delete projects/rooms, permanently purge trashed designs, review filters and richer rejected-version management.
- Stronger protection against browser/process shutdown and persistent backup scheduling.
- Comprehensive startup/storage corruption, low-space and interrupted-import recovery.
- Physical-phone acceptance of the new encrypted API key storage and direct
  internet requests; a managed service/account strategy if distributing a shared-key product.
- Guaranteed encrypted-at-rest photo storage.

## Deferred beyond private Stage 1 testing

- Payments, credits/subscriptions, purchase verification and production billing.
- Public hosting, customer authentication and public API service.
- Play Store release, signing/distribution and launch compliance work.
- Consistent moving-camera whole-room AR/video transformation. Saved-view
  comparison and manual overlays now have a source prototype; tracked rendering
  is deferred.
- Tradie/client/job features, branded exports and team/enterprise roles.
- iOS build/device verification and release.

No API key is needed for local photo, version, download or backup work. See
docs/TESTING_GUIDE.md#ai-test-setup when ready to test provider calls, and CODEX_NEXT_STEPS.md for
the next acceptance checks.
