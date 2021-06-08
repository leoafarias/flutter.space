import 'dart:async';

import 'package:functions_framework/functions_framework.dart';
import 'package:gh_trend/gh_trend.dart';
import 'package:server/helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_router/shelf_router.dart';

@CloudFunction()
FutureOr<Response> function(Request request) {
  final app = Router().plus;
  app.get('/', (Request request) {
    return Response.ok('hello-world');
  });

  app.get('/flutter-favorites', (Request request) {
    return fetchFlutterFavorites();
  });

  app.get('/trending/today', (Request request) {
    return fetchDartTrendingRepos(GhTrendDateRange.today);
  });

  app.get('/trending/week', (Request request) async {
    return fetchDartTrendingRepos(GhTrendDateRange.thisWeek);
  });

  app.get('/trending/month', (Request request) async {
    return fetchDartTrendingRepos(GhTrendDateRange.thisMonth);
  });

  return app(request);
}
