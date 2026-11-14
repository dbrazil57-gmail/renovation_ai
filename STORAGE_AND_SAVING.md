# Saving and storage direction

User preference, 14 November 2026: normal work should save automatically inside
the app, with familiar options to save a copy to a chosen location or photo library.

## Current implementation

- Hive stores project/room metadata, preferences, prompts and version history.
  Image bytes are in a separate Hive box. Existing IDs and boxes are retained.
- Imported room photos and created design versions are saved when added. The
  original stays separate from crops, markup and generated images.
- Palette and review choices save when selected. Room text/style/mode preferences
  now autosave after a brief pause, with Saving / Saved locally / Save failed
  feedback. Normal back navigation waits for a pending draft save.
- Save instructions remains available for an immediate save or retry.
- Browser storage belongs to a browser profile and app origin. It is not a normal
  Downloads folder and must not be described as a permanent backup. Browser
  shutdown cannot guarantee completion of unfinished asynchronous writes.
- Download image makes a separate metadata-free PNG. Chrome uses its Downloads
  flow; Android uses a system save chooser (device verification outstanding).
- Project backup keeps original bytes plus history/preferences in a portable
  file. Restore creates a separate project copy, with fresh IDs.

## Later familiar save actions

1. Save to Photos / Gallery on Android, with explicit user action and platform
   permission handling. Do not put all private originals in the public gallery.
2. Save image as… / choose folder where the platform supports it, plus share-sheet
   export. Keep the internal working copy and version links intact.
3. Save a design board containing selected options, materials and palette swatches.
4. Backup reminders and verified restore checks; optional automatic backups to a
   user-chosen destination once permissions and failure handling are tested.
5. Optional cloud sync only later, with account, consent and conflict handling.

For a larger Android library, move large photos to app-private files behind the
repository interface and keep metadata in a local database. No SQLite migration
or storage replacement is needed just to add these controls. Any future migration
must preserve existing originals, identifiers, approvals and export compatibility.
