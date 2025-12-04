import 'package:flutter/foundation.dart';
import 'package:routelog_project/core/data/models/models.dart';
import 'package:routelog_project/core/data/repository/i_route_repository.dart';
import 'package:routelog_project/core/mixins/error_handling_mixin.dart';

class RoutesController extends ChangeNotifier with ErrorHandlingMixin {
  final IRouteRepository repo;

  RoutesController({required this.repo});

  List<RouteLog> _items = [];
  String _query = '';
  String _sort = 'data_desc';
  List<String> _tagIds = [];

  List<RouteLog> get items => _items;
  String get query => _query;
  String get sort => _sort;
  List<String> get tagIds => _tagIds;

  Future<void> load() async {
    await handleError(
      () async {
        _items = await repo.list(query: _query, sort: _sort, tagIds: _tagIds);
      },
      errorMessage: 'Failed to load routes',
    );
  }

  void setQuery(String q) {
    _query = q;
    load();
  }

  void setSort(String s) {
    _sort = s;
    load();
  }

  void setTags(List<String> ids) {
    _tagIds = ids;
    load();
  }
}