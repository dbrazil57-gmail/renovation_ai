# Planned AI design workflow

User requirement recorded 14 November 2026. This is the intended next AI workflow,
not a claim that prompt writing or multiple-result generation is implemented.

1. Add photos of the same room; choose the primary view, colours and preferences.
2. Describe the desired changes in ordinary language and identify what must stay.
3. AI reviews the photos and preferences, then writes a specific renovation prompt.
4. Show the proposed prompt to the user for editing and approval. Surface unclear
   or contradictory instructions rather than silently inventing requirements.
5. Let the user choose how many design alternatives to request. Show the count,
   provider/model and cost information before submission. Never generate paid
   alternatives automatically merely because a prompt was drafted.
6. Show the returned designs together with individual status/error information,
   useful titles, zoom/compare controls and keep/pass selection. Preserve successful
   results if another option fails; do not automatically retry billable requests.
7. Select one design as the approved baseline. Enter a further instruction or
   markup to improve that exact version. Save refinements as new child versions.

## Prompt-writing requirements

- Use the actual room photographs, selected palette, user changes and room memory.
- Separate layout-preserving renovation from a small-area precision correction.
  Replacing cabinets, flooring and appliances together is a renovation request,
  even when the walls and room footprint must remain unchanged.
- State the working viewpoint and supporting photo roles. Do not claim that
  multiple photos establish measurements or a verified 3D model.
- Explain which requested change affects which part of the room. Preserve the
  windows, openings, walls, viewpoint and approved choices unless explicitly changed.
- Treat a palette as guidance within allowed changes, not permission to repaint
  protected features. Handle "nothing to retain" without contradictory wording.
- Require the relevant image attachments. A copied text prompt alone has no photos.
- Retain the deterministic template as an offline/manual fallback, clearly labelled.

## Implementation sequence

1. Add a provider-neutral prompt-draft service and editable draft screen with
   mocked-provider tests, cancellation and clear failure handling.
2. Add the local relay vision/text endpoint. Provider key remains on the PC;
   disclose photo transmission and any prompt-drafting charge before calling it.
3. Add bounded multi-design requests and an option-comparison screen. Request
   limits, partial completion and billing acknowledgement must be explicit.
4. Record each batch, prompt revision, source/supporting image IDs, provider/model,
   request IDs, result and selected baseline. Keep legacy records readable and
   include the new records in backups with a versioned format where needed.
5. Verify with the Claylands kitchen case, then validate Android behaviour.

## Current implementation

The app currently builds prompts from a deterministic template. The local relay
requests one generated image at a time. Multiple room input photos are supported;
multiple returned design options are a different capability and remain planned.
Manual edits, saved versions, favourites, approval and version branching already
exist and should be reused rather than replaced.
