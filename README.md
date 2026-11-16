# Renovision AI — local Stage 1 prototype

An existing Flutter renovation app with project/room creation, local Hive storage,
photo import, zoom/pan, non-destructive crop/markup, imported design versions,
approved baselines, favourites and before/after comparison. Optional in-app
OpenAI editing uses a private local relay; manual AI handoff remains available.
There is no production backend or payment integration.

Existing local projects now open on Projects with a saved-room Continue card.
On a design page, use the Settings gear for saving/export and AI setup; only
Autosave and save status remain on the page. Global Settings includes project
backup and Restore project backup. External backup files must be selected;
the app does not automatically read files from Downloads.

Explore now includes six labelled sample rooms with room/style filters, plus
a separate chooser for all 19 styles and 12 colour palettes. The room picker
offers 42 home/utility/outdoor space types with search and category filters.
Choose a sample to start a room using your own photos and its style/palette,
or use Projects > Import room photo for the new visual room picker. Samples do
not populate your saved projects automatically.

Connected AI can now analyse room photos before generation: visible features,
clarification questions and an editable proposed prompt. Uploading alone saves
photos locally; it does not run AI. Review and select the AI prompt before a
separate design request. Live API quality remains unverified.

New rooms use a saved four-step setup: Photos → Direction → Analyse/review →
Final options. Finish later resumes the saved step. Existing rooms keep their
workspace; the guided-setup toolbar button reopens the steps.

Use **Projects → Open project…** to load a `.renovision.json` file containing
all rooms, original photos, designs and saved instructions/choices. **Save
project** and **Save project as…** choose a portable file. Chrome can update it
and autosave changes while linked; after restarting the app, Open project
reconnects the destination. Local browser saving continues separately. Always
use **http://localhost:7357** in the same normal Chrome profile. The local relay
connection and model choices are remembered there; credentials never enter a
project file. A restarted relay may need its new connection code.

## Project documents

Keep day-to-day work in these four files; add new topics to an existing document.

- **README.md**: running the app and finding instructions.
- [Project brief](RENOVISION_PROJECT_BRIEF.md): product requirements.
- [Feature status](FEATURE_STATUS.md): implemented, incomplete and unverified features.
- [Next steps](CODEX_NEXT_STEPS.md): current priorities and the next manual tests.

Supporting detail lives in just two optional reference guides:
[testing and storage](docs/TESTING_GUIDE.md) and
[product/research notes](docs/PRODUCT_NOTES.md).

Quick reference: [AI connection](docs/TESTING_GUIDE.md#ai-test-setup),
[saving and storage](docs/TESTING_GUIDE.md#saving-and-storage),
[competitor/UI review](docs/PRODUCT_NOTES.md#competitor-review).
A developer API key is required for provider calls; a subscription login cannot
be entered as an API key.

## How to run on Windows

Android phones are the target product. Chrome is a temporary preview of the same
Flutter workflows; browser rendering is not Android device validation. Keep
camera, file access, app lifecycle and AI transport behind platform boundaries.
The PC relay is development infrastructure, not the final phone backend.

1. Install Git for Windows, the Flutter SDK, VS Code Flutter extension and Chrome or Edge.
2. Open the existing project in VS Code. Run:

```powershell
flutter doctor
cd C:\Dev\renovision_ai
flutter devices
```

3. Run the existing app:

```powershell
flutter pub get
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_web_test.ps1
```

Open `http://localhost:7357` in your normal Chrome profile and bookmark it. This
launcher uses a fixed port and leaves browser ownership with Chrome. A different
port or profile has different saved projects. Use the same address for every test.
Recovered previous tests: [Recovered projects](docs/TESTING_GUIDE.md#recovered-projects).
Settings > App build and saved data shows the running build, address and counts,
and offers Check local saving. VS Code also has a saved-testing launch configuration
using the same web-server address; open that URL manually in normal Chrome.

4. Run validation:

```powershell
flutter test
flutter analyze
flutter test --platform chrome test/workflow_test.dart test/editor_test.dart
flutter build web
```

## Android emulator (after installing Android Studio)

- Create and start an Android Virtual Device using Android Studio > Device Manager.
- In the VS Code terminal run `flutter devices` to find the available target, then `flutter run -d <device-id>`.
- Or use VS Code's device selector at bottom-right and press F5.

## Important

- Local test configuration is excluded from Git: `.vscode/`, environment files,
  `*.local.*` settings, credentials/signing keys, private databases, exported
  `.renovision.json` projects, recovered copies, browser profiles and `output/`.
  Keep reusable application code, synthetic tests and fictional sample assets in
  version control. A shareable `.env.example` must contain placeholders only.
- Two private kitchen output files were removed from current Git tracking while
  kept locally. They still exist in earlier commit `f94fe9b`; this change does
  not remove historical content. History cleanup is a separate step before
  publishing that history. No commit or push was performed for this cleanup.

- The product name is provisional; check trademarks before publication.
- Don't store API keys or private customer photos in GitHub.
- Flutter's created `.gitignore` should be retained; add private data folders and signing credentials to it.
- Chrome stores data for a specific browser profile and origin, including port.
  Use the existing session/address when checking existing projects. Clearing site
  storage can delete projects. Back up each project and test restoring a copy. Keep source
  photos separately. Source snapshots in `.local_backups/` do not back up app data.
- Approval is explicit and separate from favourites. New imports/crops/sketches
  do not replace the approved baseline automatically. Original bytes remain intact.
- Precision mode prepares prompts/references; it does not yet enforce masks,
  blend edited crops back, or detect unintended changes outside a selection.
- Automated tests use synthetic images and disposable storage. The separate
  recovery tool reads only isolated copies of cached personal projects and writes
  validated portable backups; original databases remain untouched.
- Room Settings > Save as offers image export (metadata-free PNG). Settings offers
  Back up project (exact original bytes, history and approvals); restore adds a separate
  project copy. Check browser Downloads. Backups contain private photos/metadata.
