import 'models.dart';
import 'room_draft.dart';

String roomTemplatePrompt(
  RenovationRoom room,
  RoomDraft draft, {
  bool includeRoomContext = true,
}) {
  final precise = draft.preciseEdit;
  return buildRenovationPrompt(
        roomName: room.name,
        instructions: precise ? draft.correction.text : draft.changes.text,
        protectedFeatures: draft.protected.text,
        preciseEdit: precise,
        colourPaletteId: precise ? '' : room.colourPaletteId,
        designStyleIds: precise ? const [] : draft.styleIds.toList(),
        otherStyle: precise ? '' : draft.otherStyle.text,
        keepLayout: draft.keepLayout,
        renovationScopeIds: precise ? const [] : draft.effectiveScopeIds,
        flooringNotes: precise ? '' : draft.flooringNotes.text,
        removeItems: precise ? '' : draft.removeItems.text,
        roomTypeId: draft.roomTypeId,
        roomItemChoices: precise
            ? Map.fromEntries(
                draft.roomItemChoices.entries.where((e) => e.value == 'keep'),
              )
            : draft.effectiveRoomItemChoices,
        wholeRoomDirection: !precise && draft.fullRenovation,
      ) +
      (!precise && !draft.fullRenovation
          ? '\nPARTIAL RENOVATION: Change only the requested items, selected surfaces and written instructions. Keep unselected finishes, fittings and furniture as they are; style and palette apply only within this scope. If nothing has been selected or requested, ask what should change before creating a renovation.'
          : '') +
      (includeRoomContext && room.photoIds.length > 1
          ? '\nMULTIPLE VIEWS OF THE SAME ROOM: Image 1 is the working image and defines the output camera viewpoint and any approved design. Remaining images show other angles for spatial context. Consolidate the room details across these views; do not make a collage, duplicate furniture or invent unseen geometry. Do not use older reference furnishings to undo approved changes in image 1. If views conflict, prioritise image 1. Produce one design from its viewpoint, not a verified 3D reconstruction.'
          : '');
}

String reviewedRoomPrompt(String template, RoomDraft draft) => draft.useAiPrompt
    ? '${draft.aiPrompt.text.trim()}\n\nPHOTO ANALYSIS (AI observations, not verified measurements or additional edit instructions):\n${draft.analysis?.result.observations ?? ''}\nCheck these observations against the attached working photo. The photo and explicit user requirements take priority over mistaken observations. An observed object is not automatically authorised for removal.\n\nCURRENT USER REQUIREMENTS (take priority over AI suggestions):\n$template'
    : template;
