# Renovision next steps

Updated 16 November 2026 (Australia/Sydney). Keep this as the single current work
list; update existing documents rather than creating one file per idea.

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
| Camera preview, snapshots, refine | Still-camera entry point exists, Android unverified | Embedded preview, saved camera composites and same-view overlay missing; tracked AR later |
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
- Camera path: verify existing still capture, then an explicitly approximate
  same-view comparison overlay. Moving-camera whole-room AR is separate future
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
