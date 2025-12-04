import 'package:flutter/material.dart';
import 'package:routelog_project/core/data/models/route_log.dart';
import 'package:routelog_project/core/data/repository/i_route_repository.dart';
import 'package:routelog_project/core/mixins/error_handling_mixin.dart';

class RouteDetailController extends ChangeNotifier with ErrorHandlingMixin {
  final IRouteRepository repo;
  RouteDetailController({required this.repo});

  RouteLog? _route;

  RouteLog? get route => _route;

  Future<void> load(String id) async {
    await handleError(
      () async {
        _route = await repo.getById(id);
      },
      errorMessage: 'Failed to load route detail',
    );
  }
}