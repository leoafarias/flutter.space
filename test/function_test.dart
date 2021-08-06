import 'dart:io';

import 'package:http/http.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:server/helpers.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

const defaultTimeout = Timeout(Duration(minutes: 5));

void main() {
  test('defaults', () async {
    final proc = await TestProcess.start('dart', ['bin/server.dart']);

    await expectLater(
      proc.stdout,
      emitsThrough('Listening on :8080'),
    );

    final response =
        await get(Uri.parse('http://localhost:8080/packages/most-popular'));
    expect(response.statusCode, 200);
    print(response.body);
    // expect(response.body, 'Hello, World!');

    await expectLater(
      proc.stdout,
      emitsThrough(endsWith('GET     [200] /')),
    );

    proc.signal(ProcessSignal.sigterm);
    await proc.shouldExit(0);

    await expectLater(
      proc.stdout,
      emitsThrough('Received signal SIGTERM - closing'),
    );
  }, timeout: defaultTimeout);

  test('Fetch sorted packages', () async {
    final popular = await fetchSortedPackages(SearchOrder.popularity);
    expect(popular.length, greaterThan(1));
  });
}
