# Renovision next steps

Updated 19 November 2026 (Australia/Sydney). Keep this as the single current work
list; update existing documents rather than creating one file per idea.

## Next-release Projects/Library refinements — source after APK 1.0.10

Implemented compact Saved projects with hover/tap information, grouped Create /
Open project file controls and directly openable local project rows. Removed the
duplicate inline guidance/restore block; restore-copy stays in Settings. The file
opener is retained because the local list cannot load portable project files.
Library captions now span beneath the preview, with full title/context on hover
or long-press, full-screen viewing and edit/delete actions below. Responsive one/
two-column rows load lazily. Camera/gallery room setup labels match the next
destination (generic Continue when the source is chosen afterwards).
220 tests pass, static analysis clean. No user-data changes or new APK. Include
these changes with Live design in the next explicitly requested Android build;
check Saved projects help/file opening, Library readability and camera/gallery
copy on normal Chrome and S21.
Web release build passed; existing APK 1.0.10 checksum verified unchanged.

## Live design in the viewer — source after APK 1.0.10

User clarification implemented as a separate Live design route from projects and
Camera renovation. No prior room photo/shutter step: Start and analyse consents
to one automatic reference capture + analysis. Room/style, Palette and Brief stay
under the viewer; Generate/Update preview confirms one image request and overlays
the returned result. Palette changes reuse observations rather than reanalysing.
Every result autosaves; Save and continue opens the existing workspace. The earlier
capture/compare mode stays available. Confirmation per request is the user's chosen
mode; bounded paid live sessions are a future option, with no automatic spend loop.

215 tests pass, static analysis clean and web release compilation passed.
Existing APK 1.0.10 checksum verified unchanged. Ten mocked tests cover consent,
automatic capture, reused analysis, single-request limits, save failures, backup/continuation,
originals/approval, backgrounding, large text and rotation during generation.
No real AI call, user-data change or new APK. Next: requested APK and normal
Chrome/S21 acceptance using the Live design checklist. Existing 1.0.10 APK lacks
this new route. Preparation progress is real elapsed preparation/request stages,
not room coverage. Generation still waits for the provider; no streaming partial
previews, 3D scanning, pose tracking or instant video transformation implemented.

## Current phone test: APK 1.0.10+11

Requested build completed: `output/mobile-test/renovision-test-1.0.10.apk`
(also `renovision-test.apk`), source `a18caebdc6`. Includes both the home cover
picker and embedded camera/manual overlay. All 205 tests pass, analysis clean;
Android release build took 142.0 seconds. Package/version/signature verified;
signature matches 1.0.9, so update without uninstalling. Old APKs preserved.
No local projects/settings cleared, private images bundled or paid AI calls made.

S21 next: verify app-sample opening cover, change/reset cover and restart. Open
a saved room -> camera tool -> Capture new view -> Design saved view -> normal
analyse/review/confirmed generation -> Back -> Compare. Then Live view -> Enable
manual overlay -> Align original -> Show design. Match the viewpoint and keep
still: there is no pose tracking or continuous AI video. Check rotation,
background/resume, permissions, saved captures/designs and unchanged AI connection.
Only build future APKs on explicit request.

Home cover correction (19 November, source after APK 1.0.9): opening banner now
defaults to the fictional bundled coastal-living sample. Change home cover on
the banner or in Settings selects an app example or saved project photo/design;
Use default restores the app sample. Choice is device-local and independent of
Continue/last-opened room; no room images, primary photos, approval or AI settings
are changed. Save failures keep the previous choice; unavailable images fall
back to the sample. Included with camera changes in the requested 1.0.10 APK.
Validation: all 205 tests pass and static analysis is clean. Six new cover tests
include saved-choice restart, unchanged room data, missing/deleted choices,
failed-save preservation and narrow-screen large-text behaviour.
Web release build passed; verify the new cover on normal Chrome/S21 when testing.

## Current camera batch — 19 November, source after APK 1.0.9

Implemented embedded preview/still capture, saved-view AI workflow, frozen
before/after slider and opt-in manual live overlay. Take photo now uses the
embedded camera; the room workspace's camera tool opens Camera renovation.
Capture new view -> Design saved view -> analyse/review/generate normally ->
Back -> compare or Live view -> Enable manual overlay -> Align original ->
Show design. Changing sliders/modes does not call AI. Captures reuse existing
room photos/exports; originals, approvals and device AI settings are preserved.
Failed saves retain the capture for retry; linked project files save on exit.
Resources close on background and exit; alignment resets on background/rotation.

Next: normal Chrome camera permission at the existing address/profile, and S21
preview/capture/rotation/background/save/restart acceptance using APK 1.0.10.
Use docs/TESTING_GUIDE.md's camera checklist. No paid AI calls made.
Real-time generation, tracked surfaces/pose, moving-camera
AR and saved composite exports are separate future work; this is a manually
aligned flat-image overlay. Never send continuous video or silently retry AI.
Validation: 199 VM/widget tests pass, clean static analysis and successful web
release compile. Isolated Chrome tests hit the existing Flutter bootstrap/runtime
failure before any test ran and were cancelled; normal-browser acceptance is
still required. APK 1.0.9 SHA256 verified unchanged.

## Current regroup: finish the core experience before adding features

Project folder cleanup completed 19 November: 7.38 GiB of generated build/cache,
old SDK download and transient preview/debug output removed. Archived 31 old
preview profiles under `.local_backups/browser-preview-history/`; retained the
`.dart_tool/chrome-device/` profile, recovered projects, private room-photo reviews,
source/document history, local settings and APKs 1.0.8/1.0.9. 125 protected-file
hashes verified unchanged; audit is `.local_backups/cleanup-2026-11-19.json`.
No source edits or new APK required. Flutter regenerates removed build outputs.
Keep the existing localhost address/profile when restarting Chrome testing.

Previous phone build: **1.0.9+10**, source `d67b148d3f`, at
`output/mobile-test/renovision-test-1.0.9.apk` and the existing latest alias.
All 185 tests pass and analysis is clean. Built in 104.2 seconds; package/version
checked and signing matches 1.0.8, supporting an update without uninstalling.
Includes the selected Focus Canvas layout, compact refinement controls, Autosave
menu shortcut, camera/gallery entry and stronger distinct-design briefs.

Phone acceptance now: update existing app, open saved project, check photos and
AI connection, try the four workspace tabs, compare/zoom and precise refinement,
then generate 2/3 whole-room options and check meaningful differences. Restart
and confirm settings/images/versions remain. Real requests require the normal
paid confirmation. The further crop/markup compaction below and live-camera AR
are not included. No user data or prior 1.0.8 APK cleared. Build future APKs only
on explicit request; this batch was requested by the user.

Next mobile UI priority (user feedback): one task's required inputs per phone
screen. B is the workspace direction; compact crop/markup next. It still stacks
all tools, colours, widths, guidance and duplicate body actions below the image.
Use a stable image canvas, a compact tool strip, contextual colour/width/shape/
note controls and reachable Save/Cancel; keep Undo/Redo in the shared toolbar.
Horizontal browsing for styles/palettes/versions; a short vertical active panel
and optional expansion with visible button. Avoid navigation swipes on the image
because they conflict with editing gestures. Preserve large-text/keyboard access,
non-destructive reference saving and active/pending-save protection. Compare
Lightroom/Snapseed editor patterns and Homestyler/Planner room workflows; dated
sources, screenshot/video references and scope limits are in PRODUCT_NOTES.
This research-only follow-up implements no new gestures and builds no APK.

User chose B / Focus Canvas; implemented in source after APK 1.0.8. Camera-first
home, saved-room Continue, photo room-type shortcuts, charcoal/olive/cream theme,
retained Room / Style / Refine / Ideas panels, fixed visible image/version strip
and wide desktop split now replace the long workspace page. Compact Refine keeps
the instruction and paid generation choice first; mode/protections/prompt details
are expandable. Analysis can continue directly to design options. The explicit
Refine selected design tool activates existing precision mode and preserves the
whole-room brief. Storage/schema, originals, secure key handling and paid request
confirmation/partial saves are reused. No account, shopping or contractor scope
was added from the concept artwork. No APK built in this layout batch.

Acceptance next: normal Chrome at the existing address/profile, then a requested
new APK on S21. Test camera/gallery, all four tabs, field/scroll retention,
analysis -> options, selected-design refinement, 2/3 concepts, comparison/zoom,
delete/restore, keyboard/rotation, save/restart and unchanged connection settings.
The demo uses separate boxes and fictional samples, not real projects/credentials.
Native widget screenshots are `output/design-review/focus-native-*.png`; they are
review captures, not evidence of physical Android acceptance. A headless browser
capture remained blank despite a compiled demo; normal-browser visual review is
still needed. Only build another APK when explicitly requested.
Validation: all 185 tests and clean analysis; new layout tests include retained
local state when crossing the desktop/phone breakpoint, large text and shortened
viewports. The isolated web demo compiled. Native widget screenshots were
inspected with sample images; device/browser acceptance above remains outstanding.

Look/feel image choices now supplied: A Warm Studio, B Focus Canvas, C Room Journal,
saved under ignored `output/design-review/app-look-*.png`. Exact prompts retained
beside them. These are original generated UI concepts informed by the user's
HOMLY/Forma preferences, not running app screens. Await the chosen option or blend,
implement it while preserving current features/storage, then build a new APK when
requested. This image batch builds no APK and changes no app code.

Distinct alternatives correction (source only, after 1.0.8): the user's multiple
designs must be different renovation schemes, not the same result with plants.
Replaced weak material/light/texture directions with Clean & architectural,
Warm & tactile and Bold & sculptural briefs, supplying all planned directions to
each request. Require visibly different major surfaces/main furnishings or
cabinetry/lighting where authorised; keep explicit protections and the palette.
Counts, frozen source, sequential paid confirmation and partial-save handling
are unchanged. No paid generation run here. On next requested APK, test one
whole-room 3-option batch against the same original and compare substantive
differences; don't loosen Keep choices or auto-retry charges to force variety.
No newer APK built. Automatic perceptual diversity assessment remains unimplemented.
Validation: static analysis clean; all 180 tests pass. No actual AI output quality
or visual novelty claim follows from mocked provider tests.

Autosave shortcut, source change after 1.0.8: More tools > Autosave now toggles the
existing saved preference in workspace and guided setup; a check mark shows its
state. Compact local-save status replaces the large workspace switch/card.
Room settings retains Save now, file options and the full setting. Verify menu
toggle/persistence/failure at phone and desktop widths and existing exit saving.
No new APK requested for this change; the installed 1.0.8 retains the old control.
Validation complete: analysis clean and all 179 tests pass. The deletion test
now waits for page scrolling/layout before tapping its existing review menu.

Latest requested mobile build: 1.0.8+9, source `3e62d1b14e`. Analysis clean,
176 tests pass; build completed in 72.3 seconds. APK at
`output/mobile-test/renovision-test-1.0.8.apk` and latest alias; package/version
verified and signing certificate matches 1.0.7. Install over the existing app.
Phone test: analyse a room, choose 2/3 ideas, review the brief, confirm the shown
paid count, generate, select Use this design and check saved versions after a
restart. Also check camera/gallery entry. No real AI calls made by the agent.

Look/feel is next: review Warm Studio, Focus Canvas and Room Journal in the
isolated `output/design-review/renovision-next-look.html` preview. Tabs, local
refinement drafts, room/sample selection and layout bounds checked in headless
Chrome at 320px content width and desktop width (19 checks each). Example images
are existing fictional samples, not paid generations or a real camera stream.
Choose a direction before broad source layout changes. Existing projects, photos,
APK history and connection settings retained. Only build later APKs when asked.

After-analysis redesign choices (now included in 1.0.8): current whole-room
analysis now shows 1 design / 2 ideas / 3 ideas, using the existing saved count.
Setup continues with Choose redesign options; generation buttons show multiple
output counts. Review the AI brief before the existing paid confirmation, then
select a generated result with Use this design and refine from that version.
Choosing a count must not issue an AI request or stale the analysis. The initial
source batch was subsequently packaged on request as 1.0.8 above.
Validation: static analysis clean; all 176 tests pass. New coverage verifies
count saving, no generation on selection and unchanged analysis freshness;
existing confirmation, prompt use and multi-concept generation tests also pass.

Previous requested APK: 1.0.7+8 / source `fa1e8d0319`, built in 75.3 seconds at
`output/mobile-test/renovision-test-1.0.7.apk` and the existing latest alias.
All 175 tests pass; static analysis clean. APK metadata verified and signing
certificate matches 1.0.6, preserving update compatibility without uninstalling.
Phone test next: open an existing saved project; take a new-room photo; add
another camera angle in Room photos; choose multiple existing photos; cancel
camera/gallery; restart and verify saved photos/settings. Direct AI generation
remains a separate user-authorised paid test. Existing user data was not cleared.
The HOMLY/Forma compact redesign and live-camera renovation are not in this APK.
Only build subsequent APKs on another explicit request.

Latest reference choice, 18 November: HOMLY is the user's functional/workflow
reference; Forma is the styling reference (exact links and access limitations in
`docs/PRODUCT_NOTES.md`). Combine these with the previously requested compact
Planner 5D-inspired room/fine-tuning workflow. Target warm cream/taupe, charcoal
text, earthy accents and large room imagery. Prominent camera/gallery entry,
compact active control sections, selected-design refinement and nearby versions
are Renovision's adaptation, not verified HOMLY animation details. Exact HOMLY
motion still needs visual inspection before matching interactions. Preserve
projects/data and existing contextual toolbar. Do not add budget/shop/contractor
scope from the inspiration. This is the selected design specification, not a
completed app redesign; no APK should be built until explicitly requested.

Chosen visual/workspace direction — user feedback, 18 November: use Planner 5D's
room-design presentation as inspiration, especially visual room choices and
fine-tuning beside the result. Prefer one workspace with little page scrolling.
Desktop target: large image/before-after canvas with a compact side panel and
version thumbnails nearby; remove the centred long-form workspace constraint.
Phone target: keep the image visible above a compact tabbed/expandable control
area; accommodate keyboard and large text without clipping or nested scrolling.
Organise controls as Room/photos, Style/colours, Refine and Versions; show only
the active section, preserving drafts and in-flight jobs when switching.
Keep capture/gallery entry obvious and retain a place for Camera Renovation View.
Refine must use the selected saved design with a new instruction and retain its
parent/history; do not merely append edits to the original-room brief. Keep paid
request review, error feedback and real progress visible. Reuse the existing
42 room types; visual examples must not imply every type has a real sample photo.
This records the selected direction; the compact workspace is not implemented.

Phone camera/gallery batch, 18 November (source only): make Take photo and Choose
photos explicit on project entry; add camera capture to Room photos in setup and
the workspace, preserving native gallery multi-select. Sample starts now offer
source selection. Validate camera success/cancel/failure, local persistence and
existing workflow before declaring ready. No APK requested or built. Physical
S21 follow-up: capture a new room, add another camera angle, select gallery photos,
cancel each picker and restart to confirm images/settings remain. Android activity
destruction while the external picker is open still needs recovery work/testing.
All 175 automated tests passed; camera/gallery routing, cancelled/failed capture
and local-store reopening are covered without accessing a real camera or AI.

Camera Renovation View priority — user clarification, 18 November: the key new
experience is an embedded camera view, explicitly capture/generate from that
view, then reveal the saved redesign with a before/after slider or opacity
overlay and save/refine it. Prioritise a same-view camera prototype ahead of
optional skins. This proposal's first milestone is now implemented in 19 November
source, with physical-device acceptance pending: smooth camera preview, explicit
capture and paid generation with visible progress, frozen-frame comparison,
immutable source/result saving and reopening. Next: manual return-to-view
alignment with a clearly labelled approximate overlay. A static generated image
cannot remain geometrically correct while walking around; tracked surfaces and
consistent moving-camera whole-room rendering require separate AR research.
Do not imply instantaneous generation, automatically send video/paid requests,
or build an APK without an explicit request. See the camera workflow in
`docs/PRODUCT_NOTES.md` for acceptance criteria and limits.

Visual review, 18 November: three isolated interface previews (Warm Studio,
Image Workspace, Editorial Home) are in ignored `output/design-review/`.
Warm Studio is the recommended direction, with Image Workspace's selected-design
refinement. Review this direction before broad Flutter layout changes; details
and research links are in `docs/PRODUCT_NOTES.md`. Private phone testing is ready;
public release still needs the acceptance/recovery/distribution work listed below.
User preference: only build another APK on an explicit request. This batch changes
research notes and previews only; no app code or project data changed.

Contextual toolbar batch: version 1.0.6+7, source `3ffefb376a`. A shared toolbar
defines icon meanings and ordering; each screen supplies only applicable actions.
Save/setup/editing controls precede Settings, Rename, Finish later and Help.
Narrow screens show up to three direct actions, with extras in More tools in
the same order; desktop shows more actions directly. Project screens add Save
and Settings beside Rename. Guided setup adds Save/Settings/Finish later, saving
draft edits before settings navigation. Crop/markup add Save/Undo/Redo/Reset;
image viewing retains zoom/fit only, and comparison adds Reset/Help. Root Settings
does not show a redundant Settings action. Titles truncate safely on phones.
Existing body controls remain available and share existing save/edit handlers.
All 172 tests passed and static analysis is clean, including toolbar order,
phone overflow/disabled actions, actual toolbar project-file saving, preserved
setup edits, editor Undo and comparison reset. No paid calls made; physical S21
visual/navigation acceptance remains a user check.
Universal release APK built in 61.1s at
`output/mobile-test/renovision-test-1.0.6.apk`, also the latest
`renovision-test.apk`. Signature verified against 1.0.5, with unchanged package
and signing identity and version code 7. Install as an update without uninstalling;
prior APKs, projects, images and device connection settings are retained.

Compact help UI: version 1.0.5+6, source `7944f6f4ea`. Repeated explanations on
Project file/backup, palettes, design styles, workspace, AI instructions/generation,
manual handoff, version history and autosave now sit behind labelled info icons.
Hover reveals a tooltip on desktop; tap or keyboard activation opens a scrollable
readable panel on phones/desktop. Project file shows its Save buttons and short
success status. Errors, pending/action-required statuses, AI progress and paid-
request consent remain visible. First-step room-photo guidance is unchanged.
No storage/model/provider behaviour changed. All 166 tests passed, including
hover, keyboard, large-text phone layout, unchanged saving/Autosave on help taps
and preserved first-step guidance. No paid calls made. S21 visual review remains
a user check.
Universal 1.0.5 APK built in 395.4s at
`output/mobile-test/renovision-test-1.0.5.apk`, also the latest
`renovision-test.apk`. Static analysis clean; signature matches 1.0.4, with
unchanged package identity and version code 6 for an in-place update. Prior APKs,
projects, images and connection settings are retained.

Design deletion batch: version 1.0.4+5, source `55b1bf7204`. Delete controls now
exist on generated results, Explore, favourites and the version-history menu.
Confirmation moves a design to Deleted designs, removing it from active lists;
Undo and per-room Restore recover the same ID, bytes, metadata and favourite
status. The selected deleted version falls back to the approved baseline/original.
Original room photos and approved baselines are protected; choose another baseline
before deleting the current approved one. Active AI requests block deletion.
This is recoverable deletion: records/images remain in project storage and
portable files so child versions and saved analyses keep valid source/parent
references. Permanent purge is future work. Old project files default to active
designs. All 160 tests passed and static analysis is clean, including cancelled
confirmation, Undo, restart, storage failures, selected-image fallback and backup
round trips with deleted parents/analysis sources. No paid calls made; physical
S21 deletion/restore checks remain manual.
Universal release APK built in 59.0s at
`output/mobile-test/renovision-test-1.0.4.apk`, also copied to the latest
`renovision-test.apk`. Signature verified against 1.0.3: same package/signing
identity and higher version code 5, ready for in-place installation. Prior APKs
and local user data are preserved.

Multiple-concept/style batch: version 1.0.3+4, source `a198a37712`. Style chips
intentionally support blending several influences into one design. Help text
now makes this and the need to Generate again explicit; concrete style cues
strengthen the prompt, with protections/scope/palette taking priority. Fresh
whole-room attempts request a different interpretation and rotate design focus;
precision prompts remain narrow. AI visual variation is not guaranteed.
Multiple design ideas offers one confirmation covering 2 or 3 sequential paid
requests from the same frozen working image/settings. Compare styles
separately creates one selected style per concept; with two styles/three outputs,
the third is a blend. Each result saves immediately as a sibling version with
its actual prompt/source/provider metadata. The gallery supports full-screen
viewing and Use this design; it does not approve a baseline. Stop after this
image prevents later requests. Provider/local-save failures retain earlier
results and stop the batch; retry-saving sends no provider request. Exact-byte
duplicate outputs are flagged without automatic paid replacements. Saved room
batch preferences survive portable project export/import; old files default to
one result. All 152 tests passed and static analysis is clean. No paid calls were
made by the agent. Real S21 style adherence/variety remains a user test.
Universal APK built in 58.5s at `output/mobile-test/renovision-test-1.0.3.apk`
(also copied to `renovision-test.apk`). Signature verified against 1.0.2, same
package/signing identity and higher version code 4. Install as an update without
uninstalling. Earlier APKs and all project/image data are retained.

Crop/markup batch: version 1.0.2+3, source `e7b7ed2e66`. Crop has eight draggable
corner/edge handles, inside-drag movement and bounds/minimum-size protection.
Sketch adds pen, line, arrow, rectangle, ellipse, text notes, six colours and
three widths. Multiple marks can coexist; Select / move supports repositioning,
recolouring, width changes, note editing and whole-mark removal. Undo/redo covers
these changes and clearing marks. Short touch drags are recognised within the
canvas. Original photos remain unchanged. Crop processing uses a native isolate;
markup preview/export share one renderer, with full-resolution metadata-free PNG
output. Markup is editable only in the current editor session, then flattened
into the saved reference; persistent editable layers remain future work.
All 143 regression tests passed and static analysis is clean, including crop
resize/move/tap retention and phone-width multi-colour shapes/notes/undo/export.
Physical S21 gesture and visual checks remain a user test. No paid API calls made.
Universal release APK built in 98.4s at
`output/mobile-test/renovision-test-1.0.2.apk`, also copied to the latest
`renovision-test.apk`. Package identity is unchanged; version code increased to
3. Signature verified against 1.0.1: the same signing identity supports an
in-place update. Earlier APK copies and all local project data are preserved.

Phone image-viewer batch (version 1.0.1+2, source `4d0ef665b2`): user installed
the first APK on a Samsung S21 after resolving a Company Portal installation
restriction. Generated images now have a tappable full-screen preview, both in
guided setup and beside the generation controls. Working images, Explore ideas,
version thumbnails and favourites also open the shared viewer. Pinch/pan,
double-tap zoom, zoom buttons and fit-to-screen use the full image bytes; the
viewer adapts to portrait/landscape and refits after a size change. It honours
Android Auto rotate rather than changing device orientation policy. Viewing
does not edit images, approve baselines or call AI. All 140 tests passed and
static analysis is clean; physical S21 viewing/rotation remains a user check.
The gallery regression test now scrolls to Save idea in the expanded layout.
Install the new APK over the current app to retain data and the device key.
Release universal APK built in 67.3s at
`output/mobile-test/renovision-test-1.0.1.apk` (also the latest
`renovision-test.apk`). Signature verified against version 1.0.0: same signing
identity, package and higher version code 2. Previous APK retained locally.
The emulator stopped responding to read-only UI inspection, so no new native
visual acceptance is claimed and its projects were not changed. Phone viewing
and Auto rotate are the next manual checks; no paid requests were made.

18 November direct internet API batch: Android now supports a personal OpenAI
key with direct HTTPS requests for analysis and image generation. No Windows
relay, adb reverse or tunnel is needed in Internet API mode. Settings provides
the mode selector, obscured key field, model check and key removal. Android
stores only encrypted key ciphertext, backed by Android Keystore; this secret
is excluded from Android backup/device transfer and project exports. Chrome
keeps direct keys in session memory only. Saved Android direct settings restore
from the vault without a startup provider call. The optional relay still works.
Full regression suite: 135 tests passed, including six mocked direct-API tests.
Real key/billing/output verification remains a user test; no paid calls made.
Android build `9d222d5de2` installed successfully with an in-place update. The
existing saved project remains visible and the Internet API key form was checked
on the emulator, including the Android keyboard. No adb reverse is configured.
Web compilation passed and the matching preview is served at the unchanged
http://localhost:7357 address. Static analysis: no issues.
This supersedes relay-required instructions in the earlier batch notes below.

Physical-phone handoff: user reports the direct internet API test worked.
Prepared `output/mobile-test/renovision-test.apk`, source build `9d222d5de2`:
release mode, universal Android processors, existing development signing key.
Build succeeded in 142.4s and APK signature verification passed. This is a private
sideload test package, not a Play Store release. Copy it to the phone and install;
copy a saved project separately and enter the API key on that device. Physical
phone installation, lifecycle, camera and generation checks remain user tests.

18 November resume after PC reboot: AI activity feedback is now implemented.
An elapsed timer and actual preparing/waiting/reading/saving/complete/error
stages remain visible in a fixed strip in room workspaces and guided setup.
There is no invented percentage. Activity notifications are separate from AI
connection settings, so clock ticks do not rewrite credentials. Saving failures
retain the received result; retry-saving updates activity without another paid
request. Full suite: 129 tests passed; final static analysis checked separately.

Previous progress-batch source/Chrome/Android build: `a793f4c30b`. Chrome restored at the same
http://localhost:7357 address. The existing Android AVD was cold-booted without
wiping data; the copied project file survived. Updated x86-64 debug APK built in
103.7s, installed with `adb install -r`, and launched successfully. Native first
screen, Projects and system Open project picker were observed; a saved room
workspace was subsequently visible. Controlled full import/restart/camera/keyboard
checks remain incomplete because emulator navigation changed during automation;
avoid conflicting with the user testing it. A development adb reverse tunnel maps
phone localhost:8787 to the Windows relay. The relay itself stopped at PC reboot
and must be restarted with its key entered privately for real AI requests. No
provider requests were made by these checks. Screenshots/logs remain ignored.

Working: projects/rooms/photos, guided setup, style/palette/protections, OpenAI
analysis and generation, saved versions/comparison, local autosave/reload and
portable Open/Save project files. The user has produced successful live designs.

Priority order:
1. Visible AI activity (implemented in this batch; user visual verification next): real elapsed time, honest request/preparation/wait/save
   stages, last update and clear timeout/error outcomes. Keep activity visible
   while scrolling. Do not invent a percentage or retry a possibly billed request
   automatically. Prompt assembly, remote analysis and image generation must be
   distinguished; current service timeouts are 110s/210s, not expected durations.
2. Finish Android emulator validation: updated debug x86-64 package `a793f4c30b`
   is installed and launched, and a saved room workspace was observed. A copied
   project is in emulator Downloads. Native navigation and picker presentation
   work; complete controlled import/save/restart, keyboard, camera/permissions and
   real-device checks without interfering with the user operating the emulator.
   Do not call full Android acceptance complete.
3. Implement the discussed Refine this design panel: selected result + new
   instruction + Keep everything else, with parent/version history intact.
4. Make active AI/prepared brief and stale inputs obvious; distinguish keeping
   architecture from furniture placement during room-purpose conversion.
5. Improve responsive workspace: wider image/compare pane on desktop, compact
   controls and versions nearby, stacked touch layout on Android.

Before release: persistent Android document updates, camera/permissions/lifecycle
tests on a real device, robust interrupted-job recovery and a distribution/account
strategy (personal keys or a managed service). Extra providers, AR and payments are later work. Git history still
contains two private output files; clean that history before publishing it.
Private SDK/build diagnostics remain ignored; no paid AI calls were made by the
agent during emulator setup. No source-project photos or browser data cleared.

Older entries below are historical batch notes; this section sets current order.

Workspace/prompt review follow-up: desktop pages currently use a centred 950px
Flutter ListView, not an HTML iframe. Plan a responsive image-led workspace:
large image/compare area with a compact controls panel on wide screens; stacked
touch controls on phones. Keep one shared Flutter implementation. Avoid making
the design workspace depend on scrolling through every setup control.

Prompt priorities from the read-only saved-project review: add the discussed
Refine this design panel using the selected result plus a new-change instruction;
clearly display whether a reviewed AI brief or prepared local brief is active;
show which inputs made analysis stale; distinguish preserving architecture from
preserving furniture positions during a room-purpose conversion; specify window
trim/divisions and outside-view protection more clearly. Keep personal review
photos, exported prompts and metadata only in ignored output folders. No paid
AI requests or source-project modifications were made during the review.

Manual-copy clarification: removed the ChatGPT/Gemini dropdown because both
choices copied the identical prepared prompt and only changed the toast. There
is now one provider-neutral Copy AI prompt action, with instructions to attach
photos in an image-capable external app. This is separate from the actual in-app
AI connection; only OpenAI is currently integrated. Additional providers are
optional future integrations, not required to generate a design.

Restore-name correction: restoring a previously restored backup now collapses
trailing repeated `(restored)` suffixes to one. Existing project records and
contents are not renamed or migrated; use the project pencil to clean an older
title. Open project continues preserving the file's name. Eight backup/restore
tests pass and Flutter analysis is clean. No private project data was changed.

## Latest batch: guided rooms and portable project files (16 November)

Android follow-up validation: all 125 VM/widget tests pass; final static analysis
is clean. Eight file tests also pass after extending cancellation coverage: a
cancelled chooser-only save cannot trigger another chooser from autosave. Current
preview build is `01649b08ae` at the same http://localhost:7357 address.

Android-first clarification: Chrome is a development preview; the product must
behave as a native Android phone app. Browser-only file APIs stay in the web
adapter. Reusable destinations are now explicit: Android's current chooser-based
export saves a file once, then app-local autosave continues without repeatedly
opening a chooser. Updating/reconnecting a persistent Android document URI is
still outstanding. Phone screens no longer show browser-specific file advice;
the release manifest now includes INTERNET for later HTTPS service connectivity.
The current AI relay/HTTP development transport is not a production backend.

Toolchain check: Android SDK 36.0.0 and an emulator are present, but Flutter doctor
reports missing command-line tools and unknown SDK licence status. No tools were
installed and no licences were accepted. Before Android sign-off, complete setup,
build/install on a device/emulator, and test touch/keyboard layout, camera/photo
picker, denied permissions, Back, backgrounding/process restart, project files,
large photos and AI connection. Chrome tests do not establish these behaviours.

Repository privacy follow-up: `.gitignore` now excludes local editor/test
settings, credential/environment/signing files, private databases and exported
projects, browser profiles, recovery/backups and all `output/` artifacts. The
two previously tracked kitchen output files were removed from the index only;
local copies remain. Their content still exists in commit `f94fe9b`; historical
cleanup before publishing that history remains a separate task. No history
rewrite, commit or push was made. Common credential-pattern scans found no
matches in upload-eligible text, tracked text, or the eight reachable commits;
pattern scans are not a guarantee against every possible secret format.

Final served build: `0adf905de0` at http://localhost:7357. Flutter analysis is
clean. After the complete 124-test run, 13 save/settings/file checks also passed
for the final Save and close integration. No new app URL is needed.

Implemented a four-step new-room setup with photos/primary view, goal and optional
style/palette, AI analysis/review, then final editable options and generation.
Finish later saves progress; existing rooms open normally and can reopen guided
setup. Offline setup is supported; AI calls always require explicit confirmation.

Added Open project and first-class Save project/Save project as using the existing
portable .renovision.json format. Files contain all project rooms/images/designs,
instructions/analysis/choices and setup progress. Chrome can update a chosen file
and autosave changes while linked. Sequential writes, failed-save recovery,
cancelled selection and same-file project-copy protection are covered. After app
restart, Open project reconnects the disk file. Existing local projects are kept.

AI relay address/code and selected model/quality are now remembered in this
browser separately from portable files. Startup tries the local health endpoint,
never a generation. If the relay restarts, enter its new code. Continue using
http://localhost:7357; do not introduce alternate app ports/hostnames.

Validation: all 124 VM/widget tests passed and a web release build passed. Direct
isolated Chrome checks cover desktop/phone rendering, Settings and Open project.
A desktop Chrome flow created a disposable project, imported a fictional photo,
opened setup and saved/parsed a full project via an actual browser-sandbox file
handle. This is not the Windows file chooser test.
The separate Chrome widget harness stalled before running tests; no pass claimed.
User confirmed normal-profile project auto-reload. Pending manual test: save a
real project file, finish setup, restart Chrome, Open project, check every photo
and prompt, reconnect file saving, and verify the remembered AI connection while
the same relay remains running. No paid AI calls or user project changes were
made by these tests. Large project JSON encode/decode can still pause Chrome;
background-worker optimisation and recovery after forced termination remain.

## Earlier status retest

Status retest (16 November): 111 tests passed again; Flutter analysis clean.
Actual isolated Chrome checks passed at desktop (1440px) and phone (390px)
widths for gallery rendering and Settings navigation with AI connection/Restore
controls. Live provider generation, normal-profile restart and Android remain
unverified. No user projects or photos were changed by the retest.

## Latest batch: simpler design and correction modes (16 November)

Whole-room renovation now supplies a coordinated photo-led design direction
(surfaces, relevant fittings/appliances, lighting and restrained styling/cleanup)
without requiring a checklist. Explicit protected items and Keep choices take
priority. Detailed selections are collapsed into optional Advanced Keep / Replace
controls and remain stored as overrides. Uncertain fixed fittings require a
question or an explicit removal request.

Precise correction has a separate saved instruction field. It excludes the old
renovation text, palette/style and replacement selections, while retaining Keep
protections and the selected working image. Switching modes deselects the old AI
prompt; a direct correction can generate without another analysis. Both briefs
and overrides survive backup/restore. Existing instruction text is preserved as
the whole-room brief; old rooms start with an empty dedicated correction field.

All 113 tests pass; Flutter analysis is clean. The local web app was recompiled.
No paid provider calls were made, and the AI relay and saved user projects were
left intact. User test: refresh > whole-room goal/style/palette > analyse/review
> generate; select result > precise correction > describe one change > generate.
Reconnect with the running relay code if the app session was refreshed.

## Earlier batch: saved-work startup and Settings (16 November)

Button feedback follow-up: the user's real analysed brief combined Precise
correction with "All"; copy/generation rejected it but feedback was easy to
miss. Both now show a validation dialog. Analysis also rejects that combination
before a provider call. Select Whole-room renovation and analyse again to replace
the earlier no-change AI prompt. Sixteen targeted scope/generation tests pass;
Flutter analysis is clean. No paid requests were made during the fix, and the
user's running AI relay was not restarted.

Whole-room default follow-up: new-room creation already used whole-room mode;
the model constructor now agrees and the mode control lists Whole-room first.
Explicit modes saved in existing rooms are preserved. Changing the requested
scope invalidates an earlier AI brief; settle choices, analyse once, review/use
the new prompt, then generate. Thirteen store/scope tests passed.

Precision retest: 29 focused AI/scope/analysis/prompt tests passed; analysis
clean. The saved-design regression now explicitly uses precision mode, checks
the selected baseline's image bytes/parent and excludes unrelated flooring and
oven replacement instructions. Switching modes retains existing scope choices;
added guidance explains removing unrelated selections before a small correction.
This is a prompt-based edit, not masked preservation. Live visual precision still
needs the user's provider test; no paid requests were made by these checks.

Startup now reads existing projects and opens Projects when records exist,
instead of the pending-ideas Explore feed. Continue shows a saved room photo
and returns to the last opened room, using its approved design/primary view.
Older records without a resume marker also discover an existing room. This is
local browser storage, not automatic scanning of external backup files.

Design pages now keep Autosave and save status. The Settings gear holds Save now,
Save and close and Save as (project copy/image/backup). Global Settings has visible
Restore project backup, per-project backup controls and an AI connection/models
section. Backups opened from an active room flush its draft first. The room's AI
shortcut opens Settings. API keys still stay in the private relay; pairing is
session-only. The older per-project backup card and workspace image-download
button have been moved to these settings controls.

All 111 tests pass, including startup discovery, autosave preference reuse and
Settings saving with Autosave off. Analysis is clean and the web build passes.
Current build is `6e2f59dcc5`; refresh the fixed
Chrome address. Manual check: saved photo on startup > Continue > room Settings
> Save now/Save as > backup file > Settings Restore. Verify normal-profile restart
and actual file chooser behaviour. Keep existing projects and recovered backups.

## Latest batch: whole-room briefs and editor loading (16 November)

Analysis handoff follow-up: when the user selects the reviewed AI prompt,
the copied/generated brief now also includes the saved PHOTO ANALYSIS
observations, labelled as fallible observations rather than instructions or
measurements. The actual working photo and explicit user requirements retain
priority; spotting a bin does not itself authorise removal. Existing stale-input
checks still apply. This path needs connected analysis first; ordinary offline
template copying does not acquire image understanding. For manual testing,
ChatGPT can analyse the photo, draft the combined brief for approval, then edit.
Follow-up validation: 13 focused prompt/analysis tests pass, static analysis is
clean and the web build passes. Current test build is `7fd099c58b`; the earlier
108-test full pass predates this small handoff change. Live vision remains unverified.

Implemented clearer Whole-room renovation / Precise correction labels, an opt-in
Tidy and stage scope choice (bins/washing-up/incidental clutter), and a guard
against copying/generating an All request as a precision edit. Switch mode
explicitly; existing room settings are not silently changed. Whole-room All is
expanded into a coordinated selected-scope brief with layout/protections retained.

Finished the interrupted asynchronous preview change. Crop/sketch paint their
screen before engine decoding, reuse a display-sized preview and show loading/
saving states. Comparison/workspace previews also use a 1600px decode target.
Original bytes and full-resolution derivative saves are retained; native EXIF
orientation is baked into derivative output. Browser full-resolution encoding
still runs synchronously; loading/saving is not claimed fully non-blocking.

All 108 VM/widget tests pass. Current analysis/build status is recorded in
FEATURE_STATUS.md. The prior 106-test catalogue batch below is historical.
Analysis is clean and the updated web release build passes. Test build
`0fd4d9ddad` at http://localhost:7357 using the same normal Chrome profile.

Next user test needs no API key: open the saved kitchen, choose Whole-room
renovation, keep Layout protected, choose desired surfaces/appliances and tick
Tidy and stage. Copy the prompt, attach the working photo in ChatGPT and generate.
Import the result back into its room; inspect bins/clutter, floor, phone,
appliances and retained architecture. Test crop opening on the same large photo.

## Conversation-to-code audit (16 November)

Reviewed the requests available in this conversation against current code. Keep
these gaps distinct from features merely needing live/device verification.

| Requested outcome | Actual position | Next action |
| --- | --- | --- |
| Preserve existing photos/projects | Original bytes and branches are retained; recovery backups exist | Keep stable origin/profile; verify real restart/restore |
| Multiple views of a room | Up to six originals and multi-input requests implemented | Live check consolidated interpretation; not verified 3D |
| Palettes/styles and comprehensive room list | 42 spaces, 19 styles, 12 palettes, six fictional samples implemented | Extend illustrated coverage and keep full choices visible |
| Smarter prompt from photo analysis | Vision analysis and editable prompt wired to relay | Real API access and photo-based quality test |
| AI designs inside app / model testing | Four image-model options, analysis model and confirmed one-image requests implemented | Pair user's private API key and verify access/adherence/cost |
| Multiple alternatives then choose/refine | Existing single-result versions can be selected, approved and branched | Implement bounded new-option batches and A/B selection |
| Include floors/remove phone/update appliances | Scope and room-specific Keep/Replace preferences enter prompts | Check actual images; correct prompts are not proof of edits |
| Exact changes retaining approved layout | Protected text, precision prompt and approved baseline exist | Masks, compositing, structured locks and outside-region warnings missing |
| Auto/manual/exit/Save as storage | Controls and portable backup implemented | Real browser restart/picker/restore checks; stronger crash recovery later |
| Fast tool navigation with visible progress | Synchronous editor decode identified; asynchronous preview change partly applied | Finish editor tests and image loading states, measure large-image behaviour, validate/build before release |
| More visual workspace | Sample gallery/room cards implemented | Photo-led desktop/phone workspace redesign remains a proposal |
| Reference images / kitchen design board | Ordinary multi-angle images and sketch/crop exist | Separate inspiration/material/sketch roles and design-board export missing |
| Camera preview, snapshots, refine | 1.0.10 has capture/compare/manual overlay; newer source adds automatic reference analysis and tuning in the viewer | Requested APK + Chrome/S21 Live design acceptance; streaming, composite export, spatial scans and tracked AR remain |
| Competitor/pricing lessons | Research and priorities recorded in existing reference | Convert into verified workflows; no billing or competitor quality benchmark yet |
| Progress/continuity | Analysis/generation have waiting states; room saving status exists | Finish editor states and clearer stage feedback. Agent updates cannot replace the client's thinking UI or guarantee client reconnection |

Immediate order: finish the interrupted editor performance patch and tests;
verify existing-project restart/backup; connect live API access and run the
kitchen analysis > design > approve > narrow-refinement test. Then add bounded
alternatives/result review and the responsive workspace. Android acceptance
follows. Billing, public release, 3D/live AR and additional providers are later.

The 106-test/build pass below belongs to the 15 November catalogue batch.
Current unvalidated editor changes must not be reported as passing those checks.

## Basic app: current position and remaining tasks

The private Flutter prototype exists and can be used locally. It is not yet a
verified end-to-end AI renovation app: the user's live API access and real-device
acceptance tests are still outstanding. No new provider or 3D engine is required
for the basic photo-based workflow.

| Area | Current position | Remaining for the basic private test |
| --- | --- | --- |
| Room setup | 42 home/utility/outdoor space choices, search, categories and custom names | Check naming and selection with the user's rooms |
| Design choices | 19 styles, 12 palettes and six labelled fictional examples; full choices separate from sample filters | Check selections carry through to actual generated images |
| Photos and projects | Multiple originals, local room preferences, versions, approval and backups | Verify the user's normal Chrome profile after a complete stop/restart and an actual backup restore |
| AI analysis/prompt | Local relay, visible observations/questions, editable prompt and explicit selection | Connect a developer API key and inspect one real-room analysis |
| AI images | Confirmed one-image requests, model/quality choice, saved branches and comparison | Generate real results, check adherence/costs, approve one and refine that exact result |
| Failure handling | No automatic paid retries; pending-result local-save retry and normal-exit protection | Check interrupted real requests, actual browser close behaviour and disk/file-picker failures |
| Android | Shared Flutter code and still-photo entry point | Verify SDK setup, build, camera/permissions, save/export and restart on a device |

### Minimum acceptance checklist

- [ ] Check API-credit eligibility / billing and create a developer key privately.
- [ ] Start `tool/start_ai_relay.ps1`; connect using its temporary code in the app.
- [ ] Open an existing kitchen room; verify originals and saved preferences.
- [ ] Analyse its photos in-app; review observations/questions and select the edited prompt.
- [ ] Generate one low-quality image; confirm it is saved as a separate version.
- [ ] Check layout/windows, selected floor, phone removal, appliances and cabinetry.
- [ ] Approve a result, request one focused refinement, and compare with its parent.
- [ ] Reopen the app at the same origin/profile and confirm project, photos,
      preferences, analysis and approved design remain. Keep export copies.
- [ ] Export a project to a chosen location, restore it as a copy and inspect it.
- [ ] Repeat the core workflow on Android before calling the phone app tested.

Multiple new alternatives in one batch, masks/compositing, independent open-plan
zones, a shorter responsive workspace and more sample coverage remain further
work. Basic testing can compare separate single-image versions now. Payments,
accounts, cloud sync, public hosting and live tracked AR are outside this private
basic-app acceptance gate.

### Continuity and batch reporting

Preserve this checklist and FEATURE_STATUS.md after each validated batch, and
report changes, checks, running build and remaining blockers to the user. Resume
from the existing files after a session interruption; inspect the server instead
of starting a competing one or changing ports. The agent cannot guarantee that
the client automatically reconnects after a full disconnection. Do not replace
missing credentials or approval with automatic billable retries.

Requirements: [project brief](RENOVISION_PROJECT_BRIEF.md).
Actual implementation/limits: [feature status](FEATURE_STATUS.md).
Run instructions: [README](README.md).
Detailed setup/recovery: [testing guide](docs/TESTING_GUIDE.md).
Design/research background: [product notes](docs/PRODUCT_NOTES.md).

15 November review findings: [DecAI user-review lessons](docs/PRODUCT_NOTES.md#decai-user-review-lessons).
Prioritise room fidelity, result-versus-brief checks and continuing a selected
design without repeating setup. These are lessons from a limited public review
sample, not evidence that our outputs already perform better.

## 1. Finish real Chrome saving tests

Use `tool/start_web_test.ps1`, then open `http://localhost:7357` in the same normal
Chrome profile. Keep the host/port unchanged. Never clear site storage to diagnose
missing projects. Earlier test projects were recovered into portable backups;
[recovery instructions](docs/TESTING_GUIDE.md#recovered-projects) include the files.

- Confirm the existing project, room, original photos and instructions are present.
- With Autosave on, change text/preferences, wait for Saved, leave and reopen.
- With Autosave off, verify Save now and Save and close. Normal Back must save
  pending drafts and stay in the room if saving fails.
- Test Save as: named independent project copy, clean PNG and full project backup.
  Verify the Chrome location chooser, cancelling it and the resulting files.
- Restore a backup as a copy; check photos, preferences, versions and approval.
- Stop/restart Flutter and close/reopen normal Chrome at the same address.
  Confirm the project, photos and preferences persist without re-uploading.
- Browser close/refresh warnings and best-effort flush need real testing;
  forced shutdown cannot guarantee completion. Keep source photos/backups.

## 2. Improve the visual starting experience

15 November implementation: searchable/categorised room-type cards, custom naming, six original
AI-created sample rooms, room/style filtering and sample details are now present.
Use this style starts a new room with the selected style/palette and the user's
own photos. Samples are bundled under `assets/inspiration/`, separate from saved
projects. All 42 room types, 19 styles and 12 palettes are available independently
of the six illustrated examples. More sample categories, applying a preset to an existing room and the
responsive workspace redesign below remain future work.

- Done: 42 selectable home/utility/outdoor room types with search and seven
  categories. Original eight IDs and existing room-specific choices are retained;
  new subtypes use relevant controls. A custom name remains editable.
- Done: illustrated sample-design gallery, filtered by room/style, with visible
  palette/material descriptions and a clear Use this style action. Explore today
  reviews the user's own versions alongside the separate sample section.
- Keep sample inspiration distinct from personal photos, generated results and
  approved designs. Use owned/licensed or purpose-generated samples; private
  renovation photos are not public app assets. A sample must not change the
  geometry of the user's room or silently create personal project records.
- Build the responsive photo-led workspace: photo first, Style / Changes / Keep
  controls beside it on desktop and below it on phone; saved versions and
  Compare / Approve / Refine actions together. Existing private review mockups
  are in `output/design-review/`; they are proposals, not app features.
- Reuse IDs, storage, draft/save controls, approvals and room profiles.

## 3. Complete and verify the in-app AI journey

The workspace now has Test AI with this room near the top, including connection
setup/model controls. The updated relay offers GPT Image 2.5 and 2.6 Sunburst and Flare
(plus a configured custom default) and low/medium/high quality. Model changes
send no request. Image confirmation freezes the reviewed settings; result titles
retain model/quality and structured metadata retains the actual returned model.
Restart an older relay and reconnect to see these controls. Analysis still uses
the relay's separately configured analysis model.

The user confirmed on 15 November that they still have a subscription/login only.
Live testing awaits their own developer key and available API credit. Eligible
Pro/Business subscribers should check included-credit eligibility first; see the
model/access notes in docs/PRODUCT_NOTES.md#ai-model-choice. No user photo was
transmitted or live app-provider request made during this implementation.

Follow [AI setup](docs/TESTING_GUIDE.md#ai-test-setup) when API access is available.
A ChatGPT subscription/login is not a developer API key. Enter a key only through
the private relay launcher, never chat/source. Do not run paid requests silently.

- Verify visible room analysis, clarification questions and the editable prompt
  against the actual photos. Explicitly select the AI prompt for generation.
- Check current palette, Modern / Contemporary, scope and Keep/Replace choices
  enter the request; stale analysis must not override changed preferences.
- Test the kitchen: retain layout/windows/viewpoint, change selected flooring,
  remove the old telephone/cord and repair the wall, visibly update requested
  appliances, and retain handleless cabinetry and selected colour direction.
- Compare and approve a result, then refine that exact version. Confirm saved
  originals and prior branches survive. Check retrying local save sends no new
  provider request. Provider adherence and live costs remain unverified.
- Add a result-side checklist of requested changes/protected features and a
  useful way to flag what missed. Check the image against it rather than treating
  a correct prompt or AI explanation as proof of a correct design. Extend the
  benchmark with a specified two-bed arrangement and an open-plan kitchen/living
  scene; explicit independent room zones are not implemented yet.
- Add bounded multi-result generation and A/B selection as a separate batch;
  current generation returns one image. Retain partial successes, show usage,
  and never automatically retry paid requests.

## 4. Subsequent work

- True selected-region editing/masks/compositing and outside-region warnings.
- Separate material, inspiration and sketch references; design-board export.
- Project search/filtering, safe deletion/undo and richer version review.
- Android setup and real device tests: capture, permissions, gestures, pickers,
  saved projects after restart, interrupted operations and backup round trips.
- Camera path: verify the new embedded preview, capture/design comparison and
  explicitly approximate manual overlay. Moving-camera whole-room AR is separate future
  research; a generated flat image is not a tracked room model.
- Keep billing/public hosting/store release deferred. A$4.99 starter / A$9.99
  room packs are price hypotheses only; measure analysis, outputs, refinements,
  retries and other costs before setting allowances. No uncapped paid AI.

## Validation and preservation

Latest recorded code checks (15 November): 106 VM/widget tests passed, static
analysis is clean and the final catalogue web release build passed. These do not prove real Chrome
restart durability, file-picker behaviour, Android or provider quality. The
earlier documentation consolidation did not rerun code checks or AI calls.
Do not assume an earlier server session/build is still running; check Settings.

Current 16 November test server: http://localhost:7357, build `6e2f59dcc5`.
The previous server was stopped normally and replaced at the same address.
Refresh in normal Chrome; check Settings > App build and saved data. This does
not verify that the user's own saved project has survived a browser restart.
The final app was rendered in isolated Chrome profiles at 1440px desktop and
390px phone width; sample controls were present and the page fitted the viewport.
Private screenshots are `output/design-review/app-explore-desktop.png` and
`output/design-review/app-explore-mobile.png`. These visual checks do not replace
the acceptance checklist or real device/provider tests above.

After code changes, run analysis, relevant tests and the web build. Keep Hive box
names, original photo bytes, IDs and existing projects intact. Use disposable test
data for automated checks. Normal user work stays in the existing browser profile.
Earlier detailed documentation is preserved in the consolidated references;
exact pre-cleanup files and the longer old next-steps history are copied under
`.local_backups/documentation-2026-11-15-*/`. These are document copies, not app
project/photo backups.
