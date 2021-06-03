import 'dart:async';
import 'dart:convert';

import 'package:functions_framework/functions_framework.dart';
import 'package:server/helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

@CloudFunction()
FutureOr<Response> function(Request request) {
  final router = Router();
  router.get('/', (Request request) {
    return Response.ok('hello-world');
  });

  router.get('/flutter-favorites', (Request request) async {
    final favorites = await fetchFlutterFavorites();
    return Response.ok(
      jsonEncode(favorites),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  });

  return router(request);
}
