enum SuperResolutionMode {
  off(
    storageValue: 1,
    label: '關閉',
    description: '預設禁用超解析度',
  ),
  efficiency(
    storageValue: 2,
    label: '效率檔',
    description: '預設啟用基於Anime4K的超解析度 (效率優先)',
  ),
  quality(
    storageValue: 3,
    label: '質量檔',
    description: '預設啟用基於Anime4K的超解析度 (質量優先)',
  );

  const SuperResolutionMode({
    required this.storageValue,
    required this.label,
    required this.description,
  });

  final int storageValue;
  final String label;
  final String description;

  static SuperResolutionMode fromStorageValue(int value) {
    return SuperResolutionMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => SuperResolutionMode.off,
    );
  }
}
