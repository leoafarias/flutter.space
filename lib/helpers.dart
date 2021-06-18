import 'dart:convert';

import 'package:gh_trend/gh_trend.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:shelf/shelf.dart';

final client = PubClient();

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

Future<List<Package>> fetchPackagesInfo(Iterable<String> packages) async {
  final pkgFutures = <Future<PubPackage>>[];
  final metricsFutures = <Future<PackageMetrics>>[];
  for (final package in packages) {
    pkgFutures.add(client.packageInfo(package));
    metricsFutures.add(client.packageMetrics(package));
  }

  final pkgs = await Future.wait(pkgFutures);
  final metrics = await Future.wait(metricsFutures);

  final metricMap = <String, PackageMetrics>{};

  for (final metric in metrics) {
    metricMap[metric.scorecard.packageName] = metric;
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

Future<List<GithubRepoItem>> fetchDartTrendingRepos(
  GhTrendDateRange timePeriod,
) {
  return ghTrendingRepositories(
    programmingLanguage: 'dart',
    dateRange: timePeriod,
  );
}

/// Retrieves all the flutter favorites
Future<List<Package>> fetchFlutterFavorites() async {
  final searchResults = await client.search('is:flutter-favorite');
  final results = await _recursivePaging(searchResults);
  final favorites = results.map((r) => r.package);

  return fetchPackagesInfo(favorites);
}

Future<List<PackageResult>> _recursivePaging(SearchResults prevResults) async {
  final packages = prevResults.packages;
  if (prevResults.next != null) {
    final results = await client.nextPage(prevResults.next ?? '');
    final nextResults = await _recursivePaging(results);
    packages.addAll(nextResults);
  }

  return packages;
}

Response jsonResponse(dynamic result) {
  return Response.ok(
    jsonEncode(result),
    headers: {
      'Content-Type': 'application/json',
    },
  );
}
