import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

bool _isGetXImport(ImportElement import) {
  final source = import.importedLibrary?.source.uri;

  return source?.scheme == 'package' && source?.pathSegments.first == 'get';
}

void main(List<String> args, SendPort sendPort) {
  startPlugin(sendPort, _GetXLinter());
}

class _GetXLinter extends PluginBase {
  @override
  Stream<Lint> getLints(ResolvedUnitResult resolvedUnitResult) async* {
    final library = resolvedUnitResult.libraryElement;
    final getXImports = library.imports.where(_isGetXImport);

    for (final getXImport in getXImports) {
      final nameOffset = getXImport.nameOffset;
      final importLineLength = getXImport.importLineLength;

      yield Lint(
        code: 'yeet_getx_package',
        message: 'Using GetX, huh?',
        correction: 'Yeet the package and use something else.',
        severity: LintSeverity.error,
        location: resolvedUnitResult.lintLocationFromOffset(
          nameOffset,
          length: importLineLength,
        ),
        getAnalysisErrorFixes: (Lint lint) async* {
          final changeBuilder = ChangeBuilder(
            session: resolvedUnitResult.session,
          );

          await changeBuilder.addDartFileEdit(
            library.source.fullName,
            (builder) => builder.addDeletion(
              SourceRange(nameOffset, importLineLength + 1),
            ),
          );

          final getXImportFix = PrioritizedSourceChange(
            0,
            changeBuilder.sourceChange..message = 'Yeet GetX',
          );

          yield AnalysisErrorFixes(
            lint.asAnalysisError(),
            fixes: [getXImportFix],
          );
        },
      );
    }
  }
}

extension ImportElementX on ImportElement {
  int get importLineLength => "import '${importedLibrary?.source.uri}';".length;
}
