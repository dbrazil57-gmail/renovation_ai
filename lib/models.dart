import 'design_palettes.dart';
import 'design_styles.dart';
import 'room_analysis.dart';
import 'renovation_scope.dart';
import 'room_features.dart';
import 'design_recipe.dart';
import 'local_paint.dart';
import 'design_references.dart';
import 'australian_design.dart';

String _storedRoomType(Object? value) {
  final original = (value ?? '').toString();
  String normalized(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'[\s_/-]'), '');
  final candidate = normalized(original);
  for (final entry in roomTypes.entries) {
    if (normalized(entry.key) == candidate ||
        normalized(entry.value) == candidate) {
      return entry.key;
    }
  }
  return original;
}

class RenovationProject {
  final String id;
  final String name;
  final DateTime created;
  final bool archived, deleted;

  RenovationProject({
    required this.id,
    required this.name,
    required this.created,
    this.archived = false,
    this.deleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created': created.toIso8601String(),
    if (archived) 'archived': true,
    if (deleted) 'deleted': true,
  };

  factory RenovationProject.fromMap(Map<dynamic, dynamic> data) =>
      RenovationProject(
        id: data['id'].toString(),
        name: data['name'].toString(),
        created: DateTime.parse(data['created'].toString()),
        archived: data['archived'] == true,
        deleted: data['deleted'] == true,
      );
}

class RenovationRoom {
  final bool deleted;
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
  final AustralianDesignSettings australianSetting;
  final bool preciseEdit;
  final bool keepLayout;
  final bool fullRenovation;
  final int conceptCount;
  final int precisionConceptCount;
  final bool compareStyles;
  final RoomAnalysis? analysis;
  final String aiPrompt;
  final bool useAiPrompt;
  final List<String> renovationScopeIds;
  final String flooringNotes;
  final String removeItems;
  final String roomTypeId;
  final bool automaticLiveName;
  final Map<String, String> roomItemChoices;
  final Map<String, LocalPaintRecipe> paintDrafts;
  final DesignReferences? designReferences;
  final bool useDesignReferences;
  List<String> get photoIds => [originalId, ...additionalPhotoIds];
  String get primaryId => primaryPhotoId ?? originalId;
  String get displayName {
    final legacyLiveName = const {
      'live',
      'live room',
      'live view',
      'room (live)',
      'room (live view)',
      'unspecified (live)',
      'unspecified (live view)',
      'other (live)',
    }.contains(name.trim().toLowerCase());
    if (!automaticLiveName && !legacyLiveName) {
      if (const {
            'unspecified',
            'other room',
          }.contains(name.trim().toLowerCase()) &&
          roomTypeId.isNotEmpty &&
          roomTypeId != 'other') {
        return roomTypes[roomTypeId] ?? name;
      }
      return name;
    }
    final typeName = switch (roomTypeId) {
      'living' => 'Living room',
      '' || 'other' => 'Unspecified',
      _ => roomTypes[roomTypeId] ?? 'Unspecified',
    };
    return '$typeName (Live)';
  }

  final DateTime created;

  RenovationRoom({
    this.deleted = false,
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
    this.australianSetting = const AustralianDesignSettings(),
    this.preciseEdit = false,
    this.keepLayout = true,
    this.fullRenovation = true,
    this.conceptCount = 1,
    this.precisionConceptCount = 1,
    this.compareStyles = true,
    this.analysis,
    this.aiPrompt = '',
    this.useAiPrompt = false,
    this.renovationScopeIds = const [],
    this.flooringNotes = '',
    this.removeItems = '',
    this.roomTypeId = '',
    this.automaticLiveName = false,
    this.roomItemChoices = const {},
    this.paintDrafts = const {},
    this.designReferences,
    this.useDesignReferences = false,
  });

  RenovationRoom copyWith({
    DesignReferences? designReferences,
    bool? useDesignReferences,
    bool? deleted,
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
    AustralianDesignSettings? australianSetting,
    bool? preciseEdit,
    bool? keepLayout,
    bool? fullRenovation,
    int? conceptCount,
    int? precisionConceptCount,
    bool? compareStyles,
    RoomAnalysis? analysis,
    String? aiPrompt,
    bool? useAiPrompt,
    List<String>? renovationScopeIds,
    String? flooringNotes,
    String? removeItems,
    String? roomTypeId,
    bool? automaticLiveName,
    Map<String, String>? roomItemChoices,
    Map<String, LocalPaintRecipe>? paintDrafts,
  }) => RenovationRoom(
    designReferences: designReferences ?? this.designReferences,
    useDesignReferences: useDesignReferences ?? this.useDesignReferences,
    deleted: deleted ?? this.deleted,
    id: id,
    projectId: projectId,
    name: name,
    originalId: originalId,
    additionalPhotoIds: additionalPhotoIds ?? this.additionalPhotoIds,
    primaryPhotoId: primaryPhotoId ?? this.primaryPhotoId,
    colourPaletteId: colourPaletteId ?? this.colourPaletteId,
    designStyleIds: designStyleIds ?? this.designStyleIds,
    otherStyle: otherStyle ?? this.otherStyle,
    australianSetting: australianSetting ?? this.australianSetting,
    preciseEdit: preciseEdit ?? this.preciseEdit,
    keepLayout: keepLayout ?? this.keepLayout,
    fullRenovation: fullRenovation ?? this.fullRenovation,
    conceptCount: conceptCount ?? this.conceptCount,
    precisionConceptCount: precisionConceptCount ?? this.precisionConceptCount,
    compareStyles: compareStyles ?? this.compareStyles,
    analysis: analysis ?? this.analysis,
    aiPrompt: aiPrompt ?? this.aiPrompt,
    useAiPrompt: useAiPrompt ?? this.useAiPrompt,
    renovationScopeIds: renovationScopeIds ?? this.renovationScopeIds,
    flooringNotes: flooringNotes ?? this.flooringNotes,
    removeItems: removeItems ?? this.removeItems,
    roomTypeId: roomTypeId ?? this.roomTypeId,
    automaticLiveName: automaticLiveName ?? this.automaticLiveName,
    roomItemChoices: roomItemChoices ?? this.roomItemChoices,
    paintDrafts: paintDrafts ?? this.paintDrafts,
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
    if (designReferences != null) 'designReferences': designReferences!.toMap(),
    if (useDesignReferences) 'useDesignReferences': true,
    'deleted': deleted,
    'id': id,
    'projectId': projectId,
    'name': name,
    'originalId': originalId,
    'additionalPhotoIds': additionalPhotoIds,
    'primaryPhotoId': primaryPhotoId,
    'colourPaletteId': colourPaletteId,
    'designStyleIds': designStyleIds,
    'otherStyle': otherStyle,
    'australianSetting': australianSetting.toMap(),
    'preciseEdit': preciseEdit,
    'keepLayout': keepLayout,
    'fullRenovation': fullRenovation,
    'conceptCount': conceptCount,
    'precisionConceptCount': precisionConceptCount,
    'compareStyles': compareStyles,
    'analysis': analysis?.toMap(),
    'aiPrompt': aiPrompt,
    'useAiPrompt': useAiPrompt,
    'renovationScopeIds': renovationScopeIds,
    'flooringNotes': flooringNotes,
    'removeItems': removeItems,
    'roomTypeId': roomTypeId,
    'automaticLiveName': automaticLiveName,
    'roomItemChoices': roomItemChoices,
    'paintDrafts': paintDrafts.map(
      (id, recipe) => MapEntry(id, recipe.toMap()),
    ),
    'instructions': instructions,
    'correctionInstructions': correctionInstructions,
    'setupStep': setupStep,
    'setupComplete': setupComplete,
    'protectedFeatures': protectedFeatures,
    'approvedDesignId': approvedDesignId,
    'created': created.toIso8601String(),
  };

  factory RenovationRoom.fromMap(Map<dynamic, dynamic> data) => RenovationRoom(
    designReferences: data['designReferences'] is Map
        ? DesignReferences.fromMap(data['designReferences'] as Map)
        : null,
    useDesignReferences: data['useDesignReferences'] == true,
    deleted: data['deleted'] == true,
    paintDrafts: {
      for (final entry in (data['paintDrafts'] as Map? ?? const {}).entries)
        entry.key as String: LocalPaintRecipe.fromMap(entry.value as Map),
    },
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
    australianSetting: AustralianDesignSettings.fromMap(
      data['australianSetting'] as Map?,
    ),
    preciseEdit: data['preciseEdit'] is bool
        ? data['preciseEdit'] as bool
        : true,
    keepLayout: data['keepLayout'] is bool ? data['keepLayout'] as bool : true,
    fullRenovation: data['fullRenovation'] != false,
    conceptCount: data['conceptCount'] is int
        ? (data['conceptCount'] as int).clamp(1, 3)
        : 1,
    precisionConceptCount: data['precisionConceptCount'] is int
        ? (data['precisionConceptCount'] as int).clamp(1, 3)
        : 1,
    compareStyles: data['compareStyles'] != false,
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
    roomTypeId: _storedRoomType(data['roomTypeId']),
    automaticLiveName: data['automaticLiveName'] == true,
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
  final DesignRecipe? recipe;
  final LocalPaintRecipe? paintRecipe;
  final String id;
  final String roomId;
  final String imageId;
  final String title;
  final String prompt;
  final String? parentId;
  final bool favourite;
  final bool rejected;
  final bool deleted;
  final DateTime created;
  final String? sourceImageId;
  final String? aiProvider;
  final String? aiModel;
  final String? providerRequestId;
  final List<String> supportingImageIds;

  DesignVersion({
    this.recipe,
    this.paintRecipe,
    required this.id,
    required this.roomId,
    required this.imageId,
    required this.title,
    required this.prompt,
    required this.parentId,
    required this.favourite,
    required this.rejected,
    this.deleted = false,
    required this.created,
    this.sourceImageId,
    this.aiProvider,
    this.aiModel,
    this.providerRequestId,
    this.supportingImageIds = const [],
  });

  DesignVersion copyWith({bool? favourite, bool? rejected, bool? deleted}) =>
      DesignVersion(
        recipe: recipe,
        paintRecipe: paintRecipe,
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
        deleted: deleted ?? this.deleted,
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
    'recipe': recipe?.toMap(),
    'paintRecipe': paintRecipe?.toMap(),
    'supportingImageIds': supportingImageIds,
    'favourite': favourite,
    'rejected': rejected,
    'deleted': deleted,
    'created': created.toIso8601String(),
  };

  factory DesignVersion.fromMap(Map<dynamic, dynamic> data) => DesignVersion(
    recipe: data['recipe'] == null ? null : DesignRecipe(data['recipe'] as Map),
    paintRecipe: data['paintRecipe'] == null
        ? null
        : LocalPaintRecipe.fromMap(data['paintRecipe'] as Map),
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
    deleted: data['deleted'] == true,
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
  AustralianDesignSettings australianSetting = const AustralianDesignSettings(),
  bool keepLayout = true,
  List<String> renovationScopeIds = const [],
  String flooringNotes = '',
  String removeItems = '',
  String roomTypeId = '',
  Map<String, String> roomItemChoices = const {},
  bool wholeRoomDirection = false,
  bool conciseDesignDirection = false,
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
$regionalRenovationTerms
$treatment
Requested design changes: ${requestedChanges.isEmpty ? (hasChanges
            ? 'Apply the selected changes listed below.'
            : preciseEdit
            ? 'No specific edit was provided. Ask for a narrow instruction; do not invent one.'
            : 'Suggest a tasteful, achievable renovation concept.') : requestedChanges}
$protections
$layout
${!preciseEdit && wholeRoomDirection ? (conciseDesignDirection ? 'WHOLE-ROOM DESIGN DIRECTION: Render the coordinated proposal within the selected scope. Replace unprotected dated finishes and fittings; remove everyday loose clutter. Preserve the agreed architecture/layout, useful storage, functional or uncertain equipment and actual outside view. Remove a fixed telephone only when explicitly requested. Explicit narrow instructions and KEEP choices override suggestions. Do not invent structural openings, hidden appliances or built-ins.' : 'DESIGN INITIATIVE: A short or empty brief in New design mode is permission to propose a fresh, coordinated interior scheme, not to copy the existing decor. Choose a confident design direction from the selected style/palette, or choose complementary materials and colours when none are selected. Make at least three substantial, room-appropriate changes to unprotected surfaces, furnishings, fittings or lighting where available. A near-identical room with extra plants or a mild recolour is insufficient. Keep explicit narrow instructions, Keep choices and architectural/layout restrictions authoritative; never invent structural changes to create impact.\nWHOLE-ROOM DESIGN DIRECTION: Use the photographs to propose a coordinated renovation appropriate to this room. Consider flooring, wall finishes, cabinetry and work surfaces where present, suitable modern fittings/appliances, layered lighting, materials and restrained furniture/accessory styling. Remove everyday loose clutter such as freestanding bins and washing-up for the concept. Do not retain visibly dated finishes merely because they appear in the source photo. These are design suggestions to review, not measured construction advice. Explicit user instructions and KEEP choices override this direction. Preserve the agreed layout, useful storage, functional or uncertain equipment and the actual outside view. Ask before removing an uncertain fixed fitting; remove a wall telephone only when explicitly requested. Do not invent structural openings, hidden appliances or additional built-in elements.') : ''}
${!preciseEdit && wholeRoomDirection && !renovationScopeIds.contains('lighting') ? 'MAIN LIGHTING: $lightingReplacementInstruction' : ''}
${!preciseEdit && wholeRoomDirection && !conciseDesignDirection ? 'DESIGN SYNTHESIS: Resolve one complete material and lighting scheme before rendering, using the actual photograph and any matching observations or design proposal. Give authorised main surfaces and fittings specific, complementary materials, textures and detailing; establish a clear focal treatment with quieter supporting finishes. Coordinate foreground and visible background within the requested scope. Use convincing material depth, balanced daylight and restrained staging rather than extra ornaments or altered exposure to create impact. Keep the original framing and real outside view. Apply these decisions in the image; do not return a written plan or ask for approval instead.' : ''}
$scope
$itemPrompt
${style.isEmpty ? '' : styleDirection(designStyleIds, other: otherStyle)}
${preciseEdit ? '' : australianSetting.prompt}
${paletteById(colourPaletteId)?.prompt(precise: preciseEdit) ?? ''}
${preciseEdit ? 'Keep unselected regions consistent. Do not silently remove items outside the target area. A marked-up reference or crop limits the intended change; it is not permission to redesign the rest of the room.' : 'Coordinate the requested changes across the room. Where new storage is requested, depict usable doors, panels and shelving appropriate to that request rather than blank decorative cladding. Do not silently remove items outside the requested renovation scope.'}
${!preciseEdit && wholeRoomDirection ? 'Unprotected existing furniture may be replaced in place as part of the coordinated renovation; retain practical seating/storage capacity and circulation. Do not add extra windows, doors, walls, alcoves or unrelated furniture.' : 'Do not add extra windows, doors, walls, alcoves or furniture unless asked.'} Preserve useful existing storage unless its removal is explicitly requested. ${!preciseEdit && wholeRoomDirection ? 'Resolve genuinely conflicting requirements conservatively; ordinary unspecified finish and styling choices are for the designer to propose within the authorised scope.' : 'Resolve unclear instructions conservatively; ask about genuinely conflicting requirements rather than inventing a new brief.'}
Produce one photorealistic renovation concept. This is visual inspiration only, not a measured structural or construction plan.''';
}
