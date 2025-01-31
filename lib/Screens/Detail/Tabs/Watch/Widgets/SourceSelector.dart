import 'package:flutter/material.dart';
import 'package:flutter_qjs/quickjs/ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../DataClass/Media.dart';
import '../../../../../Functions/Function.dart';
import '../../../../../Preferences/PrefManager.dart';
import '../../../../../Widgets/DropdownMenu.dart';
import '../../../../../api/Mangayomi/Model/Source.dart';
import '../../../../../api/Mangayomi/extension_preferences_providers.dart';
import '../../../../../api/Mangayomi/get_source_preference.dart';
import '../../../../Extensions/ExtensionSettings/ExtensionSettings.dart';
import '../../../../Settings/language.dart';

class SourceSelector extends ConsumerStatefulWidget {
  final Source? currentSource;
  final Function(Source source) onSourceChange;
  final Media mediaData;
  final List<Source> sourceList;

  const SourceSelector({
    super.key,
    this.currentSource,
    required this.onSourceChange,
    required this.mediaData,
    required this.sourceList,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SourceSelectorState();
}

class _SourceSelectorState extends ConsumerState<SourceSelector> {
  @override
  Widget build(BuildContext context) {
    var sources = widget.sourceList;
    if (sources.isEmpty) {
      return const Column(
        children: [
          buildDropdownMenu(
            padding: EdgeInsets.all(0),
            currentValue: 'No sources installed',
            options: ['No sources installed'],
            prefixIcon: Icons.source,
          ),
        ],
      );
    }
    String nameAndLang(Source source) {
      bool isDuplicateName =
          sources.where((s) => s.name == source.name).length > 1;

      return isDuplicateName
          ? '${source.name!} - ${completeLanguageName(source.lang!.toLowerCase())}'
          : source.name!;
    }

    var lastUsedSource = PrefManager.getCustomVal<String>(
        '${widget.mediaData.id}-lastUsedSource');
    if (lastUsedSource == null ||
        !sources.any((e) => nameAndLang(e) == lastUsedSource)) {
      lastUsedSource = nameAndLang(sources.first);
    }

    Source source =
        sources.firstWhereOrNull((e) => nameAndLang(e) == lastUsedSource!) ??
            sources.first;

    var theme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildDropdownMenu(
                padding: const EdgeInsets.all(0),
                currentValue: lastUsedSource,
                options: sources.map((e) => nameAndLang(e)).toList(),
                borderColor: theme.primary,
                prefixIcon: Icons.source,
                onChanged: (name) async {
                  PrefManager.setCustomVal(
                      '${widget.mediaData.id}-lastUsedSource', name);
                  lastUsedSource = name;
                  source = sources.firstWhereOrNull(
                          (e) => nameAndLang(e) == lastUsedSource!) ??
                      sources.first;
                  if (widget.currentSource?.id != source.id) {
                    widget.onSourceChange(source);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                var sourcePreference = getSourcePreference(source: source)
                    .map((e) => getSourcePreferenceEntry(e.key!, source.id!))
                    .toList();
                navigateToPage(
                  context,
                  SourcePreferenceWidget(
                    source: source,
                    sourcePreference: sourcePreference,
                  ),
                );
              },
              child: Icon(
                Icons.settings,
                size: 32,
                color: theme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
