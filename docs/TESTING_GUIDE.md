# Testing and storage reference

## Follow-up acceptance — 23 November

Latest finish-polish source: **`7821f8aa18`**, same localhost:7357, no APK update.
396 full-suite tests (100s), clean analysis, web build and refreshed paint-help
capture/full decode pass. Mocked tests verify actual clean/guide byte order, no
request before confirmation or after Cancel, legacy draft reopening, missing-source
refusal and portable Save/restore with both source references. No paid AI call.

Owner confirms the supplied tile pictures are **Local finishes** versions; an AI
attempt failed, leaving that preview selected. This does not establish that no AI
was attempted. For the
next real polish test, select that version and use Refine > **Polish saved finishes
with AI** (or the pinned **Polish with AI** action inside Colours & tiles). Review
the confirmation: **Clean design · image 1**, **Rough finish guide · image 2**.
Cancel first to check no new AI version. Confirm only when ready for a paid request.
The completed result must be a separate **AI finish polish** version. Compare its
actual splashback wall planes, tile/grout colours, window/view, sink/tap, worktop
and cupboard edges with the clean source. A saved local preview alone does not
establish that AI ran; local outlines can cross objects and need checking.

Local checks: White/Black/custom grout must change only grout, retain tile colour,
and survive save/reopen. The Polish action stays visible in Select, Finish and
while Tile layout & grout is expanded. Phone touch/camera/chooser acceptance still
follows the next explicitly requested APK.

Current corrections: owner confirms key saving. Agent-run real filesystem tests
now pass in the actual Windows OneDrive Renos folder, using new uniquely named
`RenoVision-save-check-*` subfolders and generated fixture photos. Save, autosave,
Save as independence, failed-write recovery, reopen, separate-copy restore, encrypted
export and wrong-password rejection were checked. No existing files were changed.
Evidence: `output/onedrive-save-acceptance.log` and `project_disk_acceptance_test.dart`.
This does not claim cloud-sync or physical phone chooser acceptance.

Current correction-pass evidence: 394 full-suite tests pass (86s); 28 targeted paint/
refinement tests pass after the final stable progress slot. Seven help captures and
full MP4 decodes pass. Actual Chrome verifies the single update field, local project
look reuse, Save as retaining both rooms/palette/independent instructions, and the
advanced exported-copy-only protection explanation. Logs:
`output/save-refine-tests-verified.log`, `save-refine-final-tile-checks.log`,
`save-refine-final-desktop.log`, `save-refine-final-phone.log`,
`save-refine-help-encoding.log`. Final source `2643765277`: clean final analysis
27.2s, release web build 63.3s; desktop and phone screenshots inspected. Current
APK remains 1.0.17+18; no paid AI request was made.

Normal saving now has Save project / Save project as. The duplicate plain backup
snapshot button is removed. Password export is collapsed in Advanced and protects
only the exported copy. To test a snapshot, Save project as a new filename, edit
the working file, then Restore a separate copy from the earlier file.

Selecting a result now starts Precision and hides the original broad brief. Choose
New design or Partial explicitly to return to wider changes. Test full-splashback
four corners, directional growth and repeated sliders without reopening Tile layout.
Use another room's look should copy only style/palette; its observations/layout
must not appear in this room's prompt. None of these local actions needs AI.

Use the same normal Chrome profile at **http://localhost:7357/**. Keep all old
projects. A fresh test is a separate project/file, not a storage reset. Source
changes in this batch are not in published APK 1.0.17. Ask for a new APK after
Chrome acceptance; then repeat camera/Live, vault, chooser/save/share and touch
checks on the S21. Mocked tests cannot establish AI design quality.

| Check | Actions and expected result |
| --- | --- |
| Remembered key | Enter privately in Settings > AI connection and models once after updating. Visit all four workspace tabs, reload, then close/reopen this same address/profile. Connection restores. Remove key explicitly and reload: it stays removed. Never put keys in screenshots or project files. |
| Autosave and real file | Use the visible switch under the title. With it on, change an instruction, leave/reopen the room: it returns. Save project as a new file in Renos, verify nonzero Windows size, open the file and compare rooms/photos/designs/choices. Edit while that browser file is linked and reopen it to verify the update. A restart requires reconnecting the external file; local work still returns. Android chooser exports are not persistent linked-file autosave. |
| Snapshot vs import | Save project as a separate filename, edit the working project, restore the earlier file: an independent older copy appears. In the active project's settings choose Import rooms from project: confirm to add remapped room copies, preserving existing rooms. It does not merge same-room edits. |
| Project names/delete | Create two projects with the same proposed name: the second gets a numeric suffix. Use the project row's delete icon, optionally back up, type its exact name, then Archive or Delete. It disappears from the active list; restore it under Archived & deleted projects and verify full contents. |
| Whole room | In Style, turn Whole room off/on before opening detailed choices. Expanded Keep exceptions and individual item choices remain editable where applicable. |
| Focused update | Select a generated version. Refine shows Update this design. Request only a brass tap; choose Apply focused update and review. Cancel first: no request. Confirm only when ready to pay. Result is a child version; original renovation instructions and approved baseline remain unchanged. |
| Paint polish | Select a wall/splashback and finish; use the pinned Polish with AI action. Review clean source first, rough guide second. It must exclude whole-room replacement instructions and unrelated angles. Cancel sends nothing; confirmed success saves AI finish polish separately from Local finishes. Reopened local versions offer Polish saved finishes with AI in Refine. |
| Materials | Outline a splashback with four convex corners clockwise from top-left, import a cropped material sample, enable Fit tiles to four-corner outline, adjust scale/grout. Save/reopen and change colour. Unselected objects and original remain intact locally; judge perspective/edges as a preview. |
| Distinct options | With a fixed palette/Keep layout, choose three new concepts. Inspect prompt directions before confirming three paid requests. Compare actual cabinetry/hood/material/main-light schemes, not plants alone; record model/quality/elapsed time. |
| Notices and compact UI | Switch Room/Style/Refine/Ideas on desktop and phone width. Generate/Brief % and Autosave stay available. Informational notices dismiss or expire; a failed-save retry remains available. Check enlarged text and keyboard. |
| Region, costs, research | Settings > Language & region changes terminology. AI usage & image budget shows priced/unpriced images; a manual USD budget is an incomplete estimate, not provider credit. Ideas > Current design references is optional OpenAI-only text research: review the query and separate cost confirmation; enable returned sourced notes only after reading. No photo is sent for that research. |
| Help | Replay the refreshed recordings, check captions/controls, seek/full-screen, then return to the same project. Demos use simulated AI/camera and never change customer projects or spend credits. |

OneDrive checks are acceptance of the existing project-file feature after its
empty-file bug, not a new OneDrive integration. No OneDrive account/sync API is
added. The original failure's cause is not established. Keep the original empty
file and save the test to a new filename.

Verified source `ac96247b07`: full suite 388 passing tests, followed by 24 related
project/library/save tests after the final archive visibility fix; clean final
analysis 17.7s; web build 48.2s.
Actual desktop/phone-sized tab navigation and inspected screenshots pass. Actual
selected-update field, Autosave browser reload and typed archive/restore pass;
vault reload/separate deletion passes with synthetic keys. Seven offline help
captures pass and all MP4s pass codec/timestamp/full-decode checks. Evidence:
`output/followup-tests-accepted.log`, `followup-archive-final.log`,
`followup-controls-verified-browser.log`, `followup-phone-final-browser.log`,
`browser-vault-check.log` and `followup-help-encoding.log`. These do not count as
real provider, native file-picker/OneDrive or S21 acceptance.

A separate clean local file was created at
`output/test-projects/RenoVision-followup-kitchen.renovision.json` (not committed):
one authorised original, new IDs, Modern / Contemporary and Charcoal & walnut,
no previous analysis/designs/credentials. Older test files remain untouched.
Older dated evidence below applies to its stated build.

## Today's acceptance pass — 22 November

This is the current manual test order for audit IDs T01–T19 in FEATURE_STATUS.md.
Automated success is not visual acceptance of an AI result. Start with local/free
checks; paid requests happen only when the owner confirms them inside the app.
Keep existing projects/data and use a new separate test project/file.

Already verified on current source: 374 automated tests, clean analysis and release
web build; real Chrome 16 MB file bridge/every-byte read-back and empty-write
rejection; app Open/Save/reload with a separate sample; and this audit's actual
Room/Style/Refine/Ideas navigation at desktop and phone dimensions with inspected
screenshots. The old workspace automation stall did not reproduce. This does not
replace real provider, system file-picker/OneDrive or physical S21 acceptance.

| Test | Actions | Expected result / record |
| --- | --- | --- |
| 1. Real file saving (T10–T11) | Open the separate fresh kitchen file below. Save project as a new filename in `C:\Users\dbraz\OneDrive\Documents\Renos`. Check Windows file size, reload the app, then Open that exact file. | Nonzero size; original photo, room, style/palette and instructions return. No missing work or success on an empty file. Preserve the old zero-byte file. |
| 2. Autosave vs backup (T11) | With the working file open and Autosave on, edit a room instruction and wait for pending/saving to finish. Open the working file again. Export a backup snapshot, edit again, then restore the earlier snapshot. | Working file includes the edit while connected; restored snapshot creates a separate project with the older contents. Existing work is retained; no merge occurs. |
| 3. Connection (T09) | Connect privately, note provider/image model/analysis model/quality. Visit Room, Style, Refine, Ideas and Settings. Reload the browser. | App tab navigation retains the connection. Page reload clears the session key with an enter-key notice; project data and saved nonsecret preferences remain. Never include a key in screenshots/reports. |
| 4. Navigation and controls (T01–T05, T08) | Check Projects first and cog/Back. Select styles across two pages; change palette. In Style turn Whole room off, choose an individual update, then turn it on and choose a Keep exception. In Refine switch New / Partial / Precise. Open Ideas without results. | Ten style choices per page; selections persist. Compact palettes, editable Keep exceptions, separate instructions retained. New design on normal room entry. Ideas offers inspiration; manual copy/import is in Refine. |
| 5. Generate/checklist (T03–T04) | Open brief checklist from each tab. On a low-coverage brief select Proceed with current brief; cancel at send confirmation. Open prompt preview and close it. | Generate/Brief % stay accessible. Optional low coverage does not block proceeding; cancel sends no request. Prompt details start collapsed. No automatic charge from changing choices. |
| 6. Real analysis and one concept (T06–T08) | Use one kitchen photo first; optionally add another view and check included-photo confirmation. Choose New design, Whole room, style/palette and Keep choices before analysing. Review facts/plan, then preview and explicitly generate once. | Facts describe actual images; plan is future design direction. Current enabled plan appears with current instructions. Result retains architecture/layout while substantially updating allowed materials/fittings/main light. Record model/quality, duration and visual misses. |
| 7. Reuse and refinement (T06–T07) | Change palette after analysis and preview without analysing again. Select a generated image, enter a precise instruction such as tap only, and confirm one correction if desired. Separately try 2 ideas when ready for two charges. | Current choices plus matching photo facts remain; stale plan is omitted. Precision stays focused. Multiple ideas should differ materially, not just add plants. This needs real-image acceptance. |
| 8. Local finishes (T12) | Select a wall, change colour twice on the same layer, extend edge then Undo. On a separate surface choose kitchen Splashback tiles, alter scale/grout, save/reopen. | Colour replaces previous colour; same selection retained. Edge extension is undoable. Smaller patterns/finer grout persist. Outside pixels/original stay intact. Judge actual edges; preview is not perspective-correct material rendering. Finish with AI only prepares a separately confirmed polish. |
| 9. Offline sample (T14) | Help > Sample walkthroughs > Try kitchen sample flow; replay stages, inspect brief/compare, create separate practice copy. | No key or AI spending; before/after and saved brief available; existing projects unchanged. Later idea board is a different-view sample, not a fake in-app generation. |
| 10. Save completed work (T10–T11) | Save project after a real analysis/design and local finish; reopen that exact file. Export one image too. | Full project restores analysis, history, original, choices and saved layers. Image export contains only the chosen image. No credentials in project files. |

**Recommended platform order:** use current Chrome at localhost:7357 for prompt,
form, history and desktop file acceptance first. It is quicker to iterate, not
proof of Android behaviour. Latest Chrome is `68527c827a`; APK 1.0.17+18 is older
(`d19f2fd3d2`) and lacks the last two commits. Do not compare those as identical
builds or silently rebuild an APK.

After an explicitly requested APK of accepted current source, install over the
existing S21 app (keep data). Repeat tests 1–10 with native file choosers and add:
camera/gallery permissions and rotation; Live analyse/generate/overlay staying in
the viewer; background/resume/interruption; secure key retention after restart;
image save/share; offline/error recovery; real speed and enlarged text. Chrome
cannot replace those device checks. iPhone acceptance follows separately.

For fair AI comparison use the same original bytes, supporting views, provider,
image/analysis model, quality, selected mode, instructions, plan toggle, style,
palette and Keep choices on the same source build. Provider outputs can vary per
request; matching input should give comparable capability, not identical images.
Chrome and Android share prompt/provider/photo-preparation code. File permissions,
credentials, camera and rendering/processing speed differ by platform. No evidence
establishes that Chrome inherently uses a weaker image model.

Known unfinished features should not be tested as if present: project merge;
region/language selector; automatic web/product research; usage-based dollar
balance; photorealistic tile textures/plane mapping; deployed funded test credits.
Use the release guide for the remaining public-store gates.

## Fresh kitchen acceptance — current batch, 22 November

Keep **http://localhost:7357/** and your normal browser profile. Do not clear
storage or delete older projects. After this build is ready:

1. **Open project**:
   `output/test-projects/RenoVision-fresh-kitchen.renovision.json`. This separate
   project has the authorised original, Modern/Contemporary and Charcoal & walnut;
   no old analysis/designs/credentials.
2. **Save project as** to a new name in Renos. Confirm nonzero size; close/reopen
   that file and check the photo/choices before paid AI. Preserve the empty export.
3. Connect privately in Settings. Switching all four workspace tabs and reopening
   Settings must retain the connection. Browser reload clears its session key by
   design; Android stores credentials separately in its vault.
4. Check New design, whole room and compact palettes. Turn whole room off for
   individual changes; Keep exceptions remain editable when it is on. Other
   photos provide angles/context; the working photo controls the output viewpoint.
5. Confirm one analysis. Observations describe the photo; the editable plan combines
   facts with current choices/instructions. Apply this plan when generating controls
   inclusion in the generation prompt; it does not mean an image already exists.
6. Preview, then explicitly confirm a generation. For quality comparison keep the
   same photo/brief/model. Showcase concept explicitly chooses High and may cost
   more. Record visual changes, not just request success.
7. Save/reopen and check the new version, analysis and choices. Try local splashback
   scale and wall edge extension/Undo. Tiles remain approximate; AI polish is
   optional and separately confirmed.

**Autosave** keeps local room choices/instructions and updates a connected reusable
project file. Imports and completed designs persist when added, even with Autosave
off. Leaving a room saves pending edits; closing a browser during pending work is
not equivalent. Reopen browser file connections after restart. **Backup snapshot**
contains the same project at that moment and does not follow later edits.
**Duplicate project** creates another in-app project. **Restore** adds a copy;
it never merges or overwrites. **Open** resumes identical data or offers conflict
choices. Project files exclude AI credentials and local connection settings.

Browser file verification: compile `tool/verify_browser_file_save.dart` to JS and
serve over localhost in an isolated Chrome profile. It exercises production code
with real origin-private handles: 16 MB write/close/every-byte read-back, then a
no-op stream leaving zero bytes that must fail. It does not establish OneDrive
behaviour. The initial Flutter browser harness stalled loading CanvasKit and is
not counted as passed; native tests do not replace the browser filesystem check.

Source `68527c827a`: **374 tests pass** (80s), clean analysis (13.5s), release web
build (46.9s). Evidence: `output/current-batch-tests-final.log`,
`current-batch-analysis-clean.log`, `current-batch-web.log`,
`browser-file-checks.log` and `current-batch-browser.log`. The actual app Open/Save
path writes the complete kitchen fixture to a real origin-private file, through
a simulated picker in a disposable Chrome profile, then retains the project after
app reload. Deeper workspace automation stalled after entering Refine; native
tests cover those controls, with manual Chrome acceptance still required. Its
attempt is retained in `output/current-batch-browser-workspace-attempt.log`.
No owner key/provider call,
normal-profile modification or new APK is involved. This is not yet acceptance
of the owner's OneDrive/system file picker.

## Prompt enhancement acceptance — after 1.0.17, 22 November

In Chrome, keep the same localhost:7357 address and normal profile. Select an
original room photo, New design and Full room; select style/palette/Keep choices
before analysis for the most specific proposal. Explicitly confirm Analyse once.
The new proposal is enabled automatically only for the exact current photos and
choices. Expand Room observations and design proposal to review/edit or turn it
off. Preview prepared prompt includes current requirements, matching observations
and the enabled current proposal. Generate still requires separate confirmation.

Change palette, style, scope, text or supporting views: an older proposal must
not be sent. Matching photo facts remain available after preference changes;
changed photos/views exclude those facts too. Generation can proceed without a
new analysis. The earlier proposal remains saved for reference. Precise correction
must not inherit a broad proposal even if an inconsistent saved flag is true.
Repeat through first-room setup and Live preview; a Live palette update must reuse
the photo analysis and omit the old proposal without leaving the camera viewer.
Two/three ideas reinterpret suggestions within authorised scope and explicit Keep/
material/palette requirements; they are separate confirmed paid requests.

Existing historical prompts/recipes and approved images must remain unchanged.
Detailed three-option briefs use concise generic guidance when a proposal is
included; optional observations may be excerpted with an explicit marker. The
full analysis stays saved. Written instructions, Keep choices and the edited
proposal are not shortened. An excessively long written brief still triggers the
normal request-size guard before any paid request.
No automatic quality/model change or extra provider call is introduced. Do not
mistake mocked request checks for better real images: compare the same original
kitchen and brief at High quality with/without a proposal, with owner-confirmed
requests. Existing APK 1.0.17 is unchanged and needs a requested rebuild for this.

Source `71336f78f2`: **368 tests pass** (86s), including current/default proposal,
opt-out/edit/save/portable restore, stale palette/scope/view fallback, precise
isolation, guided setup, Live updates and detailed three-concept length coverage.
Analysis is clean (15.5s); release web build passes (101.5s). Evidence:
`output/prompt-enhancement-tests.log`, `prompt-enhancement-focused-tests.log`,
`prompt-enhancement-analysis.log`, `prompt-enhancement-web.log`. All AI responses
in request tests are synthetic; no real provider image-quality claim is made.

Actual 390×844 Chrome at localhost:7357 confirms the final source stamp, kitchen
sample stages/brief/compare, separate practice import and Room/New design controls.
Disposable profile only; normal Chrome data is untouched. Evidence:
`output/prompt-enhancement-browser.log`, `prompt-enhancement-*.png`. A longer
driver attempt could not reveal the deeper prepared-preview control; its log is
retained as `prompt-enhancement-browser-preview-attempt.log`. That interaction is
covered by Flutter tests, not a completed browser end-to-end acceptance check.
No real key, paid request or provider result was used in these checks.

## Requested APK 1.0.17 acceptance

Install the new APK over the existing app; keep its data. Confirm build/version,
projects, original photos, design history, API key and room preferences survive.
Open Help > Sample walkthroughs > Try the kitchen sample flow, step/play through
the original, saved brief, actual result and later board. View the saved brief,
zoom/compare the matching pair, then Try a separate practice project. Confirm
existing work remains unchanged, the practice project reopens, and repeated use
reuses that copy. Test local paint/tiles, version selection and save/share without
an AI key. The board is a different-view exploration, not a precision overlay.

In Settings > AI connection and models, inspect Tester credits. No invitation
is supplied by the APK. Only an explicitly activated HTTPS service and individual
invitation enable live owner-funded requests. Test allowance expiry/exhaustion,
refresh, disconnect and restore separately from personal provider keys. Multiple
ideas consume one design allowance per image; interrupted attempts may consume
allowance. Offline sample replay never consumes one.

Public-store, support-email/privacy and tester-service setup are consolidated in
[the Google Play release guide](GOOGLE_PLAY_RELEASE.md). New private-test evidence
is recorded below. Earlier dated source-only notes describe their original checks;
all completed shared changes are now included in 1.0.17.

Verified package **1.0.17+18**, source `d19f2fd3d2`:
`output/mobile-test/renovision-test-1.0.17.apk`, alias `renovision-test.apk`.
84,941,239 bytes; SHA256
`9E4AE423009A1F6040203ACAD591A91B857381D6468D154FEDFD9D1DBC39E0E6`.
Same package/certificate as 1.0.16; published 1.0.10–1.0.16 remain unchanged.
**363 tests pass** (81s), clean analysis (16.9s), release web (48.1s) and Android
(70.3s) builds pass. Public asset hashes, private-file exclusion, optional camera,
permissions and 64-bit ELF/ZIP 16KB alignment pass. This is development signing,
not a production Play bundle. Logs: `output/release17-tests.log`,
`release17-analysis.log`, `release17-web.log` and
`output/mobile-test/build-1.0.17.log`, `verification-1.0.17.log`.

Actual 390×844 Chrome at unchanged localhost:7357: Help sample original/brief/result/
board, compare, separate practice import, local finishes, reload and tester-access
settings pass. Disposable browser profile only; normal profile/data unchanged.
Evidence: `output/release17-browser.log`, `release17-*.png`.
Android API 37 read-only emulator: final APK update, original/brief/result/board,
compare, practice import, force-stop/restart and invitation settings pass. Existing
projects survived the update. Evidence: `output/mobile-test/smoke-1.0.17.log`,
`rv17-*.png`. This emulator uses 4KB pages; real 16KB runtime and physical S21
acceptance remain open. No provider key or real paid AI request was used.

Mocked tester/gateway tests cover durable quota reservations, duplicate rejection,
expiry/revocation, endpoint/redirect restrictions, stripped upload metadata and
personal provider-key/model/quality retention across trial restart. The HTTPS
service is not deployed or funded; no invitations were generated or sent.

## Android acceptance, then iPhone parity — 22 November

First accept the current v1 workflow on the owner's Samsung S21 after a requested
package. Record actual device/OS/build and observed results; existing automated
tests and Chrome checks do not establish physical-phone or AI image-quality parity.

For Android acceptance and the subsequent iPhone beta, check the same tasks:

- Create a project, capture/import several room views, analyse and produce a
  useful first design with minimal typing. Paid requests require deliberate consent.
- Choose/refine a version, recolour walls, try wall/floor/splashback tile previews,
  compare, save and reopen after process restart. Retain sources and approvals.
- Capture/overlay through Live, zoom/rotate, handle camera/photo permission choices,
  leave/background/reopen and recover from network or save failures.
- Keep rooms, settings and keys after restart; iPhone keys must use persistent
  Keychain storage before claiming parity. Never include keys in portable projects.
- Save/share an image and export/open plain and protected projects; verify copies
  across Android/iPhone preserve photos, versions, choices and local-finish layers.
- Exercise room/version deletion and recovery, permanent deletion when implemented,
  feedback/report delivery, and denied permissions/offline/low-storage cases.

Only after native file/save/share/key gaps and actual iPhone checks pass should
friends receive an authorised TestFlight beta. Feed issues back into the shared
code and recheck affected Android/Chrome workflows. Friends using only iPhones
do not replace the Android testers needed for Google's applicable closed test.
Track public Google Play and Apple release acceptance separately. Native desktop
packaging can follow while Chrome remains current. This update records the plan;
it creates no new APK/iOS build, invites, account or paid request.

## Photo-first designs and local tile previews — 22 November

Wall tile shortcut check: in a Kitchen room, select a splashback region, open
2 Finish and choose Splashback tiles. Check subway/brick tiles and the same colour/
mask, then change pattern/colour. In Bathroom/Ensuite, try Bathroom wall tiles
and Shower wall tiles on separate layers; save/reopen. Powder room/Separate toilet
must omit Shower wall tiles. Keep floor layers and custom surface names intact.
The local preview is approximate; optional Finish with AI is confirmed separately.
Shortcut source `74d73a34cf`: **354 tests pass**, clean analysis (10.0s). Logs:
`output/wall-tiles-tests.log` and `output/wall-tiles-analysis.log`. The shared editor
also passes 320×568 and landscape layout checks at 1.6× text with bathroom controls.
Release web build passes (48.1s), source `74d73a34cf`, at the same desktop origin.
Actual 390×844 Chrome check applies Splashback tiles, saves and reopens with the
surface and subway pattern restored. Evidence: `output/wall-tiles-browser.log`
and `output/wall-tiles-reopened.png`. Public kitchen sample, isolated profile and
simulated project picker; no provider call or real project/settings changes.

At the unchanged desktop address, open a sample room and analyse its photos with
normal confirmation. Leave Use this AI prompt off. Preview a New design request:
matching PHOTO ANALYSIS observations should appear with current requirements.
Change style/palette: facts can remain without another analysis. Change working
image or included views: those old facts must disappear. Precise correction must
not automatically inherit whole-room observations. The optional reviewed prompt
still has its own strict freshness guard. Analysis and generation are separate
paid actions; no paid provider test was run for this source batch.

Open Colours & tiles without AI, tap a clear surface or outline a patterned floor,
then choose 2 Finish. Pick Wall/Floor/Splashback and a tile pattern. Try another
colour on the same selection; expand Tile layout & grout for size/angle/grout.
Compare before, save/reopen, delete a surface/all layers and Undo. Test plain and
protected project copies. Tile patterns are approximate 2D visual guidance.

Finish with AI must save the preview as a new version, select it and prepare one
precise polish with the paint/tile choices. It must not send a provider request.
Reviewing and confirming Generate is a separate step. Check source images and
approved baselines are unchanged. Phone performance, real AI image quality and
physical S21 acceptance await a requested APK and user-controlled paid tests.

Source `b95048b5fc`: **350 tests pass**, clean analysis (11.4s), Chrome release
build (55.5s). Evidence: `output/analysis-finishes-tests.log`,
`output/analysis-finishes-analysis.log` and `output/analysis-finishes-web.log`.
Tests include legacy/tile bounds, every unselected full-PNG pixel and alpha,
protected/plain recipe restoration, matching fact reuse and exclusions, and a
saved single-polish correction without a provider call. Published APK 1.0.16
and its alias still match the recorded SHA256.
Actual 390×844 Chrome smoke: public sample import, region selection, floor/tile
choice, Save finish version and reopen restore the same recipe and rendered
preview. Evidence: `output/analysis-finishes-browser.log` and
`output/analysis-finishes-reopened.png`. A disposable profile and simulated picker
were used; the real user profile, API keys and native file chooser were untouched.

Checklist Proceed follow-up, source `56814171d1`: at a valid low score such as
65%, open Brief %, tick Proceed with the current brief and confirm the primary
button changes from Refine brief to Proceed. Unticking restores Refine. Close
changes nothing; reopen starts unchecked. Proceed opens the normal send dialog
without duplicate readiness guidance (or connection settings when not connected).
No request is sent until Send is confirmed; cancelling leaves review preferences
unchanged. Required photo/correction/partial-scope guards still apply. Tests use
mock AI; the existing APK is preserved. Evidence: `output/brief-proceed-*.log`.
All **343 tests pass**, analysis is clean (12.3s), Chrome release build passes
(57.2s). Actual 390×844 browser checks cover the checked Proceed label, low-score
continuation to connection setup, reopening/reset and Close. Screenshot:
`output/brief-proceed-checked.png`; no normal-profile edits or paid requests.

## Brief readiness source acceptance — 22 November

Source `65936b5efb`; evidence is in `output/brief-review-*.log`. Scoring is local
input coverage and makes no photo-quality or generated-image-quality claim.
All **342 tests pass**, analysis is clean (11.1s) and Chrome release build passes
(61.9s). New regression cases exercise score changes, precise-mode requirements,
refine/cancel, low-score proceed, threshold persistence and preference-write failure.
Actual 390×844 Chrome interaction verifies the indicator in all four tabs, the
checklist/refine route and a live 65%→75% edit. Evidence:
`output/brief-review-browser.log`, `output/brief-65.png`, `brief-checklist.png`,
`brief-75.png`. A bundled public-photo project and simulated picker were used in
an isolated profile; no real project/AI key edits or browser-paid requests.
Normal weights: photo 35, room type 10, goal/scope 25, style 15, palette 10, layout
rule 5. Generic full-room intent earns 15/25 until it has an explicit goal/scope or
both style and palette. Precise weights: image 55, instruction 40, retain-rest 5.
No points require another photo, paid analysis or an API connection.

On the next requested phone package, verify:

1. Brief % stays visible on every tab and updates after edits, style/palette/scope
   changes and mode switches. Tap it for criteria; Close changes nothing.
2. Generate opens one send-confirmation dialog containing coverage guidance.
   Refine brief closes it, selects the suggested controls and resets workspace
   scrolling to the inputs. Wizard/Live return to their relevant controls.
3. Basic valid direction (for example 65%) can proceed without paid analysis.
   An actual photo and a correction/partial edit scope remain required where applicable.
4. Cancel/refine does not send or acknowledge a review. After proceeding at 75%+,
   the coverage reminder is hidden for that room/mode, including after restart.
   Normal paid-request confirmation remains. A drop below 75% restores guidance.
5. A narrow precise edit can reach 100% without styles, palette or room-type input.
   A blank correction cannot be sent. Criteria do not evaluate semantic quality.
6. A failed reminder-preference write must not discard a confirmed result or
   automatically retry/duplicate generation. Other room/mode preferences are separate.

Device preference keys use `settings:brief_review:<roomId>:<mode>` and are not
included in portable projects; restored inputs recompute coverage. Existing photos,
settings, project format and the 1.0.16 APK remain intact. No paid AI in verification.

Lighting/terminology source `50196e8c85`, 22 November: selected lighting and
full-room briefs must request visibly new main fittings rather than only strips.
Keep/protected fixtures and accent-only precise corrections remain authoritative;
analysis reports main fittings separately and does not guess unseen fixtures.
Regional aliases must not turn a basin-only instruction into full vanity replacement
or overwrite the user's wording. Evidence: `output/lighting-review-*.log`.
Real AI image adherence has not been verified; tests exercise prompt scope only.
No paid request or new APK. UI localization/region selection remains proposed.
All **335 tests pass**, analysis is clean (12.7s), and Chrome release build passes
(56.0s). Regression checks cover explicit/full-room lighting replacement, a narrow
accent-only precise correction, protected main lights and unchanged user wording.

Main-navigation follow-up, 22 November, source `75ffe41898`: verify Projects is
first/default, then Explore and Library; Settings is available through the cog
and Back returns to the selected main tab. Existing toolbar, feedback, workflow,
help and enlarged-text tests cover these paths. Evidence is under
`output/navigation-review-*.log`; the published 1.0.16 APK is unchanged.
All **332 tests pass**, analysis is clean (11.2s), release web build passes (56.5s).
An isolated 390×844 browser check confirms visible order, initial Projects, and
cog/Back restoring each of Projects, Explore and Library. No real project edits.

## Workspace source acceptance — 22 November, after APK 1.0.16

Source `c2d523f4c0` passes **332 tests**. Evidence:
`output/workspace-review-final-tests.log`, `workspace-review-final-analysis.log`,
`workspace-review-web-build.log`. Existing APK 1.0.16/older checksums are retained;
the source changes are not yet in a new phone package. No paid provider request
or normal customer-store/profile edits were made.

Analysis is clean (9.9s); Chrome release compilation passes (57.6s). Actual
390×844 browser interaction passes all four tabs, a pinned Generate action,
style pagination and the Full room / Partial switch. A bundled public-photo
project was opened through a simulated picker in a disposable Chrome profile;
this is not native file-picker or S21 acceptance. Evidence:
`output/workspace-review-browser.log`, `output/workspace-*.png`. The desktop
preview serves the new source at the unchanged http://localhost:7357 origin.

Verify on the next requested phone package:

1. Generate stays reachable while scrolling or switching all four tabs. Cancelling
   the same confirmation sends nothing; 1/2/3 choices still control separate requests.
   Save failures keep the result recoverable in Refine; exiting remains guarded.
   Autosave is in More tools and pending/failed local saving remains visible.
2. Style starts with ten common choices; page through every remaining style and
   choose one on another page, then return. All choices remain selected and saved.
   Full palette chooser uses smaller two-column tiles; quick choices remain sideways.
   Check 320px, short keyboard viewports and large text without clipped labels.
3. Full room includes room-appropriate fittings and ordinary surfaces by default.
   Open Included items to see disabled choices and saved Keep exceptions. Switch
   to Partial to edit them and select scope; switch back without losing choices.
   Reopen and restore a portable copy/reuse a saved recipe: extent/choices stay.
   Old records without the new boolean retain the prior broad-design default.
4. Partial must not include broad whole-room initiative; unselected items remain.
   A blank partial/precise request is redirected to its inputs before confirmation.
   Keep layout/walls remains separate and on by default. Explicit Keep/protected
   items override full-room changes; uncertain fixed equipment is not auto-removed.
5. AI observations/prompts initially remain closed. Open them to review/use an AI
   prompt; its saved on/off preference still applies. Manual copy/import is under
   Refine. Ideas contains result review/history, not a required pre-generation step.
6. In Room, include other views and check the input thumbnails/count in analysis
   confirmation. Working photo defines the requested viewpoint; the others provide
   spatial context, not measured reconstruction. No continuous camera video is sent.

Existing help MP4s remain playable but depict earlier control locations. Refresh
the affected clips after layout acceptance; do not claim current-layout video parity.

## Requested APK acceptance — 1.0.16+17, 21 November

Latest package: `output/mobile-test/renovision-test-1.0.16.apk`, alias
`renovision-test.apk`; source `aba3ee136c`; 83,668,388 bytes; SHA256
`F70B4277E1259501EB76D09EB2316E9364B9913E83FC6576A87411840F1245FF`.
**327 tests pass**, clean analysis (8.0s), Android release build passes (20.4s
after asset correction). Version/signature match the existing update path, A icon
is retained, public assets match their hashes, and private files are excluded.
64-bit ELF and ZIP 16KB alignment pass; an actual 16KB-runtime test is still needed.

The initial, unreleased candidate exposed wrong help-video duration/frozen frames
on Android despite passing Chrome checks. All seven recordings were re-encoded
with zero-based constant-rate H.264 baseline video, no audio and fast-start MP4.
Codec, duration and full-decode checks pass before assets are published. The
unreleased candidate stays ignored and is not the delivered package.

Final native evidence: install/update and launch pass on the isolated read-only
API 37 emulator, **4KB pages**, with existing project metadata retained. Native
video advances to a different frame and pauses at 3s, reports 27s duration, seeks
to an asserted 25s position, enters/exits fullscreen and opens Read steps. UI
automation must pause via known control coordinates before dumping its hierarchy:
waiting for UI idle during playback can wait until the entire animation ends.
Immediate software-emulator screenshots can be temporarily black; settled frames
were inspected. This is not physical S21 or 16KB-runtime acceptance. Logs:
`emulator-final-1.0.16.log`, `native-video-state-1.0.16.log`; desktop release build
(66.3s) and actual playback/seek at localhost:7357 pass in `web-smoke-1.0.16.log`.

S21 checklist: install as an update, never uninstall/clear data; confirm existing
projects/photos/versions and AI settings. In a disposable room, test typed deletion,
Undo/Deleted rooms recovery, tap-wall selection, replacement colour, saved layers,
delete one/all and reopen. Test Help play/pause/near-end seek/full screen and Live
capture/overlay. Finish with AI prepares a correction and must not auto-generate.
Real OpenAI/Gemini comparisons, physical camera/share/Gallery and release stress
tests remain manual. No paid requests or real project modifications in packaging.
Evidence is under `output/mobile-test/*1.0.16*`; older published APKs are unchanged.

## Public release acceptance — 21 November review

The user has no Play Console account yet. This audit uses the existing 327-test
baseline; it does not claim a new phone run, signed store bundle, policy approval
or paid provider benchmark. Track the focused gates in CODEX_NEXT_STEPS.md.

1. Decide the production package/signing identity before uploading. The current
   app uses the example ID and debug release key. Export plain/protected project
   files from the existing test app and verify that they open with rooms, photos,
   versions, settings and approvals in the production app. A new package is a
   separate app; a changed certificate cannot simply update the old sideload.
   Keep the old install until transfers are verified; enter API keys separately.
2. Test a current release candidate on S21 and Android 16/16KB: camera/gallery,
   permission denial/cancel, Live capture→analysis→generated overlay→refine, image
   zoom/landscape/compare, 1/2/3 materially different designs and narrow corrections,
   tap-wall replacement colours, persistent layer deletion, room recovery and videos.
   Check real OpenAI/Gemini accounts with explicitly approved spending or manual
   user tests. Default provider protections/refusals must remain effective.
3. Exercise restart, background/process termination, bad/no key, no credit, offline,
   timeout, low storage, larger image libraries and backup limits. Record what
   happens to a charged in-flight job when the app is killed; do not imply durable
   recovery or automatically retry paid generation. Save/open/share plain/protected
   copies and check original/base/branch preservation. Android's destination chooser
   currently appears again rather than retaining a durable overwrite link.
4. Verify a privacy-policy entry and public page, disclosure/consent, final SDK/data
   flow inventory, and the chosen OS backup and permanent-delete/trash retention
   policy. Current backup XML excludes secret preferences only. Retest final merged
   permissions, native 16KB alignment, camera optionality, signing, no bundled private
   settings and Keystore separation. Store signing keys stay outside Git/project files.
5. Report a generated design without leaving the app; verify owner receipt, failure/
   retry state and retention. No automatic private-image/key attachments. Current
   feedback draft/email/browser handoff is not sufficient for this acceptance case.
6. Check fresh-user BYO-key onboarding, price/extra provider-cost clarity, help
   captions and truthful precision/Live wording. Supply valid private reviewer access
   in Play Console; keep secrets out of screenshots/footage. Prepare the icon/banner,
   screenshots, descriptions and app-content declarations against the final UI.
7. Upload a properly signed AAB to internal testing when requested. Address the
   pre-launch report, then run the applicable closed-test/production-access process
   and final production review. Do not treat elapsed tester days as automatic approval.

## Source follow-up acceptance — after APK 1.0.15, 21 November

These features are now included in the requested 1.0.16 APK. Do not uninstall
the current app or clear storage. Tests/recordings use disposable stores and
fictional photos, never Claylands, customer keys or a paid provider request.
Verified source `aba3ee136c`: **326 tests pass**, clean analysis, Chrome release
build (78.9s), Android Kotlin/plugin compile (2m 52s), seven MP4 decode/seek/timing
probes. Logs: `output/review-final-tests.log`, `review-final-analysis.log`,
`review-web-build.log`, `review-android-compile.log`, `walkthrough-final-encode.log`.
`output/help-web-smoke.log` records actual Chrome release navigation/play/pause,
near-end seek, full-screen round trip and Read steps/disposal. It uses an isolated
browser profile and a local static server with byte-range video serving.

1. Rooms and spaces: tap Delete beside a room. Cancel once; enter the wrong name
   (Delete stays disabled), then the exact displayed name. Undo restores the room.
   Delete again, leave/reopen and restore from Deleted rooms. Photos, versions,
   approvals and choices remain. Repeat through plain/protected portable copies.
   This is recoverable deletion, not permanent disk cleanup; active AI blocks it.
2. Start Live with Kitchen and check **Kitchen (Live)**. Change to Bedroom, leave
   and reopen with autosave off; the confirmed type still saves. Legacy stored
   labels are normalized; custom names stay intact. A genuinely unknown type
   remains Unspecified until selected rather than being guessed.
3. Paint walls: tap a clear wall, inspect its highlight and choose a colour, then
   another colour on that same layer. The selection stays and the new colour
   replaces the old one against the unchanged base. Adjust sensitivity for edges;
   outline/erase remain optional. Check walls beside similar-coloured furniture:
   this is a local colour/edge heuristic, not semantic recognition. No key needed.
4. Add a second layer, delete one, leave/reopen, delete all and reopen again.
   Undo is session-only; layer deletion persists. Empty recipes are valid. Clear
   a saved paint version and Save to create an unpainted child from its base;
   originals, parents and approvals remain unchanged.
5. **Finish with AI** saves the preview and opens Precise correction containing
   the wall colours. Previous notes remain and a stale AI-written prompt is disabled.
   No provider request starts from the shortcut. Review, connect a provider and
   explicitly generate when ready. AI creates a new version and may change other
   details: current transport does not enforce the local selection as a hard mask.
6. Help > Sample walkthroughs: play/pause, seek, full screen, background/return,
   Read steps, retry and Back. Seven MP4s show real app transactions with captions
   and tap highlights. AI/camera/native file pickers are explicitly simulated.
   Save & reopen demonstrates export/import against disposable file storage.
   Viewing recordings needs no key, changes no project and sends no photos.
7. Feedback without a destination must state that it is saved locally and not
   sent. Draft/copy still work. Actual delivery awaits the owner's public support
   email/form URL and a receipt test in Feedback setup below.

Re-recording is opt-in. On this Windows machine without desktop symlinks, set
per-process `FLUTTER_WINDOWS=false` and `FLUTTER_LINUX=false` before Flutter
commands. No global feature/Developer Mode setting was changed.
Run `flutter test tool/record_walkthroughs_test.dart --dart-define=RECORD_APP_DEMOS=true
--dart-define=RECORD_FONT_DIR=C:/Users/dbraz/Documents/flutter/bin/cache/artifacts/material_fonts`.
Then run the SDK Dart VM with `--packages=.dart_tool/package_config.json
tool/encode_walkthroughs.dart` (optional clip IDs). Install developer-only FFmpeg
and ffprobe, or set `RENOVISION_FFMPEG` and `RENOVISION_FFPROBE` to their executable
paths. This machine uses checksum-verified portable tools under ignored output,
without a global install. The encoder stages standard H.264 baseline, zero-based
constant-rate 10fps silent MP4s and validates codec/duration/full decode before
publishing. Encode all seven once when changing formats. Test actual Android and
Chrome playback/seek as well. No AI service is involved; FFmpeg is not bundled.
Frames/tools/logs stay ignored in output; only public MP4s/posters/catalog are
bundled under assets/walkthroughs.

Future APK verification must allow public walkthrough assets alongside inspiration
samples, while still rejecting private photos/settings/keys. Published APKs stay
unchanged until another build is requested. Check results are in Feature status.

## Confirmed icon A test package — 21 November, 1.0.15+16

The user confirmed A for now and accepted the offered updated test APK.
**315 tests pass**, icon export passes, analysis is clean, and Chrome/Android release builds pass (138.1/155.1 seconds). Source `ce6b2da600`; 77,161,254 bytes; SHA256 `E0A4487484CE5F595559201C39FAB1265F5033528A6C21856770897A8CCC3E0D`.
Use `output/mobile-test/renovision-test-1.0.15.apk` or `renovision-test.apk`.
The previous 1.0.14 package retains its original checksum/icon for rollback.

Install as an update without uninstalling or clearing storage. Check the olive
green/cream room-and-sparkle launcher icon, then the matching app header/startup
mark. Reopen the existing project and connection settings. If a pinned shortcut
shows an older cached image, check the app drawer and recreate only that shortcut;
do not clear app data. Physical S21 acceptance remains.

The exporter was run with `INSTALL_RENOVISION_ICON=true` following confirmation;
all 40 platform/master files match the reviewed A candidate. Android adaptive/
themed XML and actual compiled olive/cream vector resources are verified. iOS,
macOS and Windows assets are prepared; those native builds are not tested here.
No real photos, app AI requests or private settings were used. Logs are under
`output/mobile-test/` with `1.0.15`, plus `output/icon-a-install.log`.

## Requested 1.0.14 test package — 21 November 2026

**315 tests pass**, analysis is clean, and Chrome/Android release builds pass (111.2/234.8 seconds). Source `ca541ef971`; size 77,151,194 bytes; SHA256
`A81CCF75510CB9C497E7BDA1EF5D69A0D90E9FFEC3C8B76F4CBBCF56BE1F707B`. The package is
`output/mobile-test/renovision-test-1.0.14.apk` (also `renovision-test.apk`).
Application ID and signing certificate match 1.0.13, current icons are unchanged,
and old packages remain for rollback. Install over the existing app; do not
uninstall or clear storage. No real customer images/keys or paid API calls were
used during these checks. Physical S21 and real Chrome acceptance remain.

1. Open the existing project after updating; check original photos, versions,
   approved design and saved API connection. In Design workspace tap **Paint walls
   without AI**. No connection/key is needed. Outline a wall and finish the outline,
   or brush it; erase windows/trim/furniture. Move / zoom magnifies the image.
2. Use **2 Paint colour**, swatches/custom hex and coverage. Compare before,
   Undo/Redo, leave/reopen the editor and confirm its draft. Save paint version:
   a new PNG appears in Ideas, with local-paint settings and no invented AI model.
   Original/selected source and approval stay unchanged. Reopen that version to
   edit layers; use its saved colours/selection if an unfinished draft exists.
3. Save/reopen a plain and password-protected portable copy. Confirm paint layers,
   source/parent links and draft selections survive. Try Save image/Share creation.
   Those export flattened pixels; Save project transfers editable history.
4. Style > Regional influences: combine Modern/Contemporary with Japanese or
   Italian; check prompt preview contains both and retains protected features.
   Moroccan/Indian and existing regional styles are also available. No provider
   request occurs from selecting styles or previewing the deterministic prompt.
5. Help > Feedback: enter an issue/suggestion, leave/reopen, preview/copy it. With
   no configured email/URL, delivery is explicitly unavailable; the draft remains.

Local paint tests cover out-of-mask pixel equality, alpha/indexed PNG handling,
eraser holes, immutable validated layers, no AI calls, drafts, failed-save retry,
plain/protected copies and source/baseline preservation. Phone/landscape layout
checks use 160% text, with fictional stock samples for visual review. Preview
colour is an approximation; sources are limited to 24MP, preview long edge 1000.
Automatic selection, wallpaper and enforced AI-generation masks are not included.
Logs: `output/mobile-test/analysis-1.0.14.log`, `test-1.0.14.log`,
`build-1.0.14.log`, `web-1.0.14.log` and package verification logs there.

## Verified outstanding-items work — 20 November 2026

After credits were renewed, all **296 tests passed**, static analysis was clean
(12.6 seconds), and the final stamped release web build passed (102.4 seconds).
Android **1.0.13+14** is built and verified from source `f69772aaa0`
(145.5 seconds). Package details are below.

`test/outstanding_features_test.dart` covers unchanged repeat Open/restart,
divergent-file choices, failed-import and partial-write cleanup, immutable
recipes/analysis, portable-copy reference remapping, history reuse/refinement
and startup loading/error Retry. Open expects one matching project; Restore
copy remains independent. Legacy records stay readable without guessed recipes;
credentials remain outside project files. Existing AI/backup regressions pass.

Logs: `output/mobile-test/analysis-1.0.13.log`, `test-1.0.13.log` and
`output/outstanding-web-build-final.log`. The preview asset export tool also
passes; all current platform icons remain unchanged. No customer key/photo was
used for automated tests, and no paid app AI request was sent.

Phone acceptance: open the same unchanged file twice, confirm one project;
change the local draft, reopen the older file and exercise Keep local / Open
file as copy. Confirm neither overwrites the other. Generate a version, change
room choices, then use its Saved settings to inspect/reuse/refine it. Confirm
originals and approved baselines stay intact. Legacy versions should explain
when their original structured settings were not recorded.

Six previews remain at `output/design-review/icon-refinements/`. The 1.0.13/14
packages retained the original icons; A was confirmed and applied for 1.0.15 above.
The exporter still defaults to preview output; its install flag was used following
that confirmation. Further icon alternatives remain optional.

Updated after the whole-project audit, 19 November 2026. Use
[feature status](../FEATURE_STATUS.md) for implementation limits and
[next steps](../CODEX_NEXT_STEPS.md) for the ordered backlog. Earlier dated test
instructions have been consolidated here; no real project data was changed.

## 20 November source follow-up testing

These changes are included in the requested 1.0.13 package, after APK 1.0.12.
All 296 local tests pass; static analysis is clean. Coverage checks first/
collapsed AI settings and appearance, model presets without generation, safe
toolbar deletion, separate saved precision counts and three strictly scoped
correction requests from one source. Existing originals/baselines are preserved.
The targeted Chrome runner stalled in its JavaScript test iframe before running
tests; its diagnostic reported a responsive host with no pending network requests.
The isolated runner was stopped. Do not count that browser attempt as a pass.
Final release-web compilation passed in 102.4 seconds; the earlier provider build
also passed its Wasm dry run. These checks do not establish device/browser acceptance.

Provider logs: `output/gemini-analyze.log`, `gemini-regression-tests.log`,
`gemini-web-build-final.log` and `gemini-android-kotlin.log`. Seventeen new tests
cover stateless Google requests, resolution mapping, structured analysis,
separate credentials/preferences, session expiry/reconnection, offline restore,
metadata-only checks, errors/pagination, invalid input and consent-provider changes.
No app key or customer image was used; real Gemini output quality is untested.

Logs: `output/feedback-2026-11-20-analysis.log`, `-focused-tests.log`,
`-regression.log`, `-chrome-tests.log` and `-web-build.log` with the same prefix.
All application AI responses in these checks are synthetic; the brand board was
generated separately with built-in imagegen, without the app key/customer photos.

Next acceptance after the requested package:

1. Settings: AI connection and models is the first card, shows status and opens
   on tap. Home cover/Storage/Appearance use the same expandable-card pattern.
2. Connected OpenAI: try Room design, Quick ideas and Final detail. Check model/
   quality change without an API request. Fresh direct connections prefer available
   2.6 Sunburst/medium; saved choices remain unchanged unless selected explicitly.
   Older saved connections show the previously selected model until Refresh
   available models checks account access. The saved Android key is reused, no
   photos are sent, and a valid saved model/quality is not changed by refreshing.
3. Choose a saved design and tap Delete next to crop/markup. Cancel, delete/undo,
   and try an approved baseline. Originals stay protected and deletion is recoverable.
4. Refine: switch New design / Precise correction without opening advanced help.
   Whole-room mode offers 2/3 ideas; correction mode offers 2/3 scoped variations.
   Each explicitly confirmed result is a separate paid request. Counts save
   independently; old projects keep a one-output correction default.
5. With little/no brief, test a New design for substantial coordinated changes.
   Check architecture, layout and Keep choices, not merely attractive styling.
   For an older reviewed AI prompt marked stale, reanalyse with consent or deselect
   its use to preview the new deterministic brief. Do not silently repeat analysis.

Gemini is integrated in source with its own Google key. Browse OpenAI/Gemini
recommendations without entering a key. Only supported room-image editors are
offered; Claude remains an analysis candidate, not an image generator. The
OpenAI key cannot authenticate with another provider.

Provider acceptance (after a requested APK, using keys entered privately):

1. Connect Gemini: confirm Nano Banana 2.1/2K is the new-account default and no
   photo was sent. Room analysis should show Gemini and its analysis model.
2. Confirm one design, then a refinement and multiple distinct concepts. Check
   references, room layout, saved results and provider/model provenance. Test 1K
   before increasing output resolution; each confirmed request may be billed.
3. Set a Gemini model/resolution, switch to OpenAI with its separate key, then
   select Gemini and Use saved provider key. Choices should return independently.
4. Restart Android: selected provider/key restores without sending photos.
   Chrome keys remain session-only. Remove one key: the other and projects stay.
5. Cancel confirmation, reject an invalid key, check revoked/quota errors and
   verify a failed new-provider connection leaves the current connection intact.
6. Export/open the project: all room work survives; credentials stay on device.

Google integration tests use synthetic responses. A real Gemini output comparison,
S21 Keystore persistence and browser network acceptance need the user's key/device.

Live-room naming check (same source-only follow-up): start through the room
picker with Bedroom and Live design; the room should display **Bedroom (Live)**.
Confirming Kitchen instead should produce **Kitchen (Live)**. The label must
survive a project backup/open and leave originals intact. An explicit custom
rename must stay unchanged when the type later changes. Older Live room / Live
view / Room (Live view) placeholders use the same type-based display; an unknown
type shows Unspecified (Live) until selected. No existing room names are migrated.
Naming verification: 39 focused tests and all 258 regression tests pass; analysis
is clean. Logs use `output/live-room-labels-2026-11-20-` with `focused.log`,
`analysis.log` and `regression.log`. No APK, paid AI request or browser rerun for
this naming-only correction.

## Current source and phone package

Historical text-guide acceptance (included in 1.0.13; recorded replacement above):

1. Tap the information/Help icon, then Sample walkthroughs. Current screen help
   should still be readable and Close should still work.
2. Under Camera & photos, try Choose photos, Take a photo and Live view. Check
   Next/Previous progress, final Done, system Back and returning to the same app
   screen. No actual capture, provider call or project write should occur.
3. Try Design & refine, Image tools & compare, Save & reopen and Compare AI models. The fictional
   kitchen gives example instructions; it is not inserted into your projects.
4. Check small phone/landscape and enlarged system text. Step text can scroll;
   navigation remains available. The catalogue scrolls when needed.
5. The guide must describe Live design as one captured reference and a generated
   still overlay, with separately confirmed updates; it must not imply tracked AR
   or automatic paid generation from each option change.

Walkthrough logs: `output/walkthrough-focused-tests.log`,
`walkthrough-regression-tests.log`, `walkthrough-analyze.log` and
`walkthrough-web-build.log`. Four new navigation/layout tests use disposable
data; six existing Help tests pass in the focused run. No customer data or key used.
All 279 tests pass after the walkthrough change, analysis is clean and the web
release build passed (85.2 seconds). Native Android code was not changed in this
batch; its preceding provider compilation passed. No APK or browser-interaction
acceptance was run for these guides.

Model comparison follow-up: Settings → Recommended design models should say the
shortlist is not yet ranked. How to compare models opens the same manual test
guide as Help and preserves the chosen provider/model/quality when returning.
Reading it sends no photos and runs no paid test. Real-room rankings need actual
comparisons; record time and cost manually as well as design/brief/layout scores.
Enable Use fixed brief for model tests and choose one result. Confirm that the
prepared prompt is sent unchanged on repeat attempts from the same original,
instead of the normal rotating exploration directions. Two/three output requests
must stop before paid consent, keeping the saved room output count unchanged.
Restart: the test switch turns off while the provider/model choices restore.
Logs: `output/model-comparison-focused.log`, `model-comparison-analyze.log`,
`model-comparison-regression.log` and `model-comparison-web-build.log`.
Earlier comparison-stage verification: 36 focused tests and all 283 tests pass; analyzer
clean; release web build passed (83.3 seconds). No live Gemini test, customer-key
use, physical phone acceptance or new APK in this batch.

Previous test APK (superseded by 1.0.17 above): **1.0.16+17**, source `aba3ee136c`:
`output/mobile-test/renovision-test-1.0.16.apk`, alias `renovision-test.apk`.
SHA256: `F70B4277E1259501EB76D09EB2316E9364B9913E83FC6576A87411840F1245FF`.
Size: 83,668,388 bytes. Its application ID/signature match 1.0.15 for an in-place
update. Previous APKs 1.0.15/1.0.14/1.0.13/1.0.12/1.0.11/1.0.10 retain their checksums;
obsolete 1.0.8/1.0.9 were removed during cleanup. Development signing is not
public-release signing. ARM64, optional camera and internet are verified; no
microphone/storage-write permission or private project/credential assets.

Includes all completed 20 November changes: AI settings/models, visible deletion,
multiple precise variations, creative briefs, Gemini, typed Live names, help/model
comparison, project Open/resume/conflicts, generation recipes/reuse/refinement,
startup Retry and Save image / Share creation, plus 21 November local paint,
regional choices, feedback tools, confirmed icon A and all completed room/paint/help
follow-ups. **327 tests pass**, analysis is clean and release builds pass. S21 acceptance
remains. **Do not build another APK unless the user asks.** No real AI calls or
stored-user-data changes during packaging. Confirmed A is applied in 1.0.15.

Start the phone test by installing over the existing app, opening the existing
project and checking its photos/versions/AI connection. Then test Camera → Live
design → analysis/options → generation → immediate overlay without leaving the
viewer → Continue to refine. Also check history captions, compact room choices
and Settings themes/plain/protected project backups. Repeat Open and try Saved
settings / Use these settings / Refine this design. Save and share a creation
from its full-screen viewer. Confirm prompts before paid requests; export and
storage/theme tests need no AI calls.

## Windows preview

```powershell
cd C:\Dev\renovision_ai
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_web_test.ps1 -Release
```

Use **http://localhost:7357**, the same normal Chrome profile, and no Incognito.
Do not replace the profile or clear its storage. A different scheme/host/port or
profile has a different project store. The launcher deliberately avoids Flutter's
temporary Chrome profiles. Settings > App build and saved data identifies the
running build/origin and project/room/image/version counts.

Desktop refresh, 21 November: current source `aba3ee136c` is rebuilt/served at
the same address in release mode (51.2s). All **327 tests pass** and analysis is
clean; eight focused responsive workspace checks pass. The launcher scopes
Windows/Linux feature overrides to its web run
and restores them on exit, so web-only plugin resolution does not need desktop
symlinks or global feature/Developer Mode changes. Flutter resolves packages itself;
no separate unscoped pub get is needed. Omit `-Release` for development debugging.
Release builds use local Flutter engine assets and `tool/serve_web_preview.dart`,
bound only to loopback, with byte ranges for MP4 duration/seek and no-store caching.
The earlier Flutter development server could play a clip but failed near-end seeks;
use the release launcher when testing recorded help. Actual 1440px Chrome verifies
the served source, Settings/help, play/pause, accurate duration, near-end seek,
full-screen round trip and written fallback. Browser tests use an isolated profile.
Logs are ignored under `output/desktop-preview.log`, `desktop-preview-errors.log`,
`desktop-responsive-tests.log`, `desktop-server-tests.log`, `desktop-full-tests.log`,
`desktop-analysis.log` and `desktop-browser-smoke.log`. The server runs
until stopped or the PC restarts; relaunch with the same command/address/profile.
This desktop target is Chrome; native Windows packaging is still future work.
Refresh an existing tab; use Ctrl+F5 if it still shows old code. Keep the same
normal Chrome profile and do not clear site data. The HTTP server serves only
compiled public web files and cannot open the project's private folders or databases.

Check local saving writes/reads disposable diagnostic records in the current
stores. Reopening the same address/profile and confirming real project contents
is the persistence test. Do not interpret a successful diagnostic as a backup.

## Feedback setup

Included in APK 1.0.14: Help > Feedback and Settings > Feedback and ideas.
Choose Report an issue or Suggest a feature, enter a title/details, and review
the report. Build ID/platform can be omitted. Photos, project names/files, logs,
API connection settings and keys are not gathered. Text the user types remains
their responsibility; preview it before copying/sending. No analytics/report is
sent just by opening or typing in this screen.

The draft autosaves separately in `settings:feedback_draft`, outside portable
project exports. Normal Back waits for saves; errors retain text and allow retry.
Clear draft requires confirmation. It does not delete any project/image. A process
kill can still interrupt an unfinished write, as with other local drafts.

**Destination is currently unconfigured.** The owner was asked for a support
email or an existing HTTPS form URL; do not infer one from the private Git remote.
Public release configuration accepts `RENOVISION_SUPPORT_EMAIL` or
`RENOVISION_FEEDBACK_URL` using Flutter `--dart-define` / `--dart-define-from-file`.
Only put public contact details in these definitions, never provider keys.
Use an ignored `.local/feedback.json` for local build configuration if needed:

```json
{"RENOVISION_SUPPORT_EMAIL":"support@example.test"}
```

That example is not a working inbox. Email takes priority if both definitions
are supplied; invalid email, insecure form URL or missing contact leaves delivery
unconfigured. These definitions are read at build/start time; the ordinary preview
launcher does not load that JSON automatically. Supply it explicitly when running
the fixed-origin preview, for example:

```powershell
flutter run -d web-server --web-hostname localhost --web-port 7357 --dart-define-from-file=.local/feedback.json
```

Open email requests a populated composer; the user still sends it in their email
app. Open feedback form opens the configured HTTPS page without report data in
its URL; use Copy report, paste and submit there. There is no generic HTTP POST,
guaranteed browser email-client detection or server receipt acknowledgement.
No client/blocked browser leaves Copy report and selectable Review report as
fallbacks; handoffs retain the local draft and never say feedback was delivered.
Native support is Android; browser support uses normal email/HTTPS links.

Verification: all 305 tests passed, analysis clean (5.0 seconds), Chrome release
build passed (42.2 seconds) and Android Kotlin compilation passed. Logs:
`output/feedback-analyze.log`, `feedback-regression.log`, `feedback-web-build.log`,
`feedback-android-kotlin.log`; source stamp `937602d939`. All launchers were mocked
in tests; no real email/form submission was made. APK 1.0.13 SHA256 is unchanged.
The 21 November request authorises 1.0.14, including these tools; it does not
authorise a hosted service or actual report submission.

Manual acceptance after contact setup: create both report types; reopen the draft;
check diagnostic opt-out and report preview; confirm a real email/form reaches
the owner; test cancellation, no mail client and an offline connection. Verify the
chosen form's anonymous-access setting before promising account-free online use.

## Saving and storage

### Save and share a creation

Open a room photo or design full screen, then use Save image or Share creation.
On Android 10+ (including the S21), Save image writes a PNG copy to Gallery under
Pictures/RenoVision; older Android opens a system file chooser. Share creation
opens Android sharing so the user chooses the destination; the app reports that
the sheet opened, not that a recipient received anything. No broad photo/storage
permission or RenoVision account is needed. Images already remain in the project.

Chrome uses browser file sharing when supported, otherwise requests a PNG download
and says to share it from Downloads. Browser cancellation must not claim success.
If preparation consumes browser user activation, tap Share again or Save image.
Android share copies use a dedicated cache directory, read-only URI grants and a
non-exported provider; old temporary copies are cleaned up on a later share after
48 hours. Only the encoded image is sent, with EXIF/ICC/text metadata removed;
project files, prompts, history and credentials are not attached. Visible photo
contents remain visible. Gallery/download copies exist outside app-local storage.

Acceptance: save one design, find/open the full-resolution PNG in Gallery, and
share it to a chosen personal app. Cancel sharing and confirm the project stays
unchanged. Test free-space failure/retry, phone landscape and enlarged text.
On Chrome, test sharing if offered and the Downloads fallback. To transfer rooms,
editable choices and version history, use Save project instead of image export.

### Working copies and portable files

- Local metadata/preferences/history use Hive `renovision_records_v1`; image
  bytes use the separate `renovision_photo_bytes_v1` box. Existing IDs/boxes remain.
- Imports/captures/generation save new image records immediately. Originals are
  kept separate from generated results, crops and markup references.
- Room draft text/style/mode choices autosave after a short pause. More tools
  holds the Autosave shortcut; compact status shows saving/saved/failure.
- Manual Save now and normal Back/Save and close wait for pending drafts and
  received unsaved results. Save on normal exit still applies with Autosave off.
  Browser/process termination cannot guarantee completion of async work.
- Portable Save project/Save as/Back up project includes all rooms, original bytes,
  saved versions/prompts/approval and current room choices/setup/analysis. New AI
  versions include immutable settings/analysis/model/quality recipes. Legacy,
  manual and editor versions can lack recipes; no history is invented. API
  keys/relay codes are never part of that file.
- Save as can create a separate local project copy, export an image or write a
  project file. Image export is metadata-free PNG; project exports preserve exact
  originals and may therefore contain original metadata as well as private photos.
- Open project preserves portable IDs and resumes an unchanged matching project.
  Conflicting file/local contents offer Keep local / Open file as copy / Cancel.
  Copies never silently overwrite existing work or inherit the original file link.
  Restore copy deliberately remaps IDs, including saved-analysis references.
- Chrome can update a file while its selected handle stays linked during that
  app session. After restarting, reopen the unchanged file to resume/relink it.
  Android uses its system Create/Open Document chooser; the app does not persist
  a writable URI for later same-file Save. Other browsers can download a copy.
- Protected backup files are deliberately not linked to plaintext automatic saves.
  Local autosave continues; create another protected backup to update that copy.

Use Settings > Storage and privacy for the actual native store paths or browser
origin, copyable details, export behaviour and current protection. Changing a
backup destination does not move the internal Hive database. There is no app-managed
cloud sync. Android's OS-managed backup/transfer policy for non-secret project
files still needs an explicit product decision; do not promise those files are
excluded merely because API-key preferences are excluded.

### Plain and password-protected backups

Plain projects use **`.renovision.json`** and are readable without a password.
Optional **Password-protected backup** uses **`.renovision`**, AES-256-GCM with
fresh salt/nonce and PBKDF2-HMAC-SHA256 (600,000 iterations). The header is
authenticated; wrong passwords/tampering fail before records are written.
Current encrypted-file size limit is 100 MB. Native crypto work is off the UI
isolate; browser file preparation can still take visible time.

Passwords are not stored or recoverable. This protects the portable file, not
existing local databases/photos. No existing store was migrated/encrypted.

Safe acceptance on disposable copies:

1. Save a plain and protected copy to chosen locations. Check that a cancel leaves
   local data intact and both filenames/extensions are clear.
2. Open them on Chrome and Android. Cancel the password prompt, then try a wrong
   password; neither should create a partial project.
3. Open with the correct password. Compare every room/photo, prompt, choice,
   history link, approved baseline and setup state against the source copy.
4. Generate no AI image for this storage test. Confirm credentials were not imported
   and that protected files cannot receive a plaintext autosave overwrite.
5. Close/restart and check local project/appearance settings. Repeat with a larger
   disposable project and interrupted/failed writes before trusting a new release.

### Local settings and Git

Ignored: local environment/config files, `.vscode/`, `.aws/`, `.codex/`, `.local/`,
`local_data/`, `private/`, `secrets/`, browser profiles, `output/`, local databases,
`*.renovision.json` and `*.renovision`, signing keys and recovered projects.
Use placeholder-only `.env.example` if setup needs an example.

Ignore rules do not redact tracked history. Two private kitchen output files
remain in commit `f94fe9b`; their local copies were kept when untracked. Review
history before publishing. Source snapshots are not photo/project backups.

## Recovered projects

14 November recovery found earlier tests in cached browser databases under four
localhost ports. It read isolated copies and exported validated portable files;
the original cached databases were not opened by the recovery browser or cleared.

[Latest recovered Claylands kitchen](../recovered_projects/browser-recovery-20261114071955480959/port-61028-project-1.renovision.json)
contains two room views, the saved handleless-bench instructions, Layout protection,
Charcoal & walnut and Contemporary (now labelled Modern / Contemporary). That
historical attempt had no imported design version; later in-app work is separate.

| Other preserved filename in that folder | Historical content |
| --- | --- |
| `port-7357-project-1.renovision.json` | New / Kitchen, one saved design |
| `port-58523-project-1.renovision.json` | Claylands / Kitchen, two views |
| `port-59613-project-1.renovision.json` | Claylands / Kitchen, one view and earlier instructions |

Restore a recovery file once through Settings, then resume its listed local
project at the fixed address. Restore adds a copy; it does not overwrite a newer
project. Keep all these private files and `.local_backups/` ignored.
Images made in another AI website enter Renovision only after **Import generated
AI result**. Copying a prompt does not import the returned image automatically.

## AI test setup

### Independent Android internet connection

1. Open Settings > AI connection and models. Disconnect a laptop relay if needed.
2. Choose **Internet API**, select OpenAI or Gemini, enter that provider's developer
   API key privately, then **Connect over internet**. The check lists models;
   it does not generate an image. Select a supported model/quality shown by the app.
3. Open the room, choose its working image and confirm a separate analysis request.
   Review observations/questions and the editable draft prompt.
4. Choose whether to use that AI-written prompt. Confirm generation separately.
   Each analysis/image request uses the provider account; selecting a theme/style
   or merely uploading a photo does not itself run cloud AI.
5. Restart Android and verify local projects and the saved connection. Disconnect
   and remove API key clears that device's saved key, not project images.

Android encrypts the saved key with Keystore and excludes its secret preference
from OS backup/transfer. Chrome direct mode keeps the key in memory for that
session only, so reload requires re-entry. Projects do not transport credentials.
No shared key is embedded in source/APK. A subscription login is not an API key.
The independent phone routes use fixed OpenAI/Google HTTPS endpoints, reject redirects
and does not silently retry requests. No laptop or `adb reverse` is needed.

OpenAI and Gemini are integrated. Further image providers require an adapter,
capability checks and testing; provider-neutral copy/import works with
any external tool that supports the requested image task. The app does not log
into ChatGPT, Gemini or Claude subscriptions. Historical model/pricing research
in Product notes is dated; it is not a verified current access or cost guarantee.

### Optional Windows relay

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_ai_relay.ps1
```

Enter the key in its hidden terminal prompt, never chat/source. Keep that terminal
open. The launcher uses the key in the process environment and prints a temporary
local connection code, not the provider key. Stop it with Ctrl+C. A restarted
relay changes the code. It is development infrastructure, not a public backend.

Choose Laptop relay in app Settings and use its address (normally
`http://127.0.0.1:8787`) plus connection code. Remembered relay settings are stored
separately from projects in the same device/origin. A startup health check can
reconnect to that relay without sending photos or making a paid generation.
A new code must be entered if it changed. Relay health is not proof of provider
billing/model access.

### Analysis, concepts and refinement

1. Import/capture up to six original views of the same room. Select a primary
   viewpoint and optionally other views as AI context. A saved/approved result
   can become the working image; references must not undo its accepted design.
2. In whole-room mode, set the room/style/palette and goal. Default scope includes
   coordinated surfaces, fittings/appliances, lighting and loose-clutter removal.
   Keep text and optional room-specific Keep/Replace overrides take precedence.
   Request removal of uncertain fixed fittings such as an old wall handset explicitly.
3. Analyse room photos: check the upload previews, model and preferences before
   consenting. A successful analysis saves visible observations/questions and a
   draft; it cannot establish hidden construction, accurate dimensions or a 3D model.
4. Review/edit the draft and select Use this AI prompt if desired. The offline
   fallback is a deterministic template, labelled as such. In the normal workspace,
   changed preferences can invalidate a reviewed prompt; reanalyse or deselect it.
   Separating photo facts from design choices is an outstanding improvement.
5. Select one/two/three concepts and confirm the bounded image request count.
   The app freezes the source and generates sequentially with distinct design
   directions. Each success saves before the next call. Stop after current prevents
   later calls; it does not cancel the request already submitted.
6. Compare options, use one, favourite or explicitly approve it as the baseline.
   Refinement must start from the intended saved version. Select Precise correction
   and enter its narrow correction; broad renovation preferences are not reapplied.
   The correction is still prompt guidance, without an enforced region mask.
7. Check outputs for retained architecture/viewpoint, requested appliances/flooring,
   useful storage and unwanted changes. For three options, compare material/form
   choices, not only decorative plants. Exact-byte duplication is flagged; meaningful
   difference is not yet scored automatically.

Working image copies have orientation baked, unnecessary metadata stripped and
longest side limited to 2048 px for API transfer; stored original bytes stay intact.
Exact input limits/model choices live in source and depend on the configured
adapter. Check actual account usage to compare model cost/time/quality; no new
benchmark or paid call was performed by the audit.

### Errors and progress

Progress reports stages and elapsed time, not invented percentages. Preparation,
provider response and local storage are separate waits. A storage-only retry
reuses the received result/analysis instead of billing another request. Keep that
screen open until saved. Normal navigation guards pending work, but a killed app
can still lose a response while the provider completes/bills it. Check usage before
retrying an uncertain timeout. In-flight paid-job cancellation/recovery is absent.

## Android target and device acceptance

The S21 is the primary real-phone test so far. A work-policy restriction previously
blocked APK installation; the user resolved it and successfully installed/tested.
Install a requested new APK as an update with the matching ID/signature. Do not
uninstall/clear data as a routine update. This app does not require Play Store
publication for private APK testing.

Use **1.0.12** for these fixes; testing the older 1.0.11 cannot establish their
acceptance. Checklist:

- Existing projects/images/settings survive upgrade, normal exit, restart and
  background/resume. Plain/protected file pickers behave as documented.
- Camera/gallery cancellation and permission denial leave no empty/partial room.
  Camera preview/capture remain usable in portrait/landscape and after resuming.
- Live design stays in viewer after generation, waits for camera readiness,
  overlays automatically, toggles camera/design and preserves overlay across keyboard
  changes. Continue to refine opens the saved result in precise mode.
- Room-first Camera/Photos/Live paths carry room name/type/style/palette. Generic
  live names display the confirmed type; custom names are unchanged.
- Before/after, opacity overlay and zoom work without generating more images.
  Moving the camera does not imply a correctly tracked/reprojected design.
- Crop corners/edges/move; pen/shapes/arrows/text/colours/select/undo; generated
  references remain separate from originals. No claim of enforceable masks.
- Long version captions sit below previews. Use design/favourite/approval/delete/
 undo preserve baseline/history; thumbnail strip labels remain readable.
- All themes save/restart without changing room palette or draft, and all tabs
  remain readable with enlarged system text, keyboard and landscape.
- Check TalkBack/semantics, colour contrast and tap-accessible help. Phone hover
  is not a sufficient way to expose a required action.

## Verification

Requested 1.0.13 package: **296 tests passed**, `flutter analyze` clean,
web/Android release builds passed in 102.4/145.5 seconds. Logs under
`output/mobile-test/`: `test-1.0.13.log`, `analysis-1.0.13.log`, `build-1.0.13.log`,
`metadata-1.0.13.log`, `signing-1.0.13.log`, `manifest-1.0.13.log` and
`share-paths-1.0.13.log`; web log `output/outstanding-web-build-final.log`.
The verifier resolves Android's shortened XML resource path, checks the restricted
share directory, matches the 1.0.12 certificate, excludes private-file assets and
checks the final source fingerprint before publishing the versioned/latest APKs.
Physical share/Gallery/camera and interactive Chrome acceptance remain manual.

Previous 1.0.12 package: **249 tests rerun and passed**, `flutter analyze` clean,
Android release build passed in 139.1 seconds. Logs and package verification are
private under `output/mobile-test/`: `test-1.0.12.log`, `analysis-1.0.12.log`,
`build-1.0.12.log`, `metadata-1.0.12.log` and `signing-1.0.12.log`.
The preceding web build passed in 54.9 seconds; its settings-batch logs remain
under `output/`. Web compilation was not repeated for the package-version change.

The audit rendered eleven fictional-fixture screens with correct view metrics,
fonts and fake AI/file services: Projects, Rooms, room chooser, Explore, Library,
Settings, four phone workspace tabs and desktop workspace. One temporary render
test passed; PNGs/log are ignored under `output/design-audit/` and
`output/design-audit-render.log`. No customer store, real API or camera was used.
These captures establish layout only, not interactive browser/device acceptance.
When adding layout checks, set both view physical size/devicePixelRatio and
surface size where required; changing test surface size alone can leave an
incorrect MediaQuery width and exercise the wrong adaptive layout.

The subsequent workspace cleanup removed generated Android/test/tool caches and
superseded logs while retaining the then-current web build, settings/audit logs,
current/rollback APK verification records and all project/recovery/browser data.
The loose audit fixture generator and old source/tool snapshots are retained in
one SHA256-verified archive under `.local_backups/archives/`. Cleanup changed no
application code, so checks were not repeated solely for cleanup. The subsequent
requested APK build reran tests/analysis and recreated the necessary caches.

For implementation changes, run relevant tests and the required suite/analyser:

```powershell
flutter test
flutter analyze
flutter test --platform chrome test/workflow_test.dart test/editor_test.dart
flutter build web
```

Tests use synthetic fixtures/disposable stores. Broader manual coverage remains:
provider adherence/diversity, real Chrome/S21 choosers and lifecycle, large image
libraries, memory/timings, low storage/corruption and interrupted-request recovery.
The audit is not a claim of exhaustive device or AI-quality validation.
