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

Future<List<Package>> fetchPackagesInfo(Iterable<String> packages) async {
  final pkgFutures = <Future<PubPackage>>[];
  final metricsFutures = <Future<PackageMetrics?>>[];
  for (final package in packages) {
    pkgFutures.add(client.packageInfo(package));
    metricsFutures.add(client.packageMetrics(package));
  }

  final pkgs = await Future.wait(pkgFutures);
  final metrics = await Future.wait(metricsFutures);

  final metricMap = <String, PackageMetrics>{};

  for (final metric in metrics) {
    if (metric != null) {
      metricMap[metric.scorecard.packageName] = metric;
    }
  }

  final pkgList = <Package>[];

  for (final pkg in pkgs) {
    final metric = metricMap[pkg.name];
    final card = metric?.scorecard;
    final score = metric?.score;

    pkgList.add(
      Package(
        name: pkg.name,
        version: pkg.version,
        description: pkg.description,
        url: pkg.url,
        changelogUrl: pkg.changelogUrl,
        grantedPoints: card?.grantedPubPoints,
        maxPoints: card?.maxPubPoints,
        likeCount: score?.likeCount,
        popularityScore: score?.popularityScore,
        lastUpdated: score?.lastUpdated,
      ),
    );
  }

  return pkgList;
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
  return fetchPackagesInfo(googlePkgs);
}

/// Retrieves all the flutter favorites
Future<List<Package>> fetchFlutterFavorites() async {
  final favorites = await client.fetchFlutterFavorites();
  return fetchPackagesInfo(favorites);
}

/// Retrieves a limited list of sorted packages
Future<List<Package>> fetchSortedPackages(
  SearchOrder sort, {
  int limit = 100,
}) async {
  final searchResults = await client.search('', sort: sort);
  final results = await _recursivePaging(searchResults, limit: limit);
  final sorted = results.map((r) => r.package);

  return fetchPackagesInfo(sorted);
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
