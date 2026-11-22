import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'models.dart';

class BackupFailure implements Exception {
  final String message;
  const BackupFailure(this.message);
  @override
  String toString() => message;
}

/// Versioned portable project data. Contains no AI connection credentials.
class ProjectBackup {
  static const maxFileBytes = 100 * 1024 * 1024;
  static const maxPhotoBytes = 64 * 1024 * 1024;
  final RenovationProject project;
  final List<RenovationRoom> rooms;
  final List<DesignVersion> designs;
  final Map<String, Uint8List> photos;

  ProjectBackup({
    required this.project,
    required this.rooms,
    required this.designs,
    required this.photos,
  });

  int get photoBytes =>
      photos.values.fold(0, (total, bytes) => total + bytes.length);

  /// Export time and JSON key order do not make an unchanged file a new revision.
  String get contentSignature {
    Object? ordered(Object? value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()..sort();
        return {for (final key in keys) key: ordered(value[key])};
      }
      if (value is List) return value.map(ordered).toList();
      return value;
    }

    final sortedRooms = [...rooms]..sort((a, b) => a.id.compareTo(b.id));
    final sortedDesigns = [...designs]..sort((a, b) => a.id.compareTo(b.id));
    return sha256
        .convert(
          utf8.encode(
            jsonEncode(
              ordered({
                'project': project.toMap(),
                'rooms': sortedRooms.map((room) => room.toMap()).toList(),
                'designs': sortedDesigns
                    .map((design) => design.toMap())
                    .toList(),
                'photos': {
                  for (final entry in photos.entries)
                    entry.key: sha256.convert(entry.value).toString(),
                },
              }),
            ),
          ),
        )
        .toString();
  }

  Uint8List encode() {
    if (photoBytes > maxPhotoBytes) {
      throw const BackupFailure(
        'This prototype supports up to 64 MB of photos per project backup.',
      );
    }
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'renovision.project',
          'version': 2,
          'exportedAt': DateTime.now().toUtc().toIso8601String(),
          'project': project.toMap(),
          'rooms': rooms.map((room) => room.toMap()).toList(),
          'designs': designs.map((design) => design.toMap()).toList(),
          'photos': photos.map(
            (id, bytes) => MapEntry(id, {
              'data': base64Encode(bytes),
              'sha256': sha256.convert(bytes).toString(),
            }),
          ),
        }),
      ),
    );
    // Validate our own exports too: a missing reference is never a valid backup.
    ProjectBackup.decode(bytes);
    return bytes;
  }

  static ProjectBackup decode(Uint8List bytes) {
    if (bytes.length > maxFileBytes) {
      throw const BackupFailure('Backup is larger than the 100 MB file limit.');
    }
    try {
      final root = _map(jsonDecode(utf8.decode(bytes)));
      if (root['format'] != 'renovision.project' ||
          ![1, 2].contains(root['version'])) {
        throw const BackupFailure(
          'Choose a supported Renovision project backup (.renovision.json).',
        );
      }
      final projectData = _map(root['project']);
      _record(projectData, 'name');
      final project = RenovationProject.fromMap(projectData);
      final roomData = _list(root['rooms'], 1000).map(_map).toList();
      final designData = _list(root['designs'], 5000).map(_map).toList();
      final photoData = _map(root['photos']);
      if (photoData.length > 6000) {
        throw const BackupFailure('Too many photos in this backup.');
      }
      for (final room in roomData) {
        _record(room, 'name');
        if (room['deleted'] != null && room['deleted'] is! bool) {
          throw const FormatException();
        }
        for (final field in ['projectId', 'originalId']) {
          _string(room[field]);
        }
        for (final field in [
          'instructions',
          'protectedFeatures',
          'correctionInstructions',
        ]) {
          _optionalText(room[field]);
        }
        _optionalText(room['approvedDesignId']);
        _optionalText(room['primaryPhotoId']);
        _optionalText(room['colourPaletteId']);
        _optionalText(room['otherStyle']);
        _optionalText(room['flooringNotes']);
        _optionalText(room['removeItems']);
        _optionalText(room['roomTypeId']);
        if (room['automaticLiveName'] != null &&
            room['automaticLiveName'] is! bool) {
          throw const FormatException();
        }
        if (room['roomItemChoices'] != null) {
          final choices = _map(room['roomItemChoices']);
          if (choices.length > 100 ||
              choices.entries.any(
                (entry) =>
                    entry.key.isEmpty ||
                    entry.key.length > 100 ||
                    !['keep', 'replace'].contains(entry.value),
              )) {
            throw const FormatException();
          }
        }
        if (room['renovationScopeIds'] != null) {
          _list(room['renovationScopeIds'], 20).forEach(_string);
        }
        _optionalText(room['aiPrompt']);
        if (room['aiPrompt'] is String &&
            (room['aiPrompt'] as String).length > 8000) {
          throw const FormatException();
        }
        if (room['analysis'] != null && room['analysis'] is! Map) {
          throw const FormatException();
        }
        if (room['designStyleIds'] != null) {
          _list(room['designStyleIds'], 40).forEach(_string);
        }
        if (room['setupStep'] != null &&
            (room['setupStep'] is! int ||
                (room['setupStep'] as int) < 0 ||
                (room['setupStep'] as int) > 3)) {
          throw const FormatException();
        }
        for (final field in ['conceptCount', 'precisionConceptCount']) {
          if (room[field] != null &&
              (room[field] is! int ||
                  (room[field] as int) < 1 ||
                  (room[field] as int) > 3)) {
            throw const FormatException();
          }
        }
        for (final field in [
          'preciseEdit',
          'keepLayout',
          'fullRenovation',
          'useAiPrompt',
          'setupComplete',
          'compareStyles',
        ]) {
          if (room[field] != null && room[field] is! bool) {
            throw const FormatException();
          }
        }
        if (room['additionalPhotoIds'] != null) {
          _list(room['additionalPhotoIds'], 5).forEach(_string);
        }
      }
      for (final design in designData) {
        _record(design, 'title');
        if (design['supportingImageIds'] != null) {
          _list(design['supportingImageIds'], 6).forEach(_string);
        }
        for (final field in ['roomId', 'imageId']) {
          _string(design[field]);
        }
        for (final field in [
          'parentId',
          'sourceImageId',
          'aiProvider',
          'aiModel',
          'providerRequestId',
          'prompt',
        ]) {
          _optionalText(design[field]);
        }
        if (design['favourite'] is! bool ||
            design['rejected'] is! bool ||
            (design['deleted'] != null && design['deleted'] is! bool)) {
          throw const FormatException();
        }
      }
      final rooms = roomData.map(RenovationRoom.fromMap).toList();
      final designs = designData.map(DesignVersion.fromMap).toList();
      final byRoom = {for (final room in rooms) room.id: room};
      final byDesign = {for (final design in designs) design.id: design};
      if (byRoom.length != rooms.length || byDesign.length != designs.length) {
        throw const FormatException();
      }
      final requiredPhotos = <String>{};
      for (final room in rooms) {
        if (room.projectId != project.id) throw const FormatException();
        final validPaintSources = {
          ...room.photoIds,
          ...designs
              .where((design) => design.roomId == room.id)
              .map((design) => design.imageId),
        };
        if (room.paintDrafts.length > 100 ||
            !room.paintDrafts.keys.every(validPaintSources.contains)) {
          throw const BackupFailure('Backup has unrelated paint drafts.');
        }
        requiredPhotos.addAll(room.paintDrafts.keys);
        if (room.photoIds.toSet().length != room.photoIds.length ||
            !room.photoIds.contains(room.primaryId)) {
          throw const FormatException();
        }
        requiredPhotos.addAll(room.photoIds);
        final analysis = room.analysis;
        if (analysis != null) {
          final validImages = {
            ...room.photoIds,
            ...designs.where((d) => d.roomId == room.id).map((d) => d.imageId),
          };
          if (!validImages.contains(analysis.sourceImageId) ||
              !analysis.supportingImageIds.every(room.photoIds.contains)) {
            throw const BackupFailure('Backup has unrelated analysis photos.');
          }
          requiredPhotos.add(analysis.sourceImageId);
          requiredPhotos.addAll(analysis.supportingImageIds);
        }
        if (room.useAiPrompt &&
            (analysis == null || room.aiPrompt.trim().isEmpty)) {
          throw const BackupFailure('Backup has an incomplete AI prompt.');
        }
        if (room.approvedDesignId != null &&
            (byDesign[room.approvedDesignId]?.roomId != room.id ||
                byDesign[room.approvedDesignId]?.deleted == true)) {
          throw const BackupFailure('Backup has an invalid approved baseline.');
        }
      }
      for (final design in designs) {
        final room = byRoom[design.roomId];
        if (room == null) throw const FormatException();
        if (design.paintRecipe != null &&
            (design.sourceImageId == null ||
                design.aiProvider != null ||
                design.aiModel != null ||
                design.providerRequestId != null ||
                design.recipe != null)) {
          throw const BackupFailure(
            'Local paint has invalid source or AI provenance.',
          );
        }
        final savedAnalysis = design.recipe?.analysis;
        if (savedAnalysis != null) {
          final validImages = {
            ...room.photoIds,
            ...designs.where((d) => d.roomId == room.id).map((d) => d.imageId),
          };
          if (!validImages.contains(savedAnalysis.sourceImageId) ||
              !savedAnalysis.supportingImageIds.every(room.photoIds.contains)) {
            throw const BackupFailure(
              'Saved design settings reference unrelated analysis photos.',
            );
          }
        }
        requiredPhotos.add(design.imageId);
        if (design.parentId != null &&
            byDesign[design.parentId]?.roomId != design.roomId) {
          throw const BackupFailure(
            'Backup has a missing or unrelated parent version.',
          );
        }
        if (design.sourceImageId != null) {
          final validSource =
              room.photoIds.contains(design.sourceImageId) ||
              designs.any(
                (other) =>
                    other.roomId == design.roomId &&
                    other.imageId == design.sourceImageId,
              );
          if (!validSource) {
            throw const BackupFailure('Backup has an unrelated source image.');
          }
          requiredPhotos.add(design.sourceImageId!);
        }
        if (design.supportingImageIds.toSet().length !=
                design.supportingImageIds.length ||
            !design.supportingImageIds.every(room.photoIds.contains)) {
          throw const FormatException();
        }
        requiredPhotos.addAll(design.supportingImageIds);
      }
      // Validate ancestry before any storage writes, including longer cycles.
      final done = <String>{};
      for (final design in designs) {
        final path = <String>{};
        String? current = design.id;
        while (current != null && !done.contains(current)) {
          if (!path.add(current)) {
            throw const BackupFailure(
              'Backup contains a cycle in version history.',
            );
          }
          current = byDesign[current]!.parentId;
        }
        done.addAll(path);
      }
      if (photoData.length != requiredPhotos.length ||
          !requiredPhotos.every(photoData.containsKey)) {
        throw const BackupFailure(
          'Backup has missing or unexpected photo data.',
        );
      }
      final photos = <String, Uint8List>{};
      var total = 0;
      for (final entry in photoData.entries) {
        final data = _map(entry.value);
        final photo = base64Decode(_string(data['data']));
        total += photo.length;
        if (photo.isEmpty || total > maxPhotoBytes) {
          throw const BackupFailure(
            'Invalid photo data or project exceeds the 64 MB photo limit.',
          );
        }
        if (sha256.convert(photo).toString() != data['sha256']) {
          throw const BackupFailure(
            'A photo failed its integrity check. Nothing has been restored.',
          );
        }
        photos[entry.key] = photo;
      }
      return ProjectBackup(
        project: project,
        rooms: rooms,
        designs: designs,
        photos: photos,
      );
    } on BackupFailure {
      rethrow;
    } catch (_) {
      throw const BackupFailure(
        'This backup is incomplete or invalid. Nothing has been restored.',
      );
    }
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is! Map<String, dynamic>) throw const FormatException();
    return value;
  }

  static List<dynamic> _list(dynamic value, int limit) {
    if (value is! List || value.length > limit) throw const FormatException();
    return value;
  }

  static String _string(dynamic value) {
    if (value is! String || value.trim().isEmpty) throw const FormatException();
    return value;
  }

  static void _optionalText(dynamic value) {
    if (value != null && value is! String) throw const FormatException();
  }

  static void _record(Map<String, dynamic> value, String title) {
    if (_string(value['id']).length > 256) throw const FormatException();
    _string(value[title]);
    DateTime.parse(_string(value['created']));
  }
}
