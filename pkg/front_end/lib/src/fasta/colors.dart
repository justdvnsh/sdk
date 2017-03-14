// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ahe): Orignially copied from sdk/pkg/compiler/lib/src/colors.dart,
// merge these two packages.
library colors;

import 'dart:convert' show JSON;

import 'dart:io'
    show Platform, Process, ProcessResult, StdioType, stderr, stdioType, stdout;

import 'compiler_context.dart' show CompilerContext;

/// ANSI/xterm termcap for setting default colors. Output from Unix
/// command-line program `tput op`.
const String DEFAULT_COLOR = "\x1b[39;49m";

/// ANSI/xterm termcap for setting black text color. Output from Unix
/// command-line program `tput setaf 0`.
const String BLACK_COLOR = "\x1b[30m";

/// ANSI/xterm termcap for setting red text color. Output from Unix
/// command-line program `tput setaf 1`.
const String RED_COLOR = "\x1b[31m";

/// ANSI/xterm termcap for setting green text color. Output from Unix
/// command-line program `tput setaf 2`.
const String GREEN_COLOR = "\x1b[32m";

/// ANSI/xterm termcap for setting yellow text color. Output from Unix
/// command-line program `tput setaf 3`.
const String YELLOW_COLOR = "\x1b[33m";

/// ANSI/xterm termcap for setting blue text color. Output from Unix
/// command-line program `tput setaf 4`.
const String BLUE_COLOR = "\x1b[34m";

/// ANSI/xterm termcap for setting magenta text color. Output from Unix
/// command-line program `tput setaf 5`.
const String MAGENTA_COLOR = "\x1b[35m";

/// ANSI/xterm termcap for setting cyan text color. Output from Unix
/// command-line program `tput setaf 6`.
const String CYAN_COLOR = "\x1b[36m";

/// ANSI/xterm termcap for setting white text color. Output from Unix
/// command-line program `tput setaf 7`.
const String WHITE_COLOR = "\x1b[37m";

/// All the above codes. This is used to compare the above codes to the
/// terminal's. Printing this string should have the same effect as just
/// printing [DEFAULT_COLOR].
const String ALL_CODES = BLACK_COLOR +
    RED_COLOR +
    GREEN_COLOR +
    YELLOW_COLOR +
    BLUE_COLOR +
    MAGENTA_COLOR +
    CYAN_COLOR +
    WHITE_COLOR +
    DEFAULT_COLOR;

const String TERMINAL_CAPABILITIES = """
colors
setaf 0
setaf 1
setaf 2
setaf 3
setaf 4
setaf 5
setaf 6
setaf 7
op
""";

String wrap(String string, String color) {
  return CompilerContext.enableColors
      ? "${color}$string${DEFAULT_COLOR}"
      : string;
}

String black(String string) => wrap(string, BLACK_COLOR);
String red(String string) => wrap(string, RED_COLOR);
String green(String string) => wrap(string, GREEN_COLOR);
String yellow(String string) => wrap(string, YELLOW_COLOR);
String blue(String string) => wrap(string, BLUE_COLOR);
String magenta(String string) => wrap(string, MAGENTA_COLOR);
String cyan(String string) => wrap(string, CYAN_COLOR);
String white(String string) => wrap(string, WHITE_COLOR);

/// True if we should enable colors in output. We enable colors when:
///  1. stdout and stderr are terminals,
///  2. the terminal supports more than 8 colors, and
///  3. the terminal's ANSI color codes matches what we expect.
///
/// Note: do not call this method directly, as it is expensive to
/// compute. Instead, use [CompilerContext.enableColors].
bool computeEnableColors(CompilerContext context) {
  if (Platform.isWindows) {
    if (context.options.verbose) {
      print("Not enabling colors, running on Windows.");
    }
    return false;
  }

  if (stdioType(stderr) != StdioType.TERMINAL) {
    if (context.options.verbose) {
      print("Not enabling colors, stderr isn't a terminal.");
    }
    return false;
  }

  if (stdioType(stdout) != StdioType.TERMINAL) {
    if (context.options.verbose) {
      print("Not enabling colors, stdout isn't a terminal.");
    }
    return false;
  }

  // The `-S` option of `tput` allows us to query multiple capabilities at
  // once.
  ProcessResult result = Process.runSync(
      "/bin/sh", ["-c", "printf '%s' '$TERMINAL_CAPABILITIES' | tput -S"]);

  if (result.exitCode != 0) {
    if (context.options.verbose) {
      print("Not enabling colors, running tput failed.");
    }
    return false;
  }

  List<String> lines = result.stdout.split("\n");

  if (lines.length != 2) {
    if (context.options.verbose) {
      print("Not enabling colors, unexpected output from tput: "
          "${JSON.encode(result.stdout)}.");
    }
    return false;
  }

  String numberOfColors = lines[0];
  if (int.parse(numberOfColors, onError: (_) => -1) < 8) {
    if (context.options.verbose) {
      print("Not enabling colors, less than 8 colors supported: "
          "${JSON.encode(numberOfColors)}.");
    }
    return false;
  }

  String allCodes = lines[1].trim();
  if (ALL_CODES != allCodes) {
    if (context.options.verbose) {
      print("Not enabling colors, color codes don't match: "
          "${JSON.encode(ALL_CODES)} != ${JSON.encode(allCodes)}.");
    }
    return false;
  }

  if (context.options.verbose) {
    print("Enabling colors.");
  }
  return true;
}
