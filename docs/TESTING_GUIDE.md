# Testing and storage reference

## Current phone package: APK 1.0.10+11

Install `output/mobile-test/renovision-test-1.0.10.apk` over the existing app
without uninstalling. Source `a18caebdc6`; package remains
`com.example.renovision_ai` and signature matches 1.0.9. All 205 tests pass,
analysis clean; universal release APK built and verified. Old APKs retained.
Camera hardware optional, no microphone/storage write permission, only bundled
app sample assets. Physical S21 camera and provider acceptance remain manual.

## Home cover — included in APK 1.0.10

Start with an existing saved project: the first banner should show the bundled
fictional coastal living room, not the last-opened room's original photograph.
Continue should still open the saved room. Choose the banner's wallpaper control
or Settings > Home cover; select an app example or use My projects to choose a
saved photo/design. Reopen the app and visit another room: the chosen cover must
remain. Use default returns to the app sample without deleting any photos.
Check small screens/large text, cancel and save-failure retry. A deleted/missing
design should fall back to the sample. Cover preferences are saved only on this
device/profile, separately from project exports and AI credentials. This update
does not include any real room photo in the shipped assets.

## Camera renovation prototype — included in APK 1.0.10

These controls require APK 1.0.10 or later. Chrome uses the same localhost address/profile; allow camera
access (remote browser addresses require HTTPS). Camera tests use synthetic
photos/fake feeds; real S21 and normal Chrome acceptance remain to be done.
205 VM/widget tests pass, including 14 camera tests; analysis is clean and the
web release compiles. An isolated Chrome test run stalled during Flutter startup
with browser runtime errors before any test ran, and was cancelled. Do not treat
the VM tests or successful compile as physical camera or browser acceptance.
Android `:app:processReleaseMainManifest` passed without building an APK. The
merged manifest permits camera use, keeps camera hardware optional, and contains
no microphone or external-storage write permission for this still-image flow.

1. Take photo from a project: embedded preview, Capture photo, Retake, Use photo.
   Cancel and denied permission must preserve existing work; gallery still works.
2. Open a room; choose the **Camera renovation view** tool beside crop/markup.
   Live preview should open without an AI request. Capture new view saves a new
   room photo, without replacing the original, primary photo or approved baseline.
3. Choose **Design saved view**. Check Working from shows the chosen View, then
   analyse, review the brief and confirm paid generation through the usual flow.
   Choose a result and go Back (or use the camera tool) to return to comparison.
4. Compare reveals that capture and its design with the slider. Live view ->
   Enable manual overlay -> Align original: match the real camera to the ghost
   photo, keep still, then Show design and adjust opacity. It is approximate,
   with no pose tracking; moving changes perspective and breaks alignment.
5. Rotate, background/resume, deny/reallow camera and leave/reopen the screen.
   Resources should release, Retry should recover, and overlays stay off until
   explicitly enabled again. Preview must not stretch or request microphone use.
6. Retry a failed capture save locally, without recapturing or calling AI; Back
   must offer explicit discard while unsaved. Six saved photos prevent additional
   captures, while saved-view comparison/design still work. Linked project files
   flush on exit; Settings is available to reconnect/change file destinations.
7. Save/Open project and restart: captures, generated versions, prompts/settings
   and recorded source links remain. AI credentials remain on this device. Older
   imports without source provenance, crop/markup descendants and deleted results
   are not overlay choices; use a full saved photo for the camera design workflow.

The live feed stays on device. Only an explicit, separately confirmed analysis
or generation sends a saved photo. No automatic video upload, instantaneous
regeneration, tracked AR or composited-image export is implemented. Unfinished
captures exist in memory until saved; force-killing during a failed save cannot
recover them. Existing images/files are retained.

Focus Canvas / chosen B is included in **APK 1.0.9**. It changes the home
and workspace layout. Use Room for photos/analysis/source/approval, Style for palettes/style/Keep
choices, Refine for instructions/generation, and Ideas for history/import/delete.
The image, crop/markup/compare/refinement tools and version thumbnails stay visible.
On desktop, controls sit beside the canvas; on phone they sit below it. Advanced
edit mode and protected-feature fields are expandable in Refine. Autosave remains
in More tools; local status remains visible. Check drafts and active AI work survive
section switches, and restart retains photos, approvals and AI connection settings.
Physical S21 and normal-browser visual acceptance remain manual checks.

Previous phone test package: **1.0.9+10**, source `d67b148d3f`, at
`output/mobile-test/renovision-test-1.0.9.apk`. Install as an update without
uninstalling; package identity is unchanged and signing matches 1.0.8.
185 automated tests pass and analysis is clean. The post-analysis chooser
offers 1 design / 2 ideas / 3 ideas without starting generation. Review the brief,
continue to final options and confirm the separate paid request count. Generate,
use a chosen result, then reopen the project to verify settings and versions.
Real-camera, provider quality and phone acceptance remain user checks. The
selected B layout, Autosave shortcut and stronger distinct-concept briefs are
included. Further crop/markup layout changes and live-camera overlays are not.

Consolidated 15 November 2026. Detailed instructions formerly spread across
three files. Run commands from the project root, `C:\Dev\renovision_ai`.
See [current next steps](../CODEX_NEXT_STEPS.md) for what to test next and
[feature status](../FEATURE_STATUS.md) for implementation and verification limits.
This documentation cleanup did not rerun app tests or provider calls.

- [Saving and storage](#saving-and-storage)
- [Recovered projects](#recovered-projects)
- [AI test setup](#ai-test-setup)

## Saving and storage

### Local test settings and Git

Keep machine-specific values in ignored environment files, `*.local.json` /
`*.local.yaml` configuration or private local folders. `.vscode/`, `.aws/`,
`.codex/`, `.local/`, `local_data/`, `private/`, `secrets/`, generated `output/`,
project exports and local databases are excluded. `.env.example` is allowed for
placeholder-only setup instructions; never put a real key or pairing code in it.
Application source, synthetic tests and the fictional bundled inspiration assets
remain eligible for version control.

The remembered AI connection lives in browser storage, separately from portable
project files. Exported projects still contain private photos, original metadata,
instructions and design history; keep their `.renovision.json` files out of Git.
Ignore rules do not protect files already tracked or erase historical commits.
Two private kitchen output files were untracked without deleting local copies;
they still exist in old commit `f94fe9b`. Do not treat this cleanup as historical
redaction. No history was rewritten and no remote upload was performed.



User preference, 14 November 2026: normal work should save automatically inside
the app, with familiar options to save a copy to a chosen location or photo library.

### Saving investigation and recovery

The user's exact latest kitchen instructions, Layout protection, palette and two
photos were recovered from the cached localhost:61028 database. Other saved tests
were found at localhost:7357, :58523 and :59613. Their validated portable copies
are linked in TESTING_GUIDE.md#recovered-projects. The recent Claylands attempts had no imported
design versions. Images generated in ChatGPT require an explicit import back into
Renovision; only in-app AI results can be saved automatically by the app.

The previous `flutter run -d chrome` instructions allowed a changing localhost
port and a Flutter-managed browser profile. The installed Flutter SDK creates a
temporary Chrome profile and best-effort caches/restores it. Its teardown can
delete the directory even when supplied through a custom user-data-dir flag, so
the new launcher deliberately uses web-server and a normal user-controlled Chrome
profile instead of pointing Flutter at a permanent profile folder.

Use tool/start_web_test.ps1, then open http://localhost:7357 in normal Chrome.
The same scheme/host/port and browser profile must be reused. IndexedDB separates
data by origin ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API)).
Settings now displays build/address/counts and can write/read small diagnostics
in both existing Hive boxes. A check only proves session writes; reopening the
same address/profile is the durability test. No original box names were changed.

### Current implementation

New file workflow (16 November): use **Projects → Open project…** to load a
`.renovision.json` file. **Save project** / **Save project as…** appear in project
pages, room toolbar save controls and guided setup. The file includes all rooms,
originals, versions, prompts/analysis, room choices and setup progress. Open adds
a separate local copy, preserving existing records. Chrome can update a chosen
file and Autosave changes while linked. After restarting, Open project reconnects
the file destination; browser-local saving continues separately. A failed file
save keeps local work, and the status distinguishes local versus file saving.
Other browsers/native providers may download a copy rather than retain a handle.

New rooms use **Photos → Direction → Analysis/review → Final options**. Finish
later saves progress and Continue resumes it. Existing rooms have a toolbar
button to reopen guided setup. No AI request runs merely by advancing a step.

- Room workspaces show Autosave and save status beneath the palette. Open the
  room Settings gear for Save now, Save and close and Save as. Restore and project
  backups are also in global Settings. The Autosave preference persists in the
  existing app records box. It controls debounced room edits; imported photos,
  palette/review choices and created design versions still save when added.
- Save on exit stays enabled even with Autosave off: normal Back and Save and
  close await pending room writes and stay in the room if saving fails. Closing
  or refreshing a browser tab with pending work triggers its standard warning
  and a best-effort flush. Browser/process termination cannot guarantee async
  saving ([beforeunload limitations](https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeunload_event)).
- Save as > New project copy asks for a name and opens a separate full project
  copy with remapped IDs, originals and history. Save as > Image file exports a
  metadata-free PNG; Project backup file preserves exact original bytes/history.
  Pending room edits save before copy/export. Chrome uses a location chooser
  when supported; other browsers fall back to downloads. Android uses its existing
  system save flow. Real file chooser interaction still needs manual testing.
  ([Browser picker reference](https://developer.mozilla.org/en-US/docs/Web/API/Window/showSaveFilePicker)).

- Hive stores project/room metadata, preferences, prompts and version history.
  Image bytes are in a separate Hive box. Existing IDs and boxes are retained.
- Imported room photos and created design versions are saved when added. The
  original stays separate from crops, markup and generated images.
- Palette and review choices save when selected. Room text/style/mode preferences
  now autosave after a brief pause, with Saving / Saved locally / Save failed
  feedback. Normal back navigation waits for a pending draft save.
- Save now replaces the older Save instructions action for immediate save/retry.
- Renovation scope checkboxes, flooring notes and other removal details autosave
  with the room and are included in backups. Legacy style selections remain
  readable through the combined Modern / Contemporary control.
- Room type and item Keep / Replace choices autosave and are included in backups.
  Type changes preserve inactive preferences but exclude them from current prompts.
  Legacy appliance scope selections remain readable; no existing data is migrated.
- The latest room analysis stores observations, questions, the original AI draft,
  model/request ID, input photo IDs and preferences. The edited prompt and its use
  selection autosave separately. Project backup preserves both and remaps photo
  references on restore. Older rooms/backups without these optional fields work.
- Browser storage belongs to a browser profile and app origin. It is not a normal
  Downloads folder and must not be described as a permanent backup. Browser
  shutdown cannot guarantee completion of unfinished asynchronous writes.
- Download image makes a separate metadata-free PNG. Chrome uses its Downloads
  flow; Android uses a system save chooser (device verification outstanding).
- Project backup keeps original bytes plus history/preferences in a portable
  file. Restore creates a separate project copy, with fresh IDs.

### Later familiar save actions

1. Save to Photos / Gallery on Android, with explicit user action and platform
   permission handling. Do not put all private originals in the public gallery.
2. Add share-sheet export and verify the new Save as location chooser on actual
   Chrome/Android devices. Keep internal working copies and version links intact.
3. Save a design board containing selected options, materials and palette swatches.
4. Backup reminders and verified restore checks; optional automatic backups to a
   user-chosen destination once permissions and failure handling are tested.
5. Optional cloud sync only later, with account, consent and conflict handling.

For a larger Android library, move large photos to app-private files behind the
repository interface and keep metadata in a local database. No SQLite migration
or storage replacement is needed just to add these controls. Any future migration
must preserve existing originals, identifiers, approvals and export compatibility.

## Recovered projects



14 November 2026: saved data was found in Flutter's cached browser profile under
four different localhost ports. A new address has a separate IndexedDB store.
Recovery read isolated copies of those databases and exported validated backups.
The original cache was not opened by the recovery browser, changed or cleared.

Start with this file for the latest Claylands test:

[Latest Claylands kitchen backup](../recovered_projects/browser-recovery-20261114071955480959/port-61028-project-1.renovision.json)

It includes two original room views, the exact latest "Just try some new designs.
Bench as push and no handles." instructions, Layout protection, Charcoal & walnut
palette and the saved Contemporary selection (shown as Modern / Contemporary in
the updated app). No design version was imported in this attempt.

Other attempts are kept separately in the same folder:

| File | Saved content |
| --- | --- |
| port-7357-project-1.renovision.json | Project New, Kitchen, one saved design version |
| port-58523-project-1.renovision.json | Claylands, Kitchen, two original views |
| port-59613-project-1.renovision.json | Claylands, Kitchen, one original view and earlier instructions |

### Restore once, then keep testing at the same address

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_web_test.ps1`.
2. Open `http://localhost:7357` in your normal Chrome profile, not Incognito or a
   Flutter-created temporary browser. Bookmark this address.
3. Projects > Restore project backup: choose the latest file above. Restore adds
   a separate project copy; it does not overwrite existing projects. Restore the
   other attempts only if you want those separate copies too.
4. Settings > App build and saved data shows the launch build, address and saved
   counts. Run Check local saving. Reopen the same address/profile and check the
   project, preferences and recorded storage-check time are still there.
5. Import the latest ChatGPT-generated image with Import generated AI result.
   Copying a prompt to another AI app does not automatically import its result.

These backups contain private photos. `recovered_projects/` and the original
isolated recovery snapshot under `.local_backups/` are excluded from source control.
Do not delete browser data or run cleanup to fix an apparently empty project list.

## AI test setup

### Internet API on Android (18 November)

This is the independent phone route; the laptop relay is optional.

1. Open **Settings > AI connection and models**. If a laptop relay is connected,
   choose **Disconnect AI** first.
2. Select **Internet API**, enter your OpenAI developer API key privately and
   choose **Connect OpenAI over internet**. The check lists model access; it
   does not generate an image. Choose the image model/quality after connecting.
3. Open a saved room, choose **Analyse room photos**, review the saved analysis
   and proposed prompt, then generate a design with the normal confirmation.
   Each confirmed analysis/generation uses your API account.
4. Restart the Android app and confirm the connection and project still restore.
   Use **Disconnect and remove API key** to remove this device's saved key.

Android encrypts the key using Android Keystore. The encrypted preference is
excluded from Android cloud backup and device transfer. Project Open/Save files
never carry keys. Chrome direct mode keeps its key in memory only and requires
re-entry after reload. No key is embedded in source or APK. Direct requests use
fixed https://api.openai.com/v1/ endpoints, reject redirects and never automatically
retry a possibly billed request. Working photo copies have metadata stripped and
are resized to at most 2048px on the longest edge; originals remain intact.

The six mocked direct-mode tests and full 135-test suite passed without real keys
or paid provider calls. Real internet generation and physical-device lifecycle
remain manual checks. Old emulator adb reverse settings are irrelevant in this
mode: disabling them does not change the direct HTTPS route.

The following relay instructions apply only to **Laptop relay** development mode.

### Current in-app test controls (15 November)

Open **Settings > AI connection and models**, or use the room's **AI connection
settings** shortcut. Once paired with
the updated relay, **AI model and connection** lets you choose GPT Image 2.5 or 2.6
Sunburst or Flare and low/medium/high image quality. A configured custom relay
default is also retained. Selection alone makes no provider call. Model access
depends on the API account; these are configured options, not an account-access
check. Analysis uses the separate analysis model shown by the connection card.

Start with low quality and one output. Use the same room photo, working version,
prompt and settings when comparing image models; change only the model between
trials. Each run has separate API usage and explicit confirmation. Use the new
Settings shortcut to connect; generation is in **AI generation (optional)**.
Returned image-model metadata and the model/quality in the generated version's
title help identify trials. These settings are kept for the current app session.

Historical onboarding: a ChatGPT subscription alone is insufficient. Obtain
API access as described below, then run the private relay launcher and enter the
key only in its hidden terminal prompt. No live provider tests were made for
this batch. The in-app controls do not sign in to a ChatGPT subscription.

[Official image-model guidance](https://developers.openai.com/api/docs/guides/image-generation)
was checked for the model choices; actual account availability, output adherence
and charges need testing. Higher quality/additional attempts can cost more.



This private development feature sends a selected room photo and prompt to the
OpenAI Images API and saves the returned image as a new local version. The photo
picker, prompt, generation, result review, comparison and approval stay in the app.
The AI itself runs at OpenAI; this is not an offline/on-device image model.

The useful first AI test is now **Understand this room > Analyse room photos**.
Uploading stores photos locally; it does not analyse them or incur API usage.
After connecting the updated relay, confirm the photos/preferences to send.
The app saves visible-room observations, clarification questions and an editable
AI-written design prompt. Review it, edit it, and tick **Use this AI prompt for
the next design**. Generation is a separate confirmed action. A disconnected app
does not fabricate observations or present its local template as photo analysis.

### 1. Obtain API access

Check [API credits for eligible ChatGPT Pro/Business subscribers](https://developers.openai.com/api/docs/guides/chatgpt-api-credits)
first. Eligible owners can link an API organisation and claim credits; with
active credits, an API payment method is not required. The user's exact plan
and eligibility are unknown. This still requires a developer API key and is
not unlimited usage or direct subscription-login authentication in this app.

A ChatGPT login/subscription is not an API key. Sign into the OpenAI developer
platform, check API billing/available credits and model access, and create a
project-scoped API key. Image-model access may require organisation verification.
Do not paste the key into chat, Dart files, browser settings or a screenshot.

Official references:

- [Developer quickstart](https://developers.openai.com/api/docs/quickstart)
- [Create API keys](https://platform.openai.com/api-keys)
- [API key safety](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety)
- [Image generation/editing](https://developers.openai.com/api/docs/guides/image-generation)
- [Photo analysis / vision](https://developers.openai.com/api/docs/guides/images-vision)
- [Structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs)

### 2. Start the private relay on Windows

Open a separate PowerShell terminal in `C:\Dev\renovision_ai`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_ai_relay.ps1
```

When prompted, enter your developer API key. Input is hidden. The script keeps it
in the process environment for the relay session, restores the previous value
when it exits, and does not write it to a file or print it. If OPENAI_API_KEY is
already set in that terminal's environment, the script uses it without prompting.
The relay runs in this terminal; leave it open while testing.

It displays the local address and a temporary **connection code**. This code is
not your OpenAI key. Copy it into Renovision's AI connection form. Stop the relay
with Ctrl+C when finished. A restarted relay has a new code.

The app now remembers the local relay address/code and selected model/quality
in this exact browser/profile. Startup checks the local health endpoint and
reconnects if the same relay is available; it sends no images or paid requests.
Disconnect clears the remembered connection. Project files exclude connection
codes and provider keys. If the relay restarted, enter its new code once.

The relay defaults to `gpt-image-2.5-sunburst`, low quality, one result per request,
using the documented Images edit endpoint. Model availability depends on your API
account. To select another compatible GPT Image model, set its public model ID
before starting the relay, for example:

```powershell
$env:RENOVISION_IMAGE_MODEL = 'gpt-image-2.5-flare'
```

This is a model identifier, not a credential. The relay has no automatic retries.
Low quality and one image limit request size, not the total spend across repeated
button presses. Review provider pricing/usage and configure account limits.

Room analysis uses `gpt-6-luna` through the Responses API, separately from the
image-edit model. It accepts image input and structured text output
([model documentation](https://developers.openai.com/api/docs/models/gpt-6-luna)).
To select another compatible model, set `$env:RENOVISION_ANALYSIS_MODEL` before
starting the relay. This endpoint requests reasoning effort `none`, strict JSON
schema, at most 3000 output tokens and `store: false`. Account/model availability
and live analysis quality still require a real API test. It makes no image request.

### 3. Connect from Chrome

Reload/restart the existing Flutter app session to pick up the code changes while
keeping its browser profile and address. Avoid changing its port or clearing site
storage when checking existing projects. If starting a fresh app session:

```powershell
flutter pub get
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_web_test.ps1
```

Open `http://localhost:7357` in your normal Chrome profile. Keep that exact address
and profile between tests. Do not use a new randomly assigned Flutter Chrome URL.
Use Settings > App build and saved data to compare the build with the launch
terminal and check the address/counts. If previous projects are missing, see
TESTING_GUIDE.md#recovered-projects; validated copies of the earlier kitchen tests are available.

Autosave and save status are beneath the colour palette. The room Settings gear
opens Save now, Save and close and Save as (project copy, image or backup file).
Normal room exit saves pending edits even with Autosave off. Keep the same browser
profile/address; an Autosave switch cannot join separate browser-origin stores.

In **Settings**, find **In-app AI test connection**:

1. Keep the address `http://127.0.0.1:8787`.
2. Enter the relay's connection code, not the API key.
3. Choose **Connect local AI**. This checks the local relay only; it does not
   validate your key against OpenAI, generate an image or incur an AI charge.

The connection code is held only in app memory. Reconnect after an app restart.
The OpenAI key stays in the relay process and is not included in Flutter builds,
Hive data or browser storage.

### 4. Analyse the photos first

1. Refresh the app and reconnect to the running relay if needed. Restart the relay
   only when its code/configuration has changed.
2. Open your room and select the intended working image. Enable other room views
   if you want them included. Select styles/palette and describe changes if known.
   Choose **Whole-room renovation**, then describe a goal such as "Modernise the
   whole kitchen; keep the layout". No checkbox selections are required: the
   prompt supplies coordinated surfaces, fittings, lighting and styling direction.
   Put protected items in **Keep exactly as is**. Optional **Advanced Keep / Replace
   controls** holds the saved room-specific overrides, floor notes and explicit
   removals (for example the wall telephone). Explicit Keep choices take priority.
3. In **Understand this room**, choose **Analyse room photos**. Inspect the photo
   previews, model and preferences. Cancelling sends nothing.
4. Confirm **Send photos for analysis**. This sends photos to OpenAI and can incur
   API charges. Wait for observations, questions and a proposed prompt to be saved.
5. Check that the observations correspond to the actual photos. Confirm uncertain
   features yourself; the AI cannot establish measured plans or hidden structure.
6. Edit the AI-prepared prompt if needed, then tick **Use this AI prompt for the
   next design**. Prompt edits and this choice autosave with the room. It does not
   generate an image automatically.
7. Use **Generate AI design** below and approve its separate image-generation
   confirmation when ready. The reviewed prompt and authoritative current room
   requirements are attached to that request, and saved with the new version.

Changing the working photo, supporting views or room preferences marks the saved
analysis out of date. Copy/generation blocks use of its stale prompt. Analyse again
or untick the AI-prompt choice to use the local template. Older observations remain
available until a successful new analysis replaces them. Only the latest room
analysis is retained; design versions keep the exact prompt used for each image.

Scope choices/notes are preferences too. After changing them, inspect the updated
analysis/prompt before generating. Confirm that the design replaces the old floor
and removes the handset/cord rather than simply recolouring them. Originals and
previous designs remain separate. AI adherence still needs visual checking.
Room type and Keep / Replace choices also enter both analysis and design prompts.
Only the current room type's items apply. A specific Keep choice overrides broad
replacement; conflicting text should lead to clarification. Appliance replacement
must be checked visually: the model should show new appliances, not only recolour
old faces. A room name or selected type is not evidence of actual visible features.

If receiving the analysis succeeds but local saving fails, keep the room open and
choose **Retry saving analysis**. It retries storage without another provider call.
Normal Back navigation waits for analysis to finish and for pending saves. Closing
the browser/process can still lose an in-flight response; a charge may have occurred.

### 5. Run one real room edit

Multiple room views: import several photos when creating a room, or use **Add
room photos** in its workspace (up to six original views). Use **Use as primary**
to save a default viewpoint; an approved design still takes priority when opening
the room. Turn on **Use other views as AI context** to include the other angles.
If a saved design is selected, that design is image 1 and originals serve only as
spatial references; the prompt explicitly prioritises the approved changes.

Restart the updated relay and reconnect after upgrading from the single-image
version. The confirmation dialog previews every image that will be uploaded.
More input views can increase API input charges. The request accepts up to seven
images, each up to 18 MB, with a 36 MB combined limit before working-copy resizing.
The result remains one design from image 1's viewpoint, not a measured 3D model.

1. Open a test project/room and select the intended image under **Working from**.
2. Choose **Precise correction** and enter a **Specific correction**. This is a
   separate saved field; whole-room instructions, palette/style and replacement
   choices are not reapplied. Explicit Keep choices still apply. Switching modes
   deselects the previous AI prompt, so another analysis is optional for a direct
   correction. Start with one narrow change; this is not a mask-enforced edit.
3. Choose **Generate AI design**.
4. Review the image, prompt and model in the confirmation dialog. **Send to
   OpenAI** transmits them and can incur API charges. Cancel sends nothing.
5. Wait for the result to save. It becomes a new branch with the source image ID,
   parent version, supporting image IDs, prompt, provider, model and provider request ID.
6. Compare it with the original. Approval is separate: choose **Approve as
   baseline** only if satisfied. Neither the original nor the previous approved
   baseline is overwritten by generation.

The relay removes EXIF/location metadata from a working copy, strips its ICC and
text metadata, and limits its longest side to 2048 pixels before uploading. Source
bytes stored in the app are unchanged. The provider receives the full selected
working copy, not a masked crop unless that crop is what you selected. Protected
features and precise-edit wording are instructions, not preservation guarantees.

No masks, compositing or outside-region change detection are implemented yet.

### 6. Failures and recovery

- Cannot connect: check the relay is running, the address/code match, and port
  8787 is available. Only local HTTP browser origins are accepted.
- Rejected API request: check API key, billing/credits, model access and provider
  restrictions. The relay prints only a status code, never the key or image.
- Timeout/interruption: a provider charge may already have occurred. Check usage
  before trying again. The app/relay do not automatically repeat paid requests.
- Local save failure after generation: keep the screen open and choose **Retry
  saving result**. This reuses the received image without another provider call.
  Unsaved results are held in memory and are lost if that screen/app is closed.
- Normal Back/Save and close now wait while generation or a received unsaved
  image is pending. Scrolling/collapsing keeps the image card alive. Closing the
  browser/process can still interrupt saving while the provider finishes and
  bills the job. Cancellation of a submitted provider job is not implemented.

### Android target and device acceptance

#### Install directly on a physical Android phone

Latest toolbar update: `output/mobile-test/renovision-test-1.0.6.apk`, version
1.0.6+7, source `3ffefb376a`. Install over the existing app without uninstalling.

Latest compact-help update: `output/mobile-test/renovision-test-1.0.5.apk`,
version 1.0.5+6, source `7944f6f4ea`. Install over the current app; do not uninstall.

Latest deletion update: `output/mobile-test/renovision-test-1.0.4.apk`, version
1.0.4+5, source `55b1bf7204`. Install over the current app without uninstalling.

Latest multi-concept update: `output/mobile-test/renovision-test-1.0.3.apk`,
version 1.0.3+4, source `a198a37712`. Install over the current app; no uninstall.

Latest crop/markup update: `output/mobile-test/renovision-test-1.0.2.apk`, version
1.0.2+3, source `e7b7ed2e66`. This supersedes the 1.0.1 package below. Install as
an update; the package and signing identity remain unchanged.

Viewer update: `output/mobile-test/renovision-test-1.0.1.apk` (also copied to
`renovision-test.apk`), version 1.0.1+2, source `4d0ef665b2`. Install this APK as
an update over version 1.0.0; the package ID and signing key are unchanged.
Do not uninstall the current app to update it.

Google Play and a Google account are not required for this private APK test.
The phone test package is `output/mobile-test/renovision-test.apk` (ignored by
Git). It is a release-mode universal APK for ARM32, ARM64 and x86-64, signed with
this PC's existing development signing key, not a Play Store release package.

1. Copy the APK to the phone, for example by USB file transfer into Downloads.
2. Open it from the phone's Files app and choose Install. If Android asks,
   allow that Files app to install unknown apps, then return to the installer.
   USB debugging and Android Studio are unnecessary for this method.
3. Open Renovision. Its storage is separate from Chrome/the emulator. To bring
   existing work across, use Save project on the source device, copy the
   `.renovision.json` file to the phone, and choose Open project there.
4. In Settings > AI connection and models, select Internet API and enter the
   key privately on the phone. Project files do not transfer AI credentials.
5. Test a photo import, analysis, generation, saving, full close/reopen and
   project export/reopen. The phone needs internet for AI, without a PC relay.

For later test updates, install over the existing app; do not uninstall first.
Keep the package ID and development signing key stable to preserve update
compatibility, and retain a portable project backup. APKs are for Android;
iPhone testing needs a separate iOS build/distribution workflow.

#### Full-screen image check on the phone

1. Open an existing generated design and tap its image/full-screen button.
   Saved version and favourite thumbnails also open the viewer; tapping a
   version's text still selects it as the working version as before.
2. Pinch out/in, drag after zooming, try the zoom buttons, and double-tap to
   zoom or fit. Fit image resets the view. The full stored image is used here,
   rather than the thumbnail-sized preview.
3. Enable Android Auto rotate and turn the phone sideways. The viewer should
   resize and refit the picture. Turn it upright again and close using X or Back.
4. Confirm the same room/history/baseline remains. No new design or AI request
   should be created by viewing. Generate another image only if you want to test
   the tappable result preview beside generation controls or in guided setup.

Automated gesture, resize and preservation checks passed as part of 140 tests;
physical S21 acceptance is still a manual check. Original files are unchanged.

#### Crop and markup checks (1.0.2)

- Open Crop / focus, draw a box, resize each corner/edge and drag its interior
  to move it. A tap without a drag must keep the box. Save as new version and
  confirm the crop looks correct while the original remains available.
- Open Sketch / markup. Add several marks using pen, line, arrow, rectangle
  and ellipse, with different colours and Fine/Medium/Bold widths.
- Choose Text note, tap the photo and enter a comment (up to 100 characters).
  Choose Select / move, tap a note and use Edit note; move a shape, recolour it
  or use Remove selected. Check Undo, Redo and Clear marks (also undoable).
- Save as new version and open the reference full screen. Check shape colours,
  text placement and detail. References are flattened when saved: individual
  marks can be edited during this session, but cannot be recovered as separate
  layers when reopening the saved image. Colours/shapes guide the AI visually;
  they do not create an enforced edit mask.

143 regression tests passed, including saved-pixel, metadata and original-byte
preservation checks. Native S21 touch/keyboard/visual checks remain manual.

#### Multiple design ideas and style comparison (1.0.3)

1. Choose Whole-room renovation and an original room photo in Working from for
   fresh alternatives. A selected generated design is instead the reference for
   variations on it. Style chips change the next request, not an existing image.
2. Select Modern / Contemporary and Classic. With one result these blend into
   a transitional design. For separate looks, open AI generation, tick Multiple
   design ideas and Compare styles separately, and choose 2 or 3 concepts.
   With two styles/three concepts, the extra concept blends the styles. Select
   no more styles than the requested count when comparing them separately.
3. Review the confirmation: model, quality, actual starting photo/context views,
   number of separate paid requests and each concept brief. Cancel sends none.
4. Generate. Progress identifies concept number/stage. Each received image saves
   before the next request. Stop after this image lets the current request finish
   (it may be billed), then prevents the rest. Do not assume it cancels billing.
5. Open result images full screen, compare them, then choose Use this design.
   This selects the working version; approval and favourites remain separate.
   Stored version prompts/provider request IDs identify what was actually sent.
6. Reopen the room/project to check saved versions and the batch preferences.
   If a local save fails, Retry saving result saves only those received bytes;
   it does not resume the remaining paid requests. Provider failure also stops
   the batch and retains earlier versions. Generate again starts a new batch.

Fresh whole-room prompts request visible variation within protected features,
layout and palette. Exact-byte duplicates are flagged; visually similar files
with different encodings are not detected. No automatic replacement requests or
guarantee of model novelty. The 152-test suite uses simulated provider responses;
real image quality/style adherence needs a user API test. If an older reviewed
AI prompt is stale after upgrading/changing preferences, analyse again or untick
Use this AI prompt; its saved text/history is preserved.

#### Delete unwanted designs (1.0.4)

1. Tap a generated result's trash icon, or open its version-history menu and
   choose Delete design. Explore and favourites also have delete icons.
2. Cancel once to check the design remains. Confirm deletion to remove it from
   active design lists. Check that the current working image falls back safely
   if that was the deleted design. Original photos remain available.
3. Use Undo in the message, or expand Deleted designs in the room workspace
   and tap Restore. Recovery keeps the same history, image and favourite status.
4. Save/reopen a project and check deleted designs remain deleted and restorable.
   Deleting a parent must not damage its refinements or their source images.
5. Approved baselines are protected: approve the original or another design
   first, then delete the unwanted former baseline. Wait for AI work to finish
   before deleting designs; deletion itself sends no provider request.

Deleted designs and bytes remain in local storage and saved project files for
recovery and valid source references; this action does not free their disk space.
Permanent purge is not included. 160 tests pass, including generated-gallery
deletion without additional paid requests and backup/restoration of deleted
parents referenced by refinements and analysis. Physical-phone checks remain.

#### Compact help controls (1.0.5)

- On Chrome, hover over a circled info icon to read its explanation. Clicking
  it opens a readable help panel; keyboard Tab/Enter also works.
- On the phone, tap the icon and close the scrollable panel with Close or Back.
  Help does not save files, change selections or toggle Autosave.
- Check Step 1 still shows room-photo guidance. Project file should now show
  Save project, Save project as and a short status, with the longer file/privacy/
  browser explanation in its info control.
- Check palette/style and workspace sections are less text-heavy. Instructions,
  actual AI analysis/results and current form values are not hidden. Saving
  failures, unsaved/pending messages, AI progress and paid-generation consent
  remain visible in full.

166 automated tests passed, including hover, keyboard and phone-sized large-text
help panels. Native S21 visual/touch review remains a manual check.

#### Contextual top-right toolbars (1.0.6)

- Open a project, room setup and workspace. Shared actions keep the same icons
  and relative order; only relevant tools appear. Use hover/long-press labels.
- On the phone, use More tools for extra actions. On wider screens more icons
  appear directly, with the same order. Long room/project titles should truncate
  rather than collide with the toolbar.
- Save project file opens the existing Save/Save as controls. In guided setup,
  Settings first saves draft edits; Back returns to the same step. Finish later
  is a toolbar icon with that label and still saves progress before leaving.
- In markup, try toolbar Undo/Redo and Save as new version. In crop, use Reset
  selection and Save; original photos remain unchanged. The body buttons still
  work and use the same handlers.
- Full-screen viewing shows zoom/fit/help rather than unrelated project tools.
  Before/after has Reset comparison to centre the slider and Help.
- Settings has Help but no redundant Settings action on its own screen.

172 tests passed, including actual file saving through the project toolbar and
phone-width overflow selection. Native S21 touch/navigation checks remain manual.

18 November: debug build `a793f4c30b` is installed on the existing Medium Phone
emulator. Native launch, project navigation and system Open picker presentation
were observed. The project copy in Downloads survived the PC restart. A saved
room workspace was visible, but controlled import/save/restart, camera and
keyboard acceptance checks remain. Emulator interaction overlapped the check;
coordinate with the user before further taps. Full Android acceptance is not
claimed. Logs/screenshots are kept only under ignored local output.

AI progress now stays visible at the bottom of workspace/setup with elapsed
time and actual client stages. The indeterminate indicator does not claim a
provider completion percentage. A failed local save can be retried without a
second AI call. This activity is in memory; it does not recover a running paid
request after force-closing/restarting the app.

After a PC restart, start the relay privately with `tool/start_ai_relay.ps1`.
The current emulator has `adb reverse tcp:8787 tcp:8787`, so its default
`http://127.0.0.1:8787` reaches the PC relay while that tunnel exists. Without
the tunnel, an emulator can use `http://10.0.2.2:8787`. These addresses and the
relay process are development setup, not the production phone backend.

Android is the target app, not an optional browser wrapper. Chrome provides a
temporary preview for shared layout/workflows only. Validate touch targets,
keyboard/safe areas, Back, camera/photo selection, denied permissions, lifecycle,
local durability and file exports on Android before marking the app phone-ready.
The current native file adapter opens system choosers for individual saves;
only reusable destinations may be linked for background file autosave. Native
working data continues autosaving inside the app. Persistent document URI
updates/reconnection require a later Android implementation and device test.

16 November toolchain check: SDK 36.0.0/emulator present, command-line tools
missing, licence status unknown. No SDK installation or licence acceptance was
performed. Release INTERNET permission is present; cleartext development relay
access remains debug-only. The shipping app still needs an HTTPS AI backend.

Complete SDK setup first. Run the Windows relay as above. In an Android emulator,
use `http://10.0.2.2:8787` with the displayed connection code. Only the debug
manifest allows cleartext HTTP for this local test. For a USB phone, use an
ADB reverse tunnel and the loopback address; LAN/public hosting is not supported.
Android and live provider calls have not yet been verified.

### Verification

Automated relay tests replace the OpenAI HTTP client with simulated responses;
they never use your credentials or send images to a provider. UI tests cover
confirmation, new-version saving, provider failure and retrying a failed local
save without paying for another generation. A real API test still needs your key
and your explicit **Send to OpenAI** action in the app.

The completed code passes all 25 VM/widget tests, static analysis and the web
release build. The launcher passes PowerShell syntax validation. The previous automated Chrome test runner
stalled before executing cases; interactive Chrome and live API behaviour still
require testing. No automated test result here claims a successful paid generation.

This loopback relay is for your private Windows development workflow. It is not
a production backend and must not be exposed on the internet or packaged with a
reusable API key for distribution.
## Phone camera and gallery entry — 18 November source update

Packaged on request as **1.0.7+8**, source `fa1e8d0319`:
`output/mobile-test/renovision-test-1.0.7.apk` (also `renovision-test.apk`).
175 automated tests pass; static analysis clean. Package/version and matching
certificate verified against 1.0.6. Install as an update without uninstalling.
HOMLY/Forma redesign and live-camera overlay are not included. Build later APKs
only when asked.

On the phone, open a project and use **Take photo** for a new
room or **Choose photos** for existing phone photos (up to six per room). In room
setup and the workspace, Room photos offers both actions for additional angles.
Starting from a sample design offers the same source choice. The camera path
opens the phone's still-camera app; it is not yet an embedded live renovation view.

Check cancellation, a failed/unavailable camera, multiple gallery selection,
six-photo limit, reopening the project after restart and unchanged originals.
Adding photos must not start a paid AI request. Photos are stored locally using
the existing project store; choosing them is separate from sending them to AI.
Process-kill recovery during an external camera/gallery picker remains unverified.
