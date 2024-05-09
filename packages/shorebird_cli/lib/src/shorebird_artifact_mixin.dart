import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:shorebird_cli/src/command.dart';
import 'package:shorebird_cli/src/logger.dart';
import 'package:shorebird_cli/src/shorebird_env.dart';

mixin ShorebirdArtifactMixin on ShorebirdCommand {
  String get aarLibraryPath {
    final projectRoot = shorebirdEnv.getShorebirdProjectRoot()!;
    return p.joinAll([
      projectRoot.path,
      'build',
      'host',
      'outputs',
      'repo',
    ]);
  }

  String aarArtifactDirectory({
    required String packageName,
    required String buildNumber,
  }) =>
      p.joinAll([
        aarLibraryPath,
        ...packageName.split('.'),
        'flutter_release',
        buildNumber,
      ]);

  String aarArtifactPath({
    required String packageName,
    required String buildNumber,
  }) =>
      p.join(
        aarArtifactDirectory(
          packageName: packageName,
          buildNumber: buildNumber,
        ),
        'flutter_release-$buildNumber.aar',
      );

  Future<String> extractAar({
    required String packageName,
    required String buildNumber,
    required UnzipFn unzipFn,
  }) async {
    final aarDirectory = aarArtifactDirectory(
      packageName: packageName,
      buildNumber: buildNumber,
    );
    final aarPath = aarArtifactPath(
      packageName: packageName,
      buildNumber: buildNumber,
    );

    final zipDir = Directory.systemTemp.createTempSync();
    final zipPath = p.join(zipDir.path, 'flutter_release-$buildNumber.zip');
    logger.detail('Extracting $aarPath to $zipPath');

    // Copy the .aar file to a .zip file so package:archive knows how to read it
    File(aarPath).copySync(zipPath);
    final extractedZipDir = p.join(
      aarDirectory,
      'flutter_release-$buildNumber',
    );
    // Unzip the .zip file to a directory so we can read the .so files
    await unzipFn(zipPath, extractedZipDir);
    return extractedZipDir;
  }

  /// Returns the .xcarchive directory generated by `flutter build ipa`. This
  /// was traditionally named `Runner.xcarchive`, but can now be renamed.
  Directory? getXcarchiveDirectory() {
    final projectRoot = shorebirdEnv.getShorebirdProjectRoot()!;
    final archiveDirectory = Directory(
      p.join(
        projectRoot.path,
        'build',
        'ios',
        'archive',
      ),
    );

    if (!archiveDirectory.existsSync()) return null;

    return archiveDirectory
        .listSync()
        .whereType<Directory>()
        .firstWhereOrNull((directory) => directory.path.endsWith('.xcarchive'));
  }

  /// Returns the .app directory generated by `flutter build ipa`. This was
  /// traditionally named `Runner.app`, but can now be renamed.
  Directory? getAppDirectory({required Directory xcarchiveDirectory}) {
    final applicationsDirectory = Directory(
      p.join(
        xcarchiveDirectory.path,
        'Products',
        'Applications',
      ),
    );

    if (!applicationsDirectory.existsSync()) {
      return null;
    }

    return applicationsDirectory
        .listSync()
        .whereType<Directory>()
        .firstWhereOrNull((directory) => directory.path.endsWith('.app'));
  }

  static const String appXcframeworkName = 'App.xcframework';

  /// Returns the path to the App.xcframework generated by
  /// `shorebird release ios-framework` or
  /// `shorebird patch ios-framework`.
  String getAppXcframeworkPath() {
    return p.join(getAppXcframeworkDirectory().path, appXcframeworkName);
  }

  /// Returns the [Directory] containing the App.xcframework generated by
  /// `shorebird release ios-framework` or
  /// `shorebird patch ios-framework`.
  Directory getAppXcframeworkDirectory() {
    final projectRoot = shorebirdEnv.getShorebirdProjectRoot()!;
    return Directory(
      p.join(
        projectRoot.path,
        'build',
        'ios',
        'framework',
        'Release',
      ),
    );
  }

  /// Finds the most recently-edited app.dill file in the .dart_tool directory.
  // TODO(bryanoltman): This is an enormous hack – we don't know that this is
  // the correct file.
  File newestAppDill() {
    final projectRoot = shorebirdEnv.getShorebirdProjectRoot()!;
    final dartToolBuildDir = Directory(
      p.join(
        projectRoot.path,
        '.dart_tool',
        'flutter_build',
      ),
    );

    return dartToolBuildDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => p.basename(f.path) == 'app.dill')
        .reduce(
          (a, b) =>
              a.statSync().modified.isAfter(b.statSync().modified) ? a : b,
        );
  }
}
