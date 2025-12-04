import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routelog_project/core/data/models/models.dart';
import 'package:routelog_project/core/data/repository/i_route_repository.dart';

class FirestoreRouteRepository implements IRouteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StreamController<void> _changeController = StreamController.broadcast();

  FirestoreRouteRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// 현재 로그인한 사용자의 routes 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _routesCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated. Please login first.');
    }
    return _firestore.collection('users').doc(userId).collection('routes');
  }

  @override
  Future<List<RouteLog>> list({
    String? query,
    String? sort,
    List<String>? tagIds,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _routesCollection;

      // 정렬 적용
      if (sort != null) {
        switch (sort) {
          case 'date_desc':
            q = q.orderBy('startedAt', descending: true);
            break;
          case 'date_asc':
            q = q.orderBy('startedAt', descending: false);
            break;
          case 'distance_desc':
            q = q.orderBy('distanceMeters', descending: true);
            break;
          case 'distance_asc':
            q = q.orderBy('distanceMeters', descending: false);
            break;
          default:
            q = q.orderBy('startedAt', descending: true);
        }
      } else {
        q = q.orderBy('startedAt', descending: true);
      }

      final snapshot = await q.get();
      var routes = snapshot.docs
          .map((doc) => RouteLog.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // 클라이언트 사이드 필터링
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        routes = routes.where((r) {
          return r.title.toLowerCase().contains(lowerQuery) ||
              (r.notes?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }

      if (tagIds != null && tagIds.isNotEmpty) {
        routes = routes.where((r) {
          return r.tags.any((tag) => tagIds.contains(tag.id));
        }).toList();
      }

      return routes;
    } catch (e) {
      throw Exception('Failed to load routes: $e');
    }
  }

  @override
  Future<RouteLog?> getById(String id) async {
    try {
      final doc = await _routesCollection.doc(id).get();
      if (!doc.exists) return null;
      return RouteLog.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get route: $e');
    }
  }

  @override
  Future<RouteLog> create(RouteLog log) async {
    try {
      final data = log.toJson();
      data.remove('id'); // Firestore가 자동으로 ID 생성

      final docRef = await _routesCollection.add(data);
      final created = log.copyWith(id: docRef.id);

      _changeController.add(null);
      return created;
    } catch (e) {
      throw Exception('Failed to create route: $e');
    }
  }

  @override
  Future<RouteLog> update(RouteLog log) async {
    try {
      if (log.id.isEmpty) {
        throw Exception('Cannot update route without ID');
      }

      final data = log.toJson();
      data.remove('id'); // ID는 문서 ID로 관리

      await _routesCollection.doc(log.id).update(data);

      _changeController.add(null);
      return log;
    } catch (e) {
      throw Exception('Failed to update route: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _routesCollection.doc(id).delete();
      _changeController.add(null);
    } catch (e) {
      throw Exception('Failed to delete route: $e');
    }
  }

  @override
  Stream<void> watch() {
    return _changeController.stream;
  }

  void dispose() {
    _changeController.close();
  }
}
