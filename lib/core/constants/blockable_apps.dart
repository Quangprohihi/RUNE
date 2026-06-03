class BlockableApp {
  const BlockableApp({
    required this.name,
    required this.packageName,
    required this.category,
  });

  final String name;
  final String packageName;
  final String category;
}

class BlockableApps {
  const BlockableApps._();

  static const List<BlockableApp> presets = [
    BlockableApp(
      name: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      category: 'Social',
    ),
    BlockableApp(
      name: 'Instagram',
      packageName: 'com.instagram.android',
      category: 'Social',
    ),
    BlockableApp(
      name: 'Facebook',
      packageName: 'com.facebook.katana',
      category: 'Social',
    ),
    BlockableApp(
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      category: 'Video',
    ),
    BlockableApp(
      name: 'Chrome',
      packageName: 'com.android.chrome',
      category: 'Browser',
    ),
    BlockableApp(
      name: 'Play Store',
      packageName: 'com.android.vending',
      category: 'System',
    ),
  ];
}
