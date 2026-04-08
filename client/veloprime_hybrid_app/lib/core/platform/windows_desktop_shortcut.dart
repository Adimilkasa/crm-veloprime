import 'dart:io';

import 'package:flutter/foundation.dart';

const String _shortcutName = 'VeloPrime CRM';

Future<void> ensureWindowsDesktopShortcut() async {
  if (kIsWeb || !Platform.isWindows || !kReleaseMode) {
    return;
  }

  final executablePath = Platform.resolvedExecutable;
  final normalizedPath = executablePath.toLowerCase();

  if (!normalizedPath.contains(
      '${Platform.pathSeparator}windowsapps${Platform.pathSeparator}')) {
    return;
  }

  final workingDirectory = File(executablePath).parent.path;
  final escapedExecutablePath = _escapePowerShellLiteral(executablePath);
  final escapedWorkingDirectory = _escapePowerShellLiteral(workingDirectory);
  final escapedShortcutName = _escapePowerShellLiteral(_shortcutName);

  final script = '''

\$ErrorActionPreference = 'Stop'

\$targetPath = '$escapedExecutablePath'
if (-not (Test-Path \$targetPath)) { exit 0 }

\$desktopPath = [Environment]::GetFolderPath('DesktopDirectory')
if ([string]::IsNullOrWhiteSpace(\$desktopPath)) { exit 0 }

\$shortcutPath = Join-Path \$desktopPath '$escapedShortcutName.lnk'
if (Test-Path \$shortcutPath) { exit 0 }

\$shell = New-Object -ComObject WScript.Shell
\$shortcut = \$shell.CreateShortcut(\$shortcutPath)
\$shortcut.TargetPath = \$targetPath
\$shortcut.WorkingDirectory = '$escapedWorkingDirectory'
\$shortcut.IconLocation = "\$targetPath,0"
\$shortcut.Description = '$escapedShortcutName'
\$shortcut.Save()
''';

  try {
    final result = await Process.run(
      'powershell',
      const [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
      ].followedBy(['-Command', script]).toList(growable: false),
    );

    if (result.exitCode != 0) {
      debugPrint('Desktop shortcut creation skipped: ${result.stderr}'.trim());
    }
  } catch (error) {
    debugPrint('Desktop shortcut creation failed: $error');
  }
}

String _escapePowerShellLiteral(String value) => value.replaceAll("'", "''");
