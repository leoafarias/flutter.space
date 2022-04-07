import 'dart:async';

import 'package:functions_framework/functions_framework.dart';
import 'package:gh_trend/gh_trend.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:server/helpers.dart';
import 'package:shelf_plus/shelf_plus.dart';

@CloudFunction()
FutureOr<Response> function(Request request) {
  final app = Router().plus;
  app.get('/', (Request request) {
    return Response.ok('hello-world');
  });

  app.get('/cache', (Request request) async {
    await fetchAndCacheRequests();
    return Response.ok('cache');
  });

  app.get('/flutter-favorites', (Request request) {
    return fetchFlutterFavorites();
  });

  app.get('/google-packages', (Request request) {
    return fetchGooglePackages();
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

  app.get('/packages/most-popular', (Request request) async {
    return fetchSortedPackages(SearchOrder.popularity);
  });

  app.get('/packages/most-liked', (Request request) async {
    return fetchSortedPackages(SearchOrder.like);
  });

  app.get('/packages/recently-created', (Request request) async {
    return fetchSortedPackages(SearchOrder.created);
  });

  app.get('/packages/recently-updated', (Request request) async {
    return fetchSortedPackages(SearchOrder.updated);
  });

  return app(request);
}
