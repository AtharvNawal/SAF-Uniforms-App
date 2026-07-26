import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/entities/gallery_photo.dart';
import '../domain/repositories/gallery_repository.dart';

const String _tag = 'gallery.repo';
const String _bucket = 'saf-uniforms.firebasestorage.app';

class GalleryRepositoryImpl implements GalleryRepository {
  GalleryRepositoryImpl({
    required FirebaseFirestore firestore,
    required String uid,
  })  : _firestore = firestore,
        _uid = uid,
        _storage = FirebaseStorage.instanceFor(bucket: 'gs://$_bucket');

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _uid;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('gallery');

  Reference _storageRef(String photoId) =>
      _storage.ref().child('user_photos/$_uid/$photoId.jpg');

  @override
  Stream<List<GalleryPhoto>> watchPhotos() {
    developer.log('watchPhotos: subscribing uid=$_uid', name: _tag, level: 800);
    if (_uid.isEmpty) return const Stream.empty();
    return _col
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_docToPhoto).toList(growable: false));
  }

  @override
  Future<Result<GalleryPhoto>> uploadPhoto({
    required List<int> imageBytes,
    String dressCode = '',
    void Function(double progress)? onProgress,
  }) async {
    final photoId = _uuid.v4();
    developer.log(
        'uploadPhoto: start id=$photoId bytes=${imageBytes.length} uid=$_uid',
        name: _tag,
        level: 800);
    try {
      final ref = _storageRef(photoId);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000, immutable',
      );
      final task = ref.putData(Uint8List.fromList(imageBytes), metadata);

      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress?.call(snap.bytesTransferred / snap.totalBytes);
        }
      });

      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();
      developer.log('uploadPhoto: storage ok url=$url', name: _tag, level: 800);

      final now = DateTime.now();
      final data = <String, dynamic>{
        'url': url,
        'thumbnailUrl': url,
        'uploadedAt': Timestamp.fromDate(now),
        'dressCode': dressCode,
      };
      await _col.doc(photoId).set(data);
      developer.log('uploadPhoto: firestore ok id=$photoId',
          name: _tag, level: 800);

      return Ok(GalleryPhoto(
        id: photoId,
        url: url,
        thumbnailUrl: url,
        uploadedAt: now,
        dressCode: dressCode,
      ));
    } catch (e, st) {
      developer.log('uploadPhoto: failed id=$photoId',
          name: _tag, error: e, stackTrace: st, level: 1000);
      return Err(StorageFailure('Upload failed: $e'));
    }
  }

  @override
  Future<Result<void>> deletePhoto(String photoId) async {
    developer.log('deletePhoto: start id=$photoId uid=$_uid',
        name: _tag, level: 800);
    try {
      await _storageRef(photoId).delete();
      developer.log('deletePhoto: storage ok', name: _tag, level: 800);
      await _col.doc(photoId).delete();
      developer.log('deletePhoto: firestore ok', name: _tag, level: 800);
      return const Ok(null);
    } catch (e, st) {
      developer.log('deletePhoto: failed id=$photoId',
          name: _tag, error: e, stackTrace: st, level: 1000);
      return Err(StorageFailure('Delete failed: $e'));
    }
  }

  @override
  Future<Result<void>> updateMetadata({
    required String photoId,
    String? dressCode,
  }) async {
    developer.log('updateMetadata: id=$photoId uid=$_uid',
        name: _tag, level: 800);
    try {
      final data = <String, dynamic>{};
      if (dressCode != null) data['dressCode'] = dressCode;
      if (data.isEmpty) return const Ok(null);
      await _col.doc(photoId).update(data);
      developer.log('updateMetadata: ok id=$photoId', name: _tag, level: 800);
      return const Ok(null);
    } catch (e, st) {
      developer.log('updateMetadata: failed id=$photoId',
          name: _tag, error: e, stackTrace: st, level: 1000);
      return Err(UnknownFailure('Metadata update failed: $e'));
    }
  }

  GalleryPhoto _docToPhoto(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['uploadedAt'];
    return GalleryPhoto(
      id: doc.id,
      url: (d['url'] as String?) ?? '',
      thumbnailUrl: (d['thumbnailUrl'] as String?) ?? '',
      uploadedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      dressCode: (d['dressCode'] as String?) ?? '',
    );
  }
}
