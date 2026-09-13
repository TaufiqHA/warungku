import 'package:flutter/material.dart';

class AppAutocompleteField<T extends Object> extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final int minChars;
  final Iterable<T> Function(String query) optionsFilter;
  final String Function(T) displayStringForOption;
  final Widget Function(BuildContext, T)? optionItemBuilder;
  final void Function(T) onSelected;
  final VoidCallback? onClear;
  final bool enabled;

  const AppAutocompleteField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Pencarian...',
    this.minChars = 2,
    required this.optionsFilter,
    required this.displayStringForOption,
    this.optionItemBuilder,
    required this.onSelected,
    this.onClear,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<T>(
          textEditingController: controller,
          focusNode: focusNode,
          displayStringForOption: displayStringForOption,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.trim();
            if (query.length < minChars) {
              return Iterable<T>.empty();
            }
            return optionsFilter(query);
          },
          onSelected: onSelected,
          fieldViewBuilder: (context, textController, currentFocusNode, onFieldSubmitted) {
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: textController,
              builder: (context, value, _) {
                final hasText = value.text.isNotEmpty;
                return TextFormField(
                  controller: textController,
                  focusNode: currentFocusNode,
                  enabled: enabled,
                  onFieldSubmitted: (v) => onFieldSubmitted(),
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: hintText,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: enabled
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    suffixIcon: hasText && enabled
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              textController.clear();
                              onClear?.call();
                            },
                          )
                        : Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          optionsViewBuilder: (context, onSelectedOption, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.surface,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 220,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      if (optionItemBuilder != null) {
                        return InkWell(
                          onTap: () => onSelectedOption(option),
                          child: optionItemBuilder!(context, option),
                        );
                      }
                      return ListTile(
                        dense: true,
                        title: Text(
                          displayStringForOption(option),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelectedOption(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
