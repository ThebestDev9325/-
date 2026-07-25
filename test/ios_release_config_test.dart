import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS release configuration', () {
    test('uses the production bundle ID and Apple Developer team', () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();

      expect(
          project, contains('PRODUCT_BUNDLE_IDENTIFIER = com.chameulin.app;'));
      expect(project, contains('DEVELOPMENT_TEAM = F9GUZW4R7H;'));
      expect(project, isNot(contains('com.chameulin.chameulin')));
    });

    test('registers the Kakao login URL scheme and allowlist', () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(
        infoPlist,
        contains('kakao7a9530370e39ec27e50f8d38379a0d22'),
      );
      expect(infoPlist, contains('kakaokompassauth'));
      expect(infoPlist, contains('kakaolink'));
    });

    test('targets iOS 15 or newer', () {
      final podfile = File('ios/Podfile').readAsStringSync();
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();

      expect(podfile, contains("platform :ios, '15.0'"));
      expect(project, isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0;')));
      expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 15.0;'));
    });

    test('enables Sign in with Apple for every app build configuration', () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final entitlements = File(
        'ios/Runner/Runner.entitlements',
      ).readAsStringSync();

      expect(
        'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'
            .allMatches(project),
        hasLength(3),
      );
      expect(entitlements, contains('com.apple.developer.applesignin'));
      expect(entitlements, contains('<string>Default</string>'));
    });

    test('includes the registered Firebase iOS application', () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final options = File('lib/firebase_options.dart').readAsStringSync();
      final googleServiceInfo = File(
        'ios/Runner/GoogleService-Info.plist',
      ).readAsStringSync();

      expect(
        options,
        contains('1:931900199890:ios:2836fdb6177e1341b4ee0b'),
      );
      expect(googleServiceInfo, contains('com.chameulin.app'));
      expect(
        project,
        contains('GoogleService-Info.plist in Resources'),
      );
    });
  });
}
