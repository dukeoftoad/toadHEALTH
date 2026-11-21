import 'package:flutter_test/flutter_test.dart';
import 'package:toad_health/update/update_checker.dart';
import 'package:toad_health/update/version_compare.dart';

/// The self-update flow's pure logic: tag comparison and release parsing,
/// both exercised without any network (mirrors the family's toadFILES and
/// toadPLAYER suites, where the flow was proven).
void main() {
  group('VersionCompare.isNewer', () {
    test('a newer patch is newer', () {
      expect(VersionCompare.isNewer('1.4.0', 'v1.4.1'), isTrue);
    });

    test('the same version is not newer, with or without the v', () {
      expect(VersionCompare.isNewer('1.4.0', 'v1.4.0'), isFalse);
      expect(VersionCompare.isNewer('v1.4.0', '1.4.0'), isFalse);
    });

    test('an older release is not newer', () {
      expect(VersionCompare.isNewer('1.4.0', '1.3.0'), isFalse);
    });

    test('components compare numerically, not lexicographically', () {
      expect(VersionCompare.isNewer('1.9.0', '1.10.0'), isTrue);
      expect(VersionCompare.isNewer('1.10.0', '1.9.0'), isFalse);
    });

    test('short tags are padded ("1.4" == "1.4.0")', () {
      expect(VersionCompare.isNewer('1.4', '1.4.0'), isFalse);
      expect(VersionCompare.isNewer('1.4', '1.4.1'), isTrue);
    });

    test('a pre-release is older than its stable release', () {
      expect(VersionCompare.isNewer('1.4.0', '1.4.0-beta'), isFalse);
      expect(VersionCompare.isNewer('1.4.0-beta', '1.4.0'), isTrue);
    });

    test('a malformed tag never pushes an update', () {
      expect(VersionCompare.isNewer('1.4.0', ''), isFalse);
      expect(VersionCompare.isNewer('1.4.0', 'v'), isFalse);
      expect(VersionCompare.isNewer('1.4.0', 'blob'), isFalse);
    });
  });

  group('GithubReleaseChecker.parseRelease', () {
    test('reads a real-shaped release payload', () {
      const body = '''
{
  "tag_name": "v1.4.0",
  "html_url": "https://github.com/dukeoftoad/toadHEALTH/releases/tag/v1.4.0",
  "body": "The Appearance release.\\r\\n- Theme styles\\r\\n- Night pond",
  "assets": [
    {
      "name": "toadHEALTH.apk",
      "browser_download_url": "https://github.com/dukeoftoad/toadHEALTH/releases/download/v1.4.0/toadHEALTH.apk",
      "size": 9876543
    },
    {
      "name": "toadHEALTH-wear.apk",
      "browser_download_url": "https://github.com/dukeoftoad/toadHEALTH/releases/download/v1.4.0/toadHEALTH-wear.apk",
      "size": 1234567
    }
  ]
}
''';
      final release = GithubReleaseChecker.parseRelease(body);
      expect(release.tagName, 'v1.4.0');
      // CR-LF normalized to plain newlines.
      expect(release.notes, contains('release.\n- Theme styles'));
      // The phone app is offered the phone APK, never the wear build.
      expect(release.apkName, 'toadHEALTH.apk');
      expect(release.apkUrl, isNotNull);
      expect(release.apkUrl, isNot(contains('wear')));
      expect(release.apkSizeBytes, 9876543);
    });

    test('a release with only the wear APK keeps a null url', () {
      const body = '''
{
  "tag_name": "v1.4.0",
  "assets": [
    {"name": "toadHEALTH-wear.apk", "browser_download_url": "https://x/wear", "size": 10}
  ]
}
''';
      final release = GithubReleaseChecker.parseRelease(body);
      expect(release.tagName, 'v1.4.0');
      expect(release.apkUrl, isNull);
    });

    test('a payload without a tag fails with a friendly message', () {
      expect(
        () => GithubReleaseChecker.parseRelease('{"assets": []}'),
        throwsA(isA<UpdateCheckException>()),
      );
    });

    test('garbage fails with a friendly message, not a FormatException', () {
      expect(
        () => GithubReleaseChecker.parseRelease('{not json'),
        throwsA(isA<UpdateCheckException>()),
      );
    });
  });

  group('GithubReleaseChecker.exceptionFor', () {
    test('403 maps to the rate limit', () {
      expect(
        GithubReleaseChecker.exceptionFor(403),
        isA<UpdateCheckRateLimitException>(),
      );
    });

    test('5xx maps to the retryable shape', () {
      expect(
        GithubReleaseChecker.exceptionFor(502),
        isA<UpdateCheckRetryableException>(),
      );
    });

    test('other 4xx maps to the plain friendly error', () {
      expect(
        GithubReleaseChecker.exceptionFor(404),
        isA<UpdateCheckException>(),
      );
      expect(
        GithubReleaseChecker.exceptionFor(404),
        isNot(isA<UpdateCheckRateLimitException>()),
      );
    });
  });
}
