# Testing and storage reference

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

The user currently has only a ChatGPT subscription. Before a live test, obtain
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
