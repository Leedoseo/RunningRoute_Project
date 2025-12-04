import 'package:flutter/material.dart';
import 'package:routelog_project/core/data/models/route_log.dart';
import 'package:routelog_project/core/data/repository/i_route_repository.dart';

class RouteDetailController extends ChangeNotifier {
  final IRouteRepository repo;
  RouteDetailController({required this.repo});

  RouteLog? _route;
  bool _loading = false;
  String? _error;

  RouteLog? get route => _route;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _route = await repo.getById(id);
    } catch (e, stackTrace) {
      _error = e.toString();
      debugPrint('Failed to load route detail: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}