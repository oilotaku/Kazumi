part of 'source_sheet.dart';

void _showAliasPickerDialog({
  required String sourceName,
  required List<String> aliases,
  required ValueChanged<String> onAliasSelected,
  required VoidCallback onAliasesChanged,
}) {
  KazumiDialog.show(
    builder: (context) => _AliasPickerDialog(
      sourceName: sourceName,
      aliases: aliases,
      onAliasSelected: (alias) {
        KazumiDialog.dismiss();
        onAliasSelected(alias);
      },
      onAliasesChanged: onAliasesChanged,
    ),
  );
}

void _showCustomKeywordDialog({
  required ValueChanged<String> onSubmit,
  required String initialKeyword,
  required String sourceName,
}) {
  String keyword = initialKeyword;

  void submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    KazumiDialog.dismiss();
    onSubmit(trimmed);
  }

  KazumiDialog.show(
    builder: (context) => AlertDialog(
      title: const Text('修改檢索詞'),
      content: TextFormField(
        initialValue: initialKeyword,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: '檢索關鍵詞',
          helperText: '僅檢索來源：$sourceName',
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => keyword = value,
        onFieldSubmitted: submit,
      ),
      actions: [
        TextButton(
          onPressed: KazumiDialog.dismiss,
          child: Text(
            '取消',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        TextButton(
          onPressed: () => submit(keyword),
          child: const Text('檢索'),
        ),
      ],
    ),
  );
}

class _AliasPickerDialog extends StatefulWidget {
  const _AliasPickerDialog({
    required this.sourceName,
    required this.aliases,
    required this.onAliasSelected,
    required this.onAliasesChanged,
  });

  final String sourceName;
  final List<String> aliases;
  final ValueChanged<String> onAliasSelected;
  final VoidCallback onAliasesChanged;

  @override
  State<_AliasPickerDialog> createState() => _AliasPickerDialogState();
}

class _AliasPickerDialogState extends State<_AliasPickerDialog> {
  void _confirmDelete(int index) {
    KazumiDialog.show(
      builder: (context) => AlertDialog(
        title: const Text('刪除確認'),
        content: const Text('刪除後無法恢復，確認要永久刪除這個別名嗎？'),
        actions: [
          TextButton(
            onPressed: KazumiDialog.dismiss,
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () {
              KazumiDialog.dismiss();
              // Aliases are shared across source rules.
              setState(() => widget.aliases.removeAt(index));
              widget.onAliasesChanged();
              if (widget.aliases.isEmpty) {
                Navigator.of(this.context).pop();
              }
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 560,
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('別名檢索', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '僅檢索來源：${widget.sourceName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            for (var index = 0; index < widget.aliases.length; index++)
              ListTile(
                title: Text(widget.aliases[index]),
                trailing: IconButton(
                  onPressed: () => _confirmDelete(index),
                  icon: const Icon(Icons.delete),
                ),
                onTap: () => widget.onAliasSelected(widget.aliases[index]),
              ),
          ],
        ),
      ),
    );
  }
}
