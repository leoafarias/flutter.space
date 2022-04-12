import 'package:gh_trend/gh_trend.dart';
import 'package:http/http.dart' as http;
import 'package:http_extensions/http_extensions.dart';
import 'package:http_extensions_cache/http_extensions_cache.dart';
import 'package:pub_api_client/pub_api_client.dart';

final client = PubClient(
    client: ExtendedClient(
  inner: http.Client() as http.BaseClient,
  extensions: [
    CacheExtension(
      defaultOptions: CacheOptions(
        store: MemoryCacheStore(),
      ),
    ),
  ],
));

class Package {
  const Package({
    required this.name,
    required this.version,
    required this.description,
    required this.url,
    required this.changelogUrl,
    required this.grantedPoints,
    required this.maxPoints,
    required this.likeCount,
    required this.popularityScore,
    required this.lastUpdated,
  });

  final String name;

  final String version;
  final String description;
  final String url;
  final String changelogUrl;

  final int? grantedPoints;
  final int? maxPoints;
  final int? likeCount;
  final double? popularityScore;
  final DateTime? lastUpdated;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'description': description,
      'url': url,
      'changelogUrl': changelogUrl,
      'grantedPoints': grantedPoints.toString(),
      'maxPoints': maxPoints.toString(),
      'likeCount': likeCount.toString(),
      'popularityScore': popularityScore.toString(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}

Future<void> fetchAndCacheRequests() async {
  final futures = <Future>[];
  futures.add(fetchFlutterFavorites());
  futures.add(fetchGooglePackages());
  futures.add(fetchDartTrendingRepos(GhTrendDateRange.today));
  futures.add(fetchDartTrendingRepos(GhTrendDateRange.thisWeek));
  futures.add(fetchDartTrendingRepos(GhTrendDateRange.thisMonth));
  futures.add(fetchSortedPackages(SearchOrder.popularity));
  futures.add(fetchSortedPackages(SearchOrder.like));
  futures.add(fetchSortedPackages(SearchOrder.created));
  futures.add(fetchSortedPackages(SearchOrder.updated));
  await Future.wait(futures);
}

// Simple memory cache to avoid over fetching on pub.dev API
final packageInfoCache = <String, Package>{};

Future<Package> fetchPackageInfo(String packageName) async {
  Future<PubPackage> infoFuture;
  Future<PackageMetrics?> metricsFuture;

  if (packageInfoCache[packageName] != null) {
    return Future.value(packageInfoCache[packageName]);
  } else {
    metricsFuture = client.packageMetrics(packageName);
    infoFuture = client.packageInfo(packageName);
  }

  final metrics = await metricsFuture;
  final info = await infoFuture;

  final card = metrics?.scorecard;
  final score = metrics?.score;

  final package = Package(
    name: info.name,
    version: info.version,
    description: info.description,
    url: info.url,
    changelogUrl: info.changelogUrl,
    grantedPoints: card?.grantedPubPoints,
    maxPoints: card?.maxPubPoints,
    likeCount: score?.likeCount,
    popularityScore: score?.popularityScore,
    lastUpdated: score?.lastUpdated,
  );

  packageInfoCache[packageName] = package;

  return package;
}

Future<List<Package>> fetchPackagesData(Iterable<String> packages) async {
  final pkgFutures = <Future<Package>>[];

  for (final package in packages) {
    pkgFutures.add(fetchPackageInfo(package));
  }

  return await Future.wait(pkgFutures);
}

final _trendingCache = {
  GhTrendDateRange.today: <GithubRepoItem>[],
  GhTrendDateRange.thisWeek: <GithubRepoItem>[],
  GhTrendDateRange.thisMonth: <GithubRepoItem>[]
};

Future<List<GithubRepoItem>> fetchDartTrendingRepos(
  GhTrendDateRange timePeriod,
) async {
  var data = _trendingCache[timePeriod];
  if (data == null || data.isEmpty) {
    data = await ghTrendingRepositories(
      programmingLanguage: 'dart',
      dateRange: timePeriod,
    );

    _trendingCache[timePeriod] = data;
  }

  return data;
}

/// Retrieves all the flutter favorites
Future<List<Package>> fetchGooglePackages() async {
  final googlePkgs = await client.fetchGooglePackages();
  return fetchPackagesData(googlePkgs);
}

/// Retrieves all the flutter favorites
Future<List<Package>> fetchFlutterFavorites() async {
  final favorites = await client.fetchFlutterFavorites();
  return fetchPackagesData(favorites);
}

/// Retrieves a limited list of sorted packages
Future<List<Package>> fetchSortedPackages(
  SearchOrder sort, {
  int limit = 100,
}) async {
  final searchResults = await client.search('', sort: sort);
  final results = await _recursivePaging(searchResults, limit: limit);
  final sorted = results.map((r) => r.package);

  return fetchPackagesData(sorted);
}

Future<List<PackageResult>> _recursivePaging(
  SearchResults prevResults, {
  required int limit,
}) async {
  final packages = prevResults.packages;
  // If limit is set and has reached limit
  // trim results to limit and return
  if (limit > 0 && packages.length >= limit) {
    packages.length = limit;
    return packages;
  }

  if (prevResults.next != null) {
    final results = await client.nextPage(prevResults.next ?? '');
    final nextResults = await _recursivePaging(
      results,
      limit: limit - results.packages.length,
    );
    packages.addAll(nextResults);
  }

  return packages;
}
