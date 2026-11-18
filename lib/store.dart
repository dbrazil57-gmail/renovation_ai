import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import 'models.dart';
import 'room_analysis.dart';
import 'ai_service.dart';
import 'project_backup.dart';
import 'file_transfer.dart';
import 'design_palettes.dart';
import 'design_styles.dart';
import 'room_features.dart';
import 'project_documents.dart';

/// Stage 1 local-only prototype storage. Photos are kept in a dedicated box.
/// For production-scale image libraries, move large originals to app-private
/// files while retaining stable IDs in this metadata store.
class RenovisionStore extends ChangeNotifier {
  final Box<dynamic> records;
  final Box<dynamic> photos;
  final AiService ai;
  final AppFiles files;
  late final ProjectDocuments documents;
  int _sequence = 0;
  bool _restoringAi = false;
  Future<void> _aiSettingsQueue = Future.value();

  RenovisionStore({
    required this.records,
    required this.photos,
    AiService? ai,
    AppFiles? files,
  }) : ai = ai ?? AiService(),
       files = files ?? createAppFiles() {
    documents = ProjectDocuments(
      encode: (id) => backupFor(id).encode(),
      autosave: () => autosaveEnabled,
    );
    addListener(documents.changed);
    this.ai.addListener(_rememberAiConnection);
  }

  void _rememberAiConnection() {
    if (_restoringAi) return;
    final snapshot = ai.rememberedConnection;
    _aiSettingsQueue = _aiSettingsQueue
        .catchError((_) {})
        .then((_) async {
          if (snapshot == null) {
            await records.delete('settings:ai_connection');
          } else {
            await records.put('settings:ai_connection', snapshot);
          }
        })
        .catchError((_) {
          ai.connectionNotice = 'AI is connected, but its settings could not be remembered on this device.';
        });
  }

  Future<void> restoreAiConnection() async {
    final saved = records.get('settings:ai_connection');
    if (saved is! Map) return;
    _restoringAi = true;
    try {
      await ai.restoreConnection(saved);
    } finally {
      _restoringAi = false;
    }
  }

  @override
  void dispose() {
    ai.removeListener(_rememberAiConnection);
    removeListener(documents.changed);
    documents.dispose();
    ai.dispose();
    super.dispose();
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';

  RenovationRoom? get resumeRoom {
    final saved = records.get('settings:resume');
    final previous = saved is Map ? roomById(saved['roomId'].toString()) : null;
    if (previous != null && projectById(previous.projectId) != null) {
      return previous;
    }
    final rooms = projects.expand((p) => roomsFor(p.id)).toList()
      ..sort((a, b) => b.created.compareTo(a.created));
    return rooms.isEmpty ? null : rooms.first;
  }

  Future<void> rememberRoom(String roomId) async {
    if (roomById(roomId) == null) return;
    await records.put('settings:resume', {'roomId': roomId});
    notifyListeners();
  }

  bool get autosaveEnabled {
    final settings = records.get('settings:saving');
    return settings is! Map || settings['autosave'] != false;
  }

  Future<void> setAutosaveEnabled(bool enabled) async {
    await records.put('settings:saving', {'autosave': enabled});
    notifyListeners();
  }

  DateTime? get lastStorageCheck {
    final value = records.get('meta:storage_check');
    return value is Map
        ? DateTime.tryParse(value['checkedAt'].toString())
        : null;
  }

  /// Explicit small write/read check; never overwrite any project/photo record.
  /// A successful check proves this session's writes, not restart durability.
  Future<void> checkLocalStorage() async {
    final token = _newId();
    final probe = Uint8List.fromList(token.codeUnits);
    await photos.put('diagnostic:storage_check', probe);
    if (!listEquals(imageFor('diagnostic:storage_check'), probe)) {
      throw StateError('Photo storage read-back failed.');
    }
    await records.put('meta:storage_check', {
      'token': token,
      'checkedAt': DateTime.now().toUtc().toIso8601String(),
    });
    final saved = records.get('meta:storage_check');
    if (saved is! Map || saved['token'] != token) {
      throw StateError('Project storage read-back failed.');
    }
    notifyListeners();
  }

  List<RenovationProject> get projects =>
      records.keys
          .where((key) => key.toString().startsWith('project:'))
          .map((key) => RenovationProject.fromMap(records.get(key) as Map))
          .toList()
        ..sort((a, b) => b.created.compareTo(a.created));

  List<RenovationRoom> roomsFor(String projectId) =>
      records.keys
          .where((key) => key.toString().startsWith('room:'))
          .map((key) => RenovationRoom.fromMap(records.get(key) as Map))
          .where((r) => r.projectId == projectId)
          .toList()
        ..sort((a, b) => b.created.compareTo(a.created));

  List<DesignVersion> get _storedDesigns =>
      records.keys
          .where((key) => key.toString().startsWith('design:'))
          .map((key) => DesignVersion.fromMap(records.get(key) as Map))
          .toList()
        ..sort((a, b) => b.created.compareTo(a.created));

  List<DesignVersion> get allDesigns =>
      _storedDesigns.where((d) => !d.deleted).toList();

  List<DesignVersion> deletedDesignsFor(String roomId) =>
      _storedDesigns.where((d) => d.roomId == roomId && d.deleted).toList();

  bool isDesignDeleted(String id) {
    final value = records.get('design:$id');
    return value is! Map || value['deleted'] == true;
  }

  List<DesignVersion> designsFor(String roomId) =>
      allDesigns.where((d) => d.roomId == roomId).toList();

  RenovationProject? projectById(String id) {
    final value = records.get('project:$id');
    return value is Map ? RenovationProject.fromMap(value) : null;
  }

  String _validName(String value) {
    final name = value.trim();
    if (name.isEmpty || name.length > 80) {
      throw ArgumentError('Use a name between 1 and 80 characters.');
    }
    return name;
  }

  Future<void> renameProject(String id, String name) async {
    final trimmed = _validName(name);
    final current = records.get('project:$id');
    if (current is! Map) throw StateError('Project is unavailable.');
    await records.put('project:$id', {...current, 'name': trimmed});
    notifyListeners();
  }

  Future<void> renameRoom(String id, String name) async {
    final trimmed = _validName(name);
    final current = records.get('room:$id');
    if (current is! Map) throw StateError('Room is unavailable.');
    await records.put('room:$id', {...current, 'name': trimmed});
    notifyListeners();
  }

  RenovationRoom? roomById(String id) {
    final value = records.get('room:$id');
    return value is Map ? RenovationRoom.fromMap(value) : null;
  }

  Uint8List? imageFor(String id) {
    final value = photos.get(id);
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }

  ProjectBackup backupFor(String projectId) {
    final raw = records.get('project:$projectId');
    if (raw is! Map) throw const BackupFailure('Project is unavailable.');
    final rooms = roomsFor(projectId);
    final roomIds = rooms.map((room) => room.id).toSet();
    final designs = _storedDesigns
        .where((design) => roomIds.contains(design.roomId))
        .toList();
    final ids = <String>{
      ...rooms.expand((room) => room.photoIds),
      ...designs.map((design) => design.imageId),
      ...designs.map((design) => design.sourceImageId).whereType<String>(),
      ...designs.expand((design) => design.supportingImageIds),
    };
    final images = <String, Uint8List>{};
    for (final id in ids) {
      final bytes = imageFor(id);
      if (bytes == null) {
        throw const BackupFailure(
          'A project image is missing. Backup was not created.',
        );
      }
      images[id] = Uint8List.fromList(bytes);
    }
    return ProjectBackup(
      project: RenovationProject.fromMap(raw),
      rooms: rooms,
      designs: designs,
      photos: images,
    );
  }

  /// Restore into new identifiers; publish the project last. Roll back only
  /// identifiers allocated by this operation if a write fails.
  Future<RenovationProject> restoreBackup(
    ProjectBackup backup, {
    String? projectName,
  }) async {
    // Callers cannot bypass validation by constructing a ProjectBackup directly.
    final validated = ProjectBackup.decode(backup.encode());
    String recordId(String type) {
      var id = _newId();
      while (records.get('$type:$id') != null) {
        id = _newId();
      }
      return id;
    }

    final restoredBaseName = validated.project.name.replaceFirst(
      RegExp(r'(?:\s+\(restored\))+\s*$', caseSensitive: false),
      '',
    );
    final project = RenovationProject(
      id: recordId('project'),
      name: projectName == null
          ? '$restoredBaseName (restored)'
          : _validName(projectName),
      created: validated.project.created,
    );
    final roomIds = {
      for (final room in validated.rooms) room.id: recordId('room'),
    };
    final designIds = {
      for (final design in validated.designs) design.id: recordId('design'),
    };
    final photoIds = <String, String>{};
    for (final id in validated.photos.keys) {
      var newId = 'photo_${_newId()}';
      while (photos.get(newId) != null) {
        newId = 'photo_${_newId()}';
      }
      photoIds[id] = newId;
    }
    final stagedRecords = <String, Map<String, dynamic>>{};
    for (final room in validated.rooms) {
      stagedRecords['room:${roomIds[room.id]}'] = {
        ...room.toMap(),
        'id': roomIds[room.id],
        'projectId': project.id,
        'originalId': photoIds[room.originalId],
        'additionalPhotoIds': room.additionalPhotoIds
            .map((id) => photoIds[id]!)
            .toList(),
        'primaryPhotoId': room.primaryPhotoId == null
            ? null
            : photoIds[room.primaryPhotoId],
        'approvedDesignId': room.approvedDesignId == null
            ? null
            : designIds[room.approvedDesignId],
        if (room.analysis != null)
          'analysis': {
            ...room.analysis!.toMap(),
            'sourceImageId': photoIds[room.analysis!.sourceImageId],
            'supportingImageIds': room.analysis!.supportingImageIds
                .map((id) => photoIds[id]!)
                .toList(),
          },
      };
    }
    for (final design in validated.designs) {
      stagedRecords['design:${designIds[design.id]}'] = {
        ...design.toMap(),
        'id': designIds[design.id],
        'roomId': roomIds[design.roomId],
        'imageId': photoIds[design.imageId],
        'supportingImageIds': design.supportingImageIds
            .map((id) => photoIds[id]!)
            .toList(),
        'parentId': design.parentId == null ? null : designIds[design.parentId],
        'sourceImageId': design.sourceImageId == null
            ? null
            : photoIds[design.sourceImageId],
      };
    }
    stagedRecords['project:${project.id}'] = project.toMap();
    final writtenPhotos = <String>[];
    final writtenRecords = <String>[];
    try {
      for (final entry in validated.photos.entries) {
        writtenPhotos.add(photoIds[entry.key]!);
        await photos.put(photoIds[entry.key]!, entry.value);
      }
      for (final entry in stagedRecords.entries) {
        writtenRecords.add(entry.key);
        await records.put(entry.key, entry.value);
      }
    } catch (_) {
      var cleanupFailed = false;
      for (final key in writtenRecords.reversed) {
        try {
          await records.delete(key);
        } catch (_) {
          cleanupFailed = true;
        }
      }
      for (final id in writtenPhotos) {
        try {
          await photos.delete(id);
        } catch (_) {
          cleanupFailed = true;
        }
      }
      if (cleanupFailed) {
        throw const BackupFailure(
          'Restore failed and some new records could not be removed. Existing projects were not overwritten. Keep the backup and check storage before retrying.',
        );
      }
      throw const BackupFailure(
        'Restore could not be saved. New records were removed; existing projects are unchanged. Check available storage.',
      );
    }
    notifyListeners();
    return project;
  }

  Future<RenovationProject> createProject(String name) async {
    final project = RenovationProject(
      id: _newId(),
      name: name.trim(),
      created: DateTime.now(),
    );
    await records.put('project:${project.id}', project.toMap());
    notifyListeners();
    return project;
  }

  Future<RenovationRoom> createRoom({
    required String projectId,
    required String name,
    required Uint8List originalImage,
    List<Uint8List> additionalImages = const [],
    String colourPaletteId = '',
    String roomTypeId = '',
    List<String> designStyleIds = const [],
    bool guidedSetup = false,
  }) async {
    _validatePalette(colourPaletteId);
    if (roomTypeId.isNotEmpty && !roomTypes.containsKey(roomTypeId)) {
      throw ArgumentError('Choose an available room type.');
    }
    final styles = canonicalStyleIds(designStyleIds);
    if (styles.any((id) => !designStyles.containsKey(id))) {
      throw ArgumentError('Choose an available design style.');
    }
    _validateRoomPhotos([originalImage, ...additionalImages], existingCount: 0);
    final photoId = 'photo_${_newId()}';
    final added = <String>[];
    try {
      added.add(photoId);
      await photos.put(photoId, originalImage);
      final extraIds = <String>[];
      for (final bytes in additionalImages) {
        final id = 'photo_${_newId()}';
        added.add(id);
        extraIds.add(id);
        await photos.put(id, bytes);
      }
      final room = RenovationRoom(
        id: _newId(),
        projectId: projectId,
        name: name.trim(),
        originalId: photoId,
        additionalPhotoIds: extraIds,
        colourPaletteId: colourPaletteId,
        roomTypeId: roomTypeId,
        designStyleIds: styles,
        preciseEdit: false,
        setupComplete: !guidedSetup,
        instructions: '',
        protectedFeatures: '',
        created: DateTime.now(),
      );
      await records.put('room:${room.id}', room.toMap());
      notifyListeners();
      return room;
    } catch (_) {
      for (final id in added) {
        try {
          await photos.delete(id);
        } catch (_) {}
      }
      rethrow;
    }
  }

  static const maxRoomPhotos = 6;
  Future<void> saveRoomDraft(
    String roomId, {
    required String instructions,
    String? correctionInstructions,
    required String protectedFeatures,
    required List<String> designStyleIds,
    required String otherStyle,
    required bool preciseEdit,
    required bool keepLayout,
    int? conceptCount,
    bool? compareStyles,
    RoomAnalysis? analysis,
    String? aiPrompt,
    bool? useAiPrompt,
    List<String>? renovationScopeIds,
    String? flooringNotes,
    String? removeItems,
    String? roomTypeId,
    Map<String, String>? roomItemChoices,
  }) async {
    final room = roomById(roomId);
    if (room == null) throw StateError('Room is unavailable.');
    await updateRoom(
      room.copyWith(
        instructions: instructions,
        correctionInstructions: correctionInstructions,
        protectedFeatures: protectedFeatures,
        designStyleIds: designStyleIds,
        otherStyle: otherStyle,
        preciseEdit: preciseEdit,
        keepLayout: keepLayout,
        conceptCount: conceptCount,
        compareStyles: compareStyles,
        analysis: analysis,
        aiPrompt: aiPrompt,
        useAiPrompt: useAiPrompt,
        renovationScopeIds: renovationScopeIds,
        flooringNotes: flooringNotes,
        removeItems: removeItems,
        roomTypeId: roomTypeId,
        roomItemChoices: roomItemChoices,
      ),
    );
  }

  void _validatePalette(String id) {
    if (id.isNotEmpty && paletteById(id) == null) {
      throw ArgumentError('Choose an available colour palette.');
    }
  }

  Future<void> setRoomPalette(String roomId, String paletteId) async {
    _validatePalette(paletteId);
    final room = roomById(roomId);
    if (room == null) throw StateError('Room is unavailable.');
    await updateRoom(room.copyWith(colourPaletteId: paletteId));
  }

  void _validateRoomPhotos(
    List<Uint8List> images, {
    required int existingCount,
  }) {
    if (images.isEmpty ||
        images.length + existingCount > maxRoomPhotos ||
        images.any(
          (image) => image.isEmpty || image.length > 18 * 1024 * 1024,
        )) {
      throw ArgumentError(
        'Choose up to 6 room photos, each smaller than 18 MB.',
      );
    }
  }

  Future<List<String>> addRoomPhotos(
    String roomId,
    List<Uint8List> images,
  ) async {
    final room = roomById(roomId);
    if (room == null) throw StateError('Room is unavailable.');
    _validateRoomPhotos(images, existingCount: room.photoIds.length);
    final ids = <String>[];
    try {
      for (final bytes in images) {
        final id = 'photo_${_newId()}';
        ids.add(id);
        await photos.put(id, bytes);
      }
      final latest = roomById(roomId)!;
      if (latest.photoIds.length + ids.length > maxRoomPhotos) {
        throw StateError('Room photo limit reached.');
      }
      await updateRoom(
        latest.copyWith(
          additionalPhotoIds: [...latest.additionalPhotoIds, ...ids],
        ),
      );
      return ids;
    } catch (_) {
      for (final id in ids) {
        try {
          await photos.delete(id);
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> setPrimaryPhoto(String roomId, String photoId) async {
    final room = roomById(roomId);
    if (room == null || !room.photoIds.contains(photoId)) {
      throw ArgumentError('Choose a photo from this room.');
    }
    await updateRoom(room.copyWith(primaryPhotoId: photoId));
  }

  Future<void> updateRoom(RenovationRoom room) async {
    await records.put('room:${room.id}', room.toMap());
    notifyListeners();
  }

  Future<DesignVersion> createDesign({
    required String roomId,
    required Uint8List image,
    required String title,
    required String prompt,
    String? parentId,
    String? sourceImageId,
    String? aiProvider,
    String? aiModel,
    String? providerRequestId,
    List<String> supportingImageIds = const [],
  }) async {
    final photoId = 'photo_${_newId()}';
    await photos.put(photoId, image);
    final design = DesignVersion(
      id: _newId(),
      roomId: roomId,
      imageId: photoId,
      title: title.trim().isEmpty ? 'New design' : title.trim(),
      prompt: prompt,
      parentId: parentId,
      sourceImageId: sourceImageId,
      aiProvider: aiProvider,
      aiModel: aiModel,
      providerRequestId: providerRequestId,
      supportingImageIds: supportingImageIds,
      favourite: false,
      rejected: false,
      created: DateTime.now(),
    );
    await records.put('design:${design.id}', design.toMap());
    notifyListeners();
    return design;
  }

  Future<void> rateDesign(DesignVersion design, {required bool keep}) async {
    final value = records.get('design:${design.id}');
    if (value is! Map || value['deleted'] == true) {
      throw const DesignChangeFailure(
        'Restore this deleted design before reviewing it.',
      );
    }
    await records.put(
      'design:${design.id}',
      DesignVersion.fromMap(value)
          .copyWith(favourite: keep, rejected: !keep)
          .toMap(),
    );
    notifyListeners();
  }

  Future<void> trashDesign(String id) async {
    if (ai.activity.active) {
      throw const DesignChangeFailure(
        'Wait for the current AI request to finish before deleting designs.',
      );
    }
    final value = records.get('design:$id');
    if (value is! Map) {
      throw const DesignChangeFailure('This design is no longer available.');
    }
    final design = DesignVersion.fromMap(value);
    final room = roomById(design.roomId);
    if (room == null || room.photoIds.contains(design.imageId)) {
      throw const DesignChangeFailure(
        'Original room photos cannot be deleted here.',
      );
    }
    if (room.approvedDesignId == id) {
      throw const DesignChangeFailure(
        'This is the approved baseline. Approve the original or another design before deleting it.',
      );
    }
    if (design.deleted) return;
    // Keep image bytes and ancestry: refinements/analysis may still reference them.
    await records.put('design:$id', design.copyWith(deleted: true).toMap());
    notifyListeners();
  }

  Future<void> restoreDesign(String id) async {
    final value = records.get('design:$id');
    if (value is! Map) {
      throw const DesignChangeFailure('This deleted design is unavailable.');
    }
    final design = DesignVersion.fromMap(value);
    if (!design.deleted) return;
    await records.put('design:$id', design.copyWith(deleted: false).toMap());
    notifyListeners();
  }

  /// Removing a favourite returns it to pending review rather than rejecting it.
  Future<void> setFavourite(
    DesignVersion design, {
    required bool favourite,
  }) async {
    final current = records.get('design:${design.id}');
    if (current is! Map) throw StateError('Design no longer exists.');
    final saved = DesignVersion.fromMap(current);
    await records.put(
      'design:${design.id}',
      saved.copyWith(favourite: favourite, rejected: false).toMap(),
    );
    notifyListeners();
  }

  /// Undo a pass without approving the image or making it a favourite.
  Future<void> returnToReview(String designId) async {
    final current = records.get('design:$designId');
    if (current is! Map) throw StateError('Design is unavailable.');
    await records.put('design:$designId', {
      ...current,
      'favourite': false,
      'rejected': false,
    });
    notifyListeners();
  }

  /// Approval is independent of favourites and never changes image bytes.
  Future<void> approveBaseline(String roomId, {String? designId}) async {
    final room = roomById(roomId);
    if (room == null) throw StateError('Room no longer exists.');
    if (designId != null) {
      final value = records.get('design:$designId');
      if (value is! Map) throw StateError('Design no longer exists.');
      final design = DesignVersion.fromMap(value);
      if (design.deleted ||
          design.roomId != roomId ||
          imageFor(design.imageId) == null) {
        throw StateError('Choose an available design from this room.');
      }
    }
    await updateRoom(
      room.copyWith(
        approvedDesignId: designId,
        useOriginalBaseline: designId == null,
      ),
    );
  }
}

class DesignChangeFailure implements Exception {
  final String message;
  const DesignChangeFailure(this.message);
  @override
  String toString() => message;
}
