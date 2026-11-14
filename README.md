<<<<<<< HEAD
# Renovision AI — local Stage 1 prototype

An existing Flutter renovation app with project/room creation, local Hive storage,
photo import, zoom/pan, non-destructive crop/markup, imported design versions,
approved baselines, favourites and before/after comparison. Optional in-app
OpenAI editing uses a private local relay; manual AI handoff remains available.
There is no production backend or payment integration.

Product requirements: [RENOVISION_PROJECT_BRIEF.md](RENOVISION_PROJECT_BRIEF.md).
Current changes and manual test checklist: [CODEX_NEXT_STEPS.md](CODEX_NEXT_STEPS.md).
Full feature checklist: [FEATURE_STATUS.md](FEATURE_STATUS.md).
Rooms support up to six original photos, a primary viewpoint and optional
multi-image AI context. Add angles when creating a room or from its workspace.
Choose a colour palette after selecting new room photos, or use Colour palette
in the workspace. Presets are saved locally and included in future design prompts.
Design styles and an Other field also feed the prepared prompt. Text and style
preferences autosave locally, with visible status and a manual save/retry.
See [STORAGE_AND_SAVING.md](STORAGE_AND_SAVING.md) for storage and export options.
In-app AI connection: [AI_TEST_SETUP.md](AI_TEST_SETUP.md). A developer API key is
required; a subscription login cannot be entered as an API key.

## How to run on Windows

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
flutter run -d chrome
```

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
- Tests use synthetic images and disposable storage, never personal project data.
- Room workspaces offer Download image (metadata-free PNG). Projects offer Back
  up project (exact original bytes, history and approvals); restore adds a separate
  project copy. Check browser Downloads. Backups contain private photos/metadata.
=======
# renovation_ai
>>>>>>> origin/main
