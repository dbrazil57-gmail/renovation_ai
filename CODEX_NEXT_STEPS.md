# Renovision next steps

Updated: 14 November 2026 (Australia/Sydney).

## Current direction: local workflow and look/feel, no key required yet

Newest style/autosave batch: tickable Modern, Contemporary, Classic, Minimalist,
Scandinavian, Coastal, Hamptons, Industrial, Rustic and Japandi choices, plus Other
free text. Keep existing layout and walls is an explicit preference. New rooms
default to Explore ideas; older records preserve the prior precision default.
The local prompt builder now uses these choices, handles "nothing to retain"
without a contradictory retain clause, and suggests Explore when a precision
request mentions multiple room elements. It does not change mode automatically.
A prepared-prompt preview is explicitly labelled as local/template-based.

Room text/style/mode drafts autosave after a short pause. Saving, Saved locally
and failure states are visible. Save instructions remains a force-save/retry;
normal back navigation flushes pending changes. Browser shutdown is best-effort,
not a guarantee of durable browser storage. See STORAGE_AND_SAVING.md for current
storage and later Photos/Gallery / Save as / design-board export actions.

Style/autosave validation: all 63 VM/widget tests pass. Coverage includes failed
saves and retry, queued edits, style controls, save-before-Back, backup restoration
and reopening isolated Hive storage with saved preferences. Analysis and the web
release build pass. No live AI calls or existing browser data were used.

Manual Chrome check after hot restart of the existing session/address:
1. Open a room, scroll to AI instructions, tick Modern and Contemporary and enter
   an Other direction. Choose Explore ideas for a whole-room renovation.
2. Enter changes and protected features, pause and check Saved locally.
3. Expand Preview prepared prompt; check styles, palette and layout restrictions.
4. Edit again and immediately use Back. Reopen and check the draft survived.
5. Back up the project and restore a separate copy; verify preferences and photos.

The user's supplied kitchen/dining board is a target for future presentation:
separate A/B designs, room-wide renders, material swatches and a plan inset.
Keep the reference image unchanged and do not infer verified measurements or
permission to alter unrelated architecture from the reference.

Latest user report: palette not visible in the room/design screen. The visibility
fix moves the card above the gallery and shows directly selectable palette
swatches even before a preference is saved. The full chooser and existing saved
selections remain. Hot restart the existing app session to load these changes;
verify the palette is visible before scrolling to photos.

Palette visibility checks: all 56 tests pass, analysis is clean and the web build
passes. New tests
check swatches are visible when a room opens, direct selection persists, and the
horizontal strip works at phone width. Real Chrome interaction still needs the
user's check after restarting the existing Flutter session.

The user also wants AI to write an editable prompt, then generate multiple design
options, select one and improve it. This is a future feature request. See
[AI_DESIGN_WORKFLOW.md](AI_DESIGN_WORKFLOW.md) for the requested flow and proposed implementation
sequence. Current prompts are still templates and generation returns one image;
do not describe multiple input photos as multiple returned designs.

Newest palette batch: seven coordinated presets plus No palette preference.
After selecting new room photos, a chooser previews the uploaded room and colour
swatches. Existing rooms have Colour palette > Change palette in the workspace.
Each room stores a stable preset ID; backup/restore preserves it. Copied and
in-app AI prompts include names, surface suggestions and hex values, with scope
limited to requested edit areas in Precision mode. Existing photos, approvals
and historical design prompts are not recoloured or rewritten.

Palette manual Chrome check: create a test room, select photos, choose a preset
and confirm Use palette. In the room, change the choice, copy a prompt, verify
its COLOUR PALETTE section, then reopen and back up/restore the room's project.
Test No palette preference and cancelling the chooser. No API key is required.
Exact rendered AI colour adherence is not claimed without a live provider test.

Palette batch verification: all 54 tests pass, analysis is clean and the web
release build passes. Tests cover phone-width selection, cancellation, draft
preservation, copied and in-app prompts, storage reopen and project restoration.
The existing Chrome test-runner limitation remains; real browser interaction and
AI colour adherence still need manual/live tests. No paid AI calls were made.

Newest batch: multiple photos per room. New-room import accepts multiple files;
the workspace Room photos card adds views later (six total), previews each, and
saves a primary-view choice. Other angles can be enabled/disabled as AI context.
The active working image is sent first, followed by supporting originals from
that same room. Approval remains separate, and an approved design still opens
first. Each result records supporting image IDs as well as its main source.

Test in Chrome after hot restart: add 2–3 photos to one room, select a primary,
toggle context, reopen the room, back up and restore a copy. Confirm all views
and the primary choice survive, with original bytes and approvals unchanged.
When eventually testing AI, restart the local relay and reconnect so it advertises
multi-input support. Review all images in the send-confirmation dialog.

Multi-view checks: all 46 tests pass, static analysis is clean and the web build
passes. Tests include
multi-image relay ordering/sanitisation, recording the primary/supporting inputs,
gallery selection, save failure, reopening photo records, backup/restore with
fresh IDs and reading old one-photo/version-1 backups. No paid calls were made.

Backups now export schema version 2 and still accept version 1. Multi-input AI
has simulated provider tests; actual consolidation quality needs a live API test.

Latest completed batch: project/room header pencil controls rename records without
changing identifiers or saved images. Project titles and backup names refresh
immediately. Version history now labels Favourite, Passed, Awaiting review and
Approved baseline; the review menu supports Mark as passed / Return to review.
Returning to review does not approve the design or mark it as a favourite.

Rename/review checks: all 37 tests pass and analysis is clean, including name
persistence after reopening Hive files, keeping instruction drafts during a
rename, and returning a passed design to review at phone width.

To test after the download/backup checks below, hot restart the existing session:
rename a project and room, reopen them, and confirm that photos/history remain.
In a room's history, use the three-dot review menu to return a passed idea to
Explore. Confirm that baseline approval stays unchanged.

See [FEATURE_STATUS.md](FEATURE_STATUS.md) for implemented, unverified and deferred
features. The user wants to improve the app before setting up a developer API key.

The previous local batch added Download image in rooms, Back up project inside projects,
Restore project backup on Projects, current-image badges and optional collapsed
AI controls. Restore creates a new project with fresh IDs; originals and existing
projects are preserved. File transfer targets Chrome and Android; Android native
chooser behaviour is not yet verified.

Next manual check in the existing Chrome session:

1. Open the saved test room and use Download image. Locate the PNG in Downloads.
2. Open the project and use Back up project. Keep the .renovision.json file.
3. From Projects, restore it as a copy and check photos, versions and approval.
4. Confirm the original project is still present and unchanged.

Backups include original image bytes/metadata. Download image prepares a separate
metadata-free PNG. Prototype backup limits are 64 MB of photos / 100 MB file.
Do not describe a browser download as a verified saved backup until the user
checks the file and completes a restore.

Latest local-batch checks: all 32 tests pass and `flutter analyze --no-pub` is
clean. `flutter build web --no-pub --no-web-resources-cdn` passes. Tests cover exact bytes, branch/approval remapping, repeated imports,
photo integrity validation, failed-restore rollback, and the transfer controls.
No paid AI calls were made; tests use disposable records and synthetic images.

## Latest direction: in-app AI testing

The user has requested in-app generation to test the actual workflow. This
supersedes the earlier manual-only/deferred-AI direction for private testing.
They currently have a subscription/login, not a developer API key.

- Added an optional local OpenAI relay and in-app connection/generation UI.
- Key entry is private in `tool/start_ai_relay.ps1`; Flutter receives only a
  temporary relay code in memory. See [AI_TEST_SETUP.md](AI_TEST_SETUP.md).
- The app previews the selected image/prompt and requires Send to OpenAI before
  any provider request. One low-quality image is requested with no auto retries.
- Results save as new branches with source image ID, prompt, provider/model and
  request ID. Existing originals and approved baselines remain intact.
- Simulated provider tests cover consent, failure and local-save recovery;
  actual provider calls require the user's API key and are still unverified.
- Latest validation: `flutter analyze --no-pub` is clean and all 25 tests pass.
  `flutter build web --no-pub --no-web-resources-cdn` passes. The launcher passes
  PowerShell syntax validation. No paid API calls were made.
- Next: help the user obtain API access, connect the local relay, and test one
  Claylands room edit. Do not request that they paste a key into chat or source.

Use RENOVISION_PROJECT_BRIEF.md as the product requirements. Preserve the existing
Hive box names and photo IDs. Never clear browser storage to diagnose missing data.

## Next work, in priority order

1. Complete the manual Chrome checklist below using the user's existing test
   example. Record the project/room, attempted action, expected behaviour and
   actual result. The example has not yet been inspected by Codex.
2. Investigate Chrome automated-test bootstrap failures without clearing user
   storage or changing the installed Flutter SDK as an incidental cleanup.
3. Add download/share for the selected image so app-created crops and sketches
   can be attached during manual AI handoff. Preserve originals; sanitise copies
   intended for sharing and explain that an external AI receives uploaded photos.
4. Add project export/restore with format validation and a non-destructive import
   strategy. Verify round trips with images, branches, approvals and room memory
   before describing the feature as a backup solution.
5. Distinguish reference images from generated results and record source image,
   provider and edit context. Retain compatibility with existing saved records.
6. Add region/mask selection and saved annotation history, then assess compositing
   and outside-region change warnings. Do not claim precision guarantees.
7. Resolve Android command-line tools/licence setup, then test on emulator and
   a real phone: import, camera, permissions, gestures, interrupted picker flows
   and persistence after restart. Chrome testing remains the first priority.

Work in coherent batches. Run analysis, relevant tests and a web build after code
changes. In-app AI is now opt-in for private tests. Keep payments, public hosting
and store release work deferred.

## Completed batch

- Added an optional approvedDesignId to room records; legacy records use the original.
- Rooms open at their approved baseline. Viewing or importing another version does
  not approve it automatically. Users can approve a selected version or return
  to the existing baseline.
- Unfavouriting returns a version to pending review; Pass remains rejection.
- Fixed the name dialog's text-controller lifetime during its closing animation.
- Cached the editor's decoded source, cloned it for saving, explicitly cleared EXIF
  from derived references, started selections at pointer-down, and added sketch undo.
- Added isolated storage/reopen tests and browser-compatible UI/editor tests.

Original source snapshots are in `.local_backups/before-baseline-fixes/`.
These are code snapshots, not backups of the user's projects or photographs.

## Manual Chrome acceptance

Use the existing running app's browser profile and address when checking existing
data. A different browser profile or origin (including port) has separate storage.
Hot restart the existing Flutter session to load Dart changes if it is still open.

1. Confirm the existing project, room and photos are still visible.
2. In a separate test room, import a JPEG and verify zoom/pan and the original.
3. Crop and sketch a reference. Check selection position, undo and saved versions.
4. Select a design and choose Approve as baseline. Leave and reopen the room;
   it should reopen that design. Selecting another version must not approve it.
5. Return to approved baseline, then try approving the original again.
6. Save an idea, open Library, remove its favourite in the workspace, and confirm
   it returns to Explore rather than becoming rejected. Test both swipe directions.
7. Save instructions, copy a narrow precision prompt, manually generate externally
   using a photo already available as a file, and import the result as a branch.
8. Compare original/result, then test the layout at a narrow browser width.

## Still incomplete

- Verify real Chrome image download and project backup/restore, then Android file
  chooser behaviour. These now have implementations; browser persistence still
  depends on profile/address and site storage.
- Explicit reference/result types and richer annotation history. In-app AI results
  now record source image ID, parent, provider/model and provider request ID.
- Masks, structured room locks, compositing and outside-region change detection.
- Storage failure/recovery UI, import validation and Android lost-picker recovery.
- Android test setup: command-line tools and licences were unresolved at assessment.
- Automated Chrome tests use disposable memory, so they do not verify real browser
  storage persistence. VM storage tests verify Hive file close/reopen separately.

No AI processing, payment or deployment was performed during the baseline-fix
batch. The project folder was not a Git repository at assessment; do not claim a
milestone commit exists. The later in-app AI batch is described above.

## Validation in this batch

- `flutter analyze --no-pub`: clean, no issues.
- `flutter build web --no-pub --no-web-resources-cdn`: passed, rendering assets
  bundled locally. This verifies compilation, not interactive browser behaviour.
- `flutter test --no-pub`: all 14 tests pass, including real Hive file reopen,
  UI navigation/approval/favourites, a phone-width layout, crop and sketch saves.
- Chrome automated tests were attempted with JavaScript and WebAssembly. Both
  stalled during Flutter browser bootstrap before running test cases; the tool
  reported `Iframe JS Execution Stalled`. Both processes were stopped. Do not
  report these as browser test passes. Manual Chrome testing remains required.
