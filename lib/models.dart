import 'design_palettes.dart';
import 'design_styles.dart';
import 'room_analysis.dart';
import 'renovation_scope.dart';
import 'room_features.dart';

class RenovationProject {
  final String id;
  final String name;
  final DateTime created;

  RenovationProject({
    required this.id,
    required this.name,
    required this.created,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created': created.toIso8601String(),
  };

  factory RenovationProject.fromMap(Map<dynamic, dynamic> data) =>
      RenovationProject(
        id: data['id'].toString(),
        name: data['name'].toString(),
        created: DateTime.parse(data['created'].toString()),
      );
}

class RenovationRoom {
  final String id;
  final String projectId;
  final String name;
  final String originalId;
  final String instructions;
  final String correctionInstructions;
  final int setupStep;
  final bool setupComplete;
  final String protectedFeatures;
  final String? approvedDesignId;
  final List<String> additionalPhotoIds;
  final String? primaryPhotoId;
  final String colourPaletteId;
  final List<String> designStyleIds;
  final String otherStyle;
  final bool preciseEdit;
  final bool keepLayout;
  final RoomAnalysis? analysis;
  final String aiPrompt;
  final bool useAiPrompt;
  final List<String> renovationScopeIds;
  final String flooringNotes;
  final String removeItems;
  final String roomTypeId;
  final Map<String, String> roomItemChoices;
  List<String> get photoIds => [originalId, ...additionalPhotoIds];
  String get primaryId => primaryPhotoId ?? originalId;
  final DateTime created;

  RenovationRoom({
    required this.id,
    required this.projectId,
    required this.name,
    required this.originalId,
    required this.instructions,
    this.correctionInstructions = '',
    this.setupStep = 0,
    this.setupComplete = true,
    required this.protectedFeatures,
    required this.created,
    this.approvedDesignId,
    this.additionalPhotoIds = const [],
    this.primaryPhotoId,
    this.colourPaletteId = '',
    this.designStyleIds = const [],
    this.otherStyle = '',
    this.preciseEdit = false,
    this.keepLayout = true,
    this.analysis,
    this.aiPrompt = '',
    this.useAiPrompt = false,
    this.renovationScopeIds = const [],
    this.flooringNotes = '',
    this.removeItems = '',
    this.roomTypeId = '',
    this.roomItemChoices = const {},
  });

  RenovationRoom copyWith({
    String? instructions,
    String? correctionInstructions,
    int? setupStep,
    bool? setupComplete,
    String? protectedFeatures,
    String? approvedDesignId,
    bool useOriginalBaseline = false,
    List<String>? additionalPhotoIds,
    String? primaryPhotoId,
    String? colourPaletteId,
    List<String>? designStyleIds,
    String? otherStyle,
    bool? preciseEdit,
    bool? keepLayout,
    RoomAnalysis? analysis,
    String? aiPrompt,
    bool? useAiPrompt,
    List<String>? renovationScopeIds,
    String? flooringNotes,
    String? removeItems,
    String? roomTypeId,
    Map<String, String>? roomItemChoices,
  }) => RenovationRoom(
    id: id,
    projectId: projectId,
    name: name,
    originalId: originalId,
    additionalPhotoIds: additionalPhotoIds ?? this.additionalPhotoIds,
    primaryPhotoId: primaryPhotoId ?? this.primaryPhotoId,
    colourPaletteId: colourPaletteId ?? this.colourPaletteId,
    designStyleIds: designStyleIds ?? this.designStyleIds,
    otherStyle: otherStyle ?? this.otherStyle,
    preciseEdit: preciseEdit ?? this.preciseEdit,
    keepLayout: keepLayout ?? this.keepLayout,
    analysis: analysis ?? this.analysis,
    aiPrompt: aiPrompt ?? this.aiPrompt,
    useAiPrompt: useAiPrompt ?? this.useAiPrompt,
    renovationScopeIds: renovationScopeIds ?? this.renovationScopeIds,
    flooringNotes: flooringNotes ?? this.flooringNotes,
    removeItems: removeItems ?? this.removeItems,
    roomTypeId: roomTypeId ?? this.roomTypeId,
    roomItemChoices: roomItemChoices ?? this.roomItemChoices,
    instructions: instructions ?? this.instructions,
    correctionInstructions:
        correctionInstructions ?? this.correctionInstructions,
    setupStep: setupStep ?? this.setupStep,
    setupComplete: setupComplete ?? this.setupComplete,
    protectedFeatures: protectedFeatures ?? this.protectedFeatures,
    approvedDesignId: useOriginalBaseline
        ? null
        : approvedDesignId ?? this.approvedDesignId,
    created: created,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'projectId': projectId,
    'name': name,
    'originalId': originalId,
    'additionalPhotoIds': additionalPhotoIds,
    'primaryPhotoId': primaryPhotoId,
    'colourPaletteId': colourPaletteId,
    'designStyleIds': designStyleIds,
    'otherStyle': otherStyle,
    'preciseEdit': preciseEdit,
    'keepLayout': keepLayout,
    'analysis': analysis?.toMap(),
    'aiPrompt': aiPrompt,
    'useAiPrompt': useAiPrompt,
    'renovationScopeIds': renovationScopeIds,
    'flooringNotes': flooringNotes,
    'removeItems': removeItems,
    'roomTypeId': roomTypeId,
    'roomItemChoices': roomItemChoices,
    'instructions': instructions,
    'correctionInstructions': correctionInstructions,
    'setupStep': setupStep,
    'setupComplete': setupComplete,
    'protectedFeatures': protectedFeatures,
    'approvedDesignId': approvedDesignId,
    'created': created.toIso8601String(),
  };

  factory RenovationRoom.fromMap(Map<dynamic, dynamic> data) => RenovationRoom(
    setupStep: data['setupStep'] is int
        ? (data['setupStep'] as int).clamp(0, 3)
        : 0,
    setupComplete: data['setupComplete'] != false,
    correctionInstructions: (data['correctionInstructions'] ?? '').toString(),
    id: data['id'].toString(),
    projectId: data['projectId'].toString(),
    name: data['name'].toString(),
    originalId: data['originalId'].toString(),
    additionalPhotoIds: List<String>.from(
      data['additionalPhotoIds'] as List? ?? const [],
    ),
    primaryPhotoId: data['primaryPhotoId'] as String?,
    colourPaletteId: (data['colourPaletteId'] ?? '').toString(),
    designStyleIds: List<String>.from(
      data['designStyleIds'] as List? ?? const [],
    ),
    otherStyle: (data['otherStyle'] ?? '').toString(),
    preciseEdit: data['preciseEdit'] is bool
        ? data['preciseEdit'] as bool
        : true,
    keepLayout: data['keepLayout'] is bool ? data['keepLayout'] as bool : true,
    analysis: data['analysis'] is Map
        ? RoomAnalysis.fromMap(data['analysis'] as Map)
        : null,
    aiPrompt: (data['aiPrompt'] ?? '').toString(),
    useAiPrompt: data['useAiPrompt'] == true,
    renovationScopeIds: List<String>.from(
      data['renovationScopeIds'] as List? ?? const [],
    ),
    flooringNotes: (data['flooringNotes'] ?? '').toString(),
    removeItems: (data['removeItems'] ?? '').toString(),
    roomTypeId: (data['roomTypeId'] ?? '').toString(),
    roomItemChoices: Map<String, String>.from(
      data['roomItemChoices'] as Map? ?? const {},
    ),
    instructions: (data['instructions'] ?? '').toString(),
    protectedFeatures: (data['protectedFeatures'] ?? '').toString(),
    approvedDesignId: data['approvedDesignId']?.toString(),
    created: DateTime.parse(data['created'].toString()),
  );
}

class DesignVersion {
  final String id;
  final String roomId;
  final String imageId;
  final String title;
  final String prompt;
  final String? parentId;
  final bool favourite;
  final bool rejected;
  final DateTime created;
  final String? sourceImageId;
  final String? aiProvider;
  final String? aiModel;
  final String? providerRequestId;
  final List<String> supportingImageIds;

  DesignVersion({
    required this.id,
    required this.roomId,
    required this.imageId,
    required this.title,
    required this.prompt,
    required this.parentId,
    required this.favourite,
    required this.rejected,
    required this.created,
    this.sourceImageId,
    this.aiProvider,
    this.aiModel,
    this.providerRequestId,
    this.supportingImageIds = const [],
  });

  DesignVersion copyWith({bool? favourite, bool? rejected}) => DesignVersion(
    id: id,
    roomId: roomId,
    imageId: imageId,
    title: title,
    prompt: prompt,
    parentId: parentId,
    sourceImageId: sourceImageId,
    aiProvider: aiProvider,
    aiModel: aiModel,
    providerRequestId: providerRequestId,
    supportingImageIds: supportingImageIds,
    favourite: favourite ?? this.favourite,
    rejected: rejected ?? this.rejected,
    created: created,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'roomId': roomId,
    'imageId': imageId,
    'title': title,
    'prompt': prompt,
    'parentId': parentId,
    'sourceImageId': sourceImageId,
    'aiProvider': aiProvider,
    'aiModel': aiModel,
    'providerRequestId': providerRequestId,
    'supportingImageIds': supportingImageIds,
    'favourite': favourite,
    'rejected': rejected,
    'created': created.toIso8601String(),
  };

  factory DesignVersion.fromMap(Map<dynamic, dynamic> data) => DesignVersion(
    id: data['id'].toString(),
    roomId: data['roomId'].toString(),
    imageId: data['imageId'].toString(),
    title: data['title'].toString(),
    prompt: (data['prompt'] ?? '').toString(),
    parentId: data['parentId']?.toString(),
    sourceImageId: data['sourceImageId']?.toString(),
    aiProvider: data['aiProvider']?.toString(),
    aiModel: data['aiModel']?.toString(),
    providerRequestId: data['providerRequestId']?.toString(),
    supportingImageIds: List<String>.from(
      data['supportingImageIds'] as List? ?? const [],
    ),
    favourite: data['favourite'] == true,
    rejected: data['rejected'] == true,
    created: DateTime.parse(data['created'].toString()),
  );
}

String buildRenovationPrompt({
  required String roomName,
  required String instructions,
  required String protectedFeatures,
  required bool preciseEdit,
  String colourPaletteId = '',
  List<String> designStyleIds = const [],
  String otherStyle = '',
  bool keepLayout = true,
  List<String> renovationScopeIds = const [],
  String flooringNotes = '',
  String removeItems = '',
  String roomTypeId = '',
  Map<String, String> roomItemChoices = const {},
  bool wholeRoomDirection = false,
}) {
  final type = resolveRoomType(roomTypeId, roomName);
  final scope = buildRenovationScopePrompt(
    scopeIds: renovationScopeIds,
    flooringNotes: flooringNotes,
    removeItems: removeItems,
    roomType: type,
    coordinatedDesign: wholeRoomDirection && !preciseEdit,
  );
  final itemPrompt = buildRoomItemsPrompt(
    type,
    roomItemChoices,
    renovationScopeIds,
  );
  final hasChanges = hasRoomChanges(
    type,
    roomItemChoices,
    renovationScopeIds,
    removeItems,
  );
  final treatment = preciseEdit
      ? 'PRECISION EDIT: Change only the explicitly requested area. Do not reinterpret the rest of the room.'
      : 'EXPLORATION: Create a coordinated renovation of the requested finishes, cabinetry and fittings while retaining the identity of this real room. This is a renovation concept, not a tiny isolated correction.';
  final protections =
      protectedFeatures.trim().isEmpty ||
          hasNoProtectedFinishes(protectedFeatures)
      ? 'No additional finishes or fittings have been marked as protected. Follow the layout and edit-scope restrictions below.'
      : 'MUST RETAIN: ${protectedFeatures.trim()}. Protected features take priority over style and colour suggestions.';
  final styleNames = [
    for (final id in canonicalStyleIds(designStyleIds))
      if (designStyles[id] != null) designStyles[id]!,
  ];
  final layout = preciseEdit || keepLayout
      ? 'LAYOUT: Keep the existing walls, openings, window sizes, room proportions, camera viewpoint and positions of the main room elements. Update the requested surfaces and fittings in place.${type == 'kitchen' ? ' Do not relocate the peninsula, sink or appliance tower unless explicitly instructed.' : ''}'
      : 'LAYOUT: Internal furniture or cabinetry layout exploration is allowed within the existing room. Keep the outer walls, openings and viewpoint; do not invent structural changes or extra windows and doors.';
  final style = [
    ...styleNames,
    if (otherStyle.trim().isNotEmpty) otherStyle.trim(),
  ];
  final requestedChanges = !preciseEdit && isWholeRoomRequest(instructions)
      ? (wholeRoomDirection
            ? 'Create a coordinated whole-room renovation using the design direction below. Retain the agreed layout and protected items; respect explicit Keep / Replace overrides.'
            : 'Create a coordinated whole-room renovation across the selected finishes, cabinetry and fittings, including the surrounding visible surfaces within the selected scope. Retain the agreed layout and protected items. Cleanup/staging is allowed only when explicitly selected.')
      : instructions.trim();
  return '''Use the attached photograph(s) of the real $roomName as the visual source. If no room image is attached, ask for it before generating a design.
ROOM TYPE: ${roomTypes[type]}. Use the actual photographs to resolve visible details; the room type is a preference, not proof of what is present.
$treatment
Requested design changes: ${requestedChanges.isEmpty ? (hasChanges
            ? 'Apply the selected changes listed below.'
            : preciseEdit
            ? 'No specific edit was provided. Ask for a narrow instruction; do not invent one.'
            : 'Suggest a tasteful, achievable renovation concept.') : requestedChanges}
$protections
$layout
${!preciseEdit && wholeRoomDirection ? 'WHOLE-ROOM DESIGN DIRECTION: Use the photographs to propose a coordinated renovation appropriate to this room. Consider flooring, wall finishes, cabinetry and work surfaces where present, suitable modern fittings/appliances, layered lighting, materials and restrained furniture/accessory styling. Remove everyday loose clutter such as freestanding bins and washing-up for the concept. Do not retain visibly dated finishes merely because they appear in the source photo. These are design suggestions to review, not measured construction advice. Explicit user instructions and KEEP choices override this direction. Preserve the agreed layout, useful storage, functional or uncertain equipment and the actual outside view. Ask before removing an uncertain fixed fitting; remove a wall telephone only when explicitly requested. Do not invent structural openings, hidden appliances or additional built-in elements.' : ''}
$scope
$itemPrompt
${style.isEmpty ? '' : 'DESIGN STYLE: ${style.join(' + ')}. Blend the selected influences coherently. Style is guidance only; apply it within the requested scope and never at the expense of protected features.'}
${paletteById(colourPaletteId)?.prompt(precise: preciseEdit) ?? ''}
${preciseEdit ? 'Keep unselected regions consistent. Do not silently remove items outside the target area. A marked-up reference or crop limits the intended change; it is not permission to redesign the rest of the room.' : 'Coordinate the requested changes across the room. Where new storage is requested, depict usable doors, panels and shelving appropriate to that request rather than blank decorative cladding. Do not silently remove items outside the requested renovation scope.'}
Do not add extra windows, doors, walls, alcoves or furniture unless asked. Preserve useful existing storage unless its removal is explicitly requested. Resolve unclear instructions conservatively; ask about genuinely conflicting requirements rather than inventing a new brief.
Produce one photorealistic renovation concept. This is visual inspiration only, not a measured structural or construction plan.''';
}
