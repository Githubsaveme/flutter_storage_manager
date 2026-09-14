import 'package:flutter/material.dart';
import 'package:flutter_storage_manager/flutter_storage_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storage Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo accent
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const StorageManagerHomeScreen(),
    );
  }
}

class StorageManagerHomeScreen extends StatefulWidget {
  const StorageManagerHomeScreen({super.key});

  @override
  State<StorageManagerHomeScreen> createState() =>
      _StorageManagerHomeScreenState();
}

class _StorageManagerHomeScreenState extends State<StorageManagerHomeScreen>
    with SingleTickerProviderStateMixin {
  final _manager = FlutterStorageManager.instance;

  StorageInfo? _storageInfo;
  StorageAnalysis? _analysis;

  bool _isLoading = false;
  String _loadingMessage = '';

  StorageCategory? _selectedCategoryFilter;
  final Set<String> _selectedFilePaths = {};

  late AnimationController _refreshAnimController;

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Analyzing storage environment...';
    });
    _refreshAnimController.repeat();

    try {
      final info = await _manager.getStorageInfo();
      final analysis = await _manager.analyzeStorage();

      if (mounted) {
        setState(() {
          _storageInfo = info;
          _analysis = analysis;
          _selectedFilePaths.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load storage data: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _refreshAnimController.stop();
        _refreshAnimController.reset();
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  IconData _getCategoryIcon(StorageCategory category) {
    switch (category) {
      case StorageCategory.cache:
        return Icons.cached_rounded;
      case StorageCategory.temporary:
        return Icons.timer_outlined;
      case StorageCategory.prefetched:
        return Icons.cloud_download_outlined;
      case StorageCategory.downloads:
        return Icons.folder_zip_outlined;
      case StorageCategory.generated:
        return Icons.description_outlined;
      case StorageCategory.thumbnails:
        return Icons.image_outlined;
      case StorageCategory.pluginManaged:
        return Icons.extension_outlined;
    }
  }

  Color _getCategoryColor(StorageCategory category) {
    switch (category) {
      case StorageCategory.cache:
        return const Color(0xFFF59E0B);
      case StorageCategory.temporary:
        return const Color(0xFFEF4444);
      case StorageCategory.prefetched:
        return const Color(0xFF3B82F6);
      case StorageCategory.downloads:
        return const Color(0xFF10B981);
      case StorageCategory.generated:
        return const Color(0xFF8B5CF6);
      case StorageCategory.thumbnails:
        return const Color(0xFFEC4899);
      case StorageCategory.pluginManaged:
        return const Color(0xFF6B7280);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- Confirmation Dialogs ---

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: confirmColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmAndClearCategory(StorageCategory category) async {
    final categoryName = category.name.toUpperCase();
    final confirmed = await _showConfirmationDialog(
      title: 'Clear $categoryName Cache?',
      message:
          'This will safely delete all application $categoryName files. Recreatable files will be re-downloaded or re-generated as needed.',
      confirmText: 'Clear Category',
    );

    if (confirmed) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Clearing $categoryName category...';
      });

      final result = await _manager.clearCategory(category);
      if (mounted) {
        _showSnackBar(
          'Cleared ${result.deletedCount} files (${_formatBytes(result.bytesFreed)})',
        );
        _loadAllData();
      }
    }
  }

  Future<void> _confirmAndDeleteSelected() async {
    if (_selectedFilePaths.isEmpty) return;

    final count = _selectedFilePaths.length;
    final confirmed = await _showConfirmationDialog(
      title: 'Delete $count Selected Files?',
      message:
          'Are you sure you want to permanently remove $count selected files from application managed storage?',
      confirmText: 'Delete Files',
    );

    if (confirmed) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Deleting selected files...';
      });

      final result = await _manager.deleteItems(_selectedFilePaths.toList());
      if (mounted) {
        _showSnackBar(
          'Deleted ${result.deletedCount} files, Freed ${_formatBytes(result.bytesFreed)}',
        );
        _loadAllData();
      }
    }
  }

  Future<void> _confirmAndClearAll() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Clear All Managed Storage?',
      message:
          'This will permanently delete all cleanable app files across cache, temporary, prefetched, and generated folders.',
      confirmText: 'Clear All Data',
      confirmColor: Colors.red.shade800,
    );

    if (confirmed) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Clearing all managed files...';
      });

      final result = await _manager.clearAllManagedFiles();
      if (mounted) {
        _showSnackBar(
          'All Cleaned! Deleted ${result.deletedCount} files (${_formatBytes(result.bytesFreed)})',
        );
        _loadAllData();
      }
    }
  }

  // --- Preview Dialog ---

  Future<void> _showReviewPreviewDialog() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Generating dry-run preview...';
    });

    try {
      final preview = await _manager.previewCleanup();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.preview_rounded,
                        color: Color(0xFF6366F1), size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cleanup Dry-Run Preview',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Found ${preview.itemCount} candidate files totaling ${_formatBytes(preview.totalBytes)} cleanable data.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: preview.items.length,
                    itemBuilder: (context, index) {
                      final item = preview.items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(item.category)
                              .withValues(alpha: 0.15),
                          child: Icon(_getCategoryIcon(item.category),
                              color: _getCategoryColor(item.category),
                              size: 20),
                        ),
                        title: Text(item.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.category.name,
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text(item.formattedSize,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.cleaning_services_rounded),
                    label: Text(
                        'Clean All Now (${_formatBytes(preview.totalBytes)})'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _confirmAndClearAll();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Preview failed: $e', isError: true);
      }
    }
  }

  // --- File Details Dialog ---

  void _showFileDetailsDialog(StorageItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_getCategoryIcon(item.category),
                color: _getCategoryColor(item.category)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Category', item.category.name.toUpperCase()),
            _detailRow('Size', item.formattedSize),
            _detailRow('Can Delete', item.canDelete ? 'Yes' : 'No'),
            if (item.createdAt != null)
              _detailRow('Created',
                  item.createdAt!.toLocal().toString().split('.')[0]),
            if (item.modifiedAt != null)
              _detailRow('Modified',
                  item.modifiedAt!.toLocal().toString().split('.')[0]),
            const SizedBox(height: 12),
            const Text('Path:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                item.path,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final res = await _manager.deleteItems([item.path]);
              if (mounted) {
                if (res.deletedCount > 0) {
                  _showSnackBar('File deleted');
                } else {
                  _showSnackBar('Deletion failed', isError: true);
                }
                _loadAllData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // --- Prefetch Helper ---

  Future<void> _prefetchSampleFile() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Prefetching sample file...';
    });

    try {
      final sampleUrl = Uri.parse(
        'https://raw.githubusercontent.com/flutter/flutter/master/README.md',
      );
      final filename =
          'sample_prefetch_${DateTime.now().millisecondsSinceEpoch}.md';

      await _manager.prefetchFile(
        sampleUrl,
        fileName: filename,
        category: StorageCategory.prefetched,
        overwrite: true,
      );

      if (mounted) {
        _showSnackBar(
            'Successfully prefetched $filename into managed storage!');
        _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Prefetch failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayItems = _analysis?.items.where((item) {
          if (_selectedCategoryFilter == null) return true;
          return item.category == _selectedCategoryFilter;
        }).toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Storage Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          RotationTransition(
            turns: _refreshAnimController,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Re-analyze',
              onPressed: _isLoading ? null : _loadAllData,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'prefetch') _prefetchSampleFile();
              if (val == 'preview') _showReviewPreviewDialog();
              if (val == 'clear_all') _confirmAndClearAll();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'preview',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.preview, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text('Dry-Run Preview',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'prefetch',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text('Prefetch File',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text('Clear All Data',
                          style: TextStyle(color: Colors.red),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage,
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadAllData,
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // --- Storage Meter Overview Card ---
                    if (_storageInfo != null)
                      _buildStorageGaugeCard(theme, isDark),
                    const SizedBox(height: 20),

                    // --- Cleanable Categories Grid ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Cleanable Categories',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.cleaning_services, size: 16),
                          label: const Text('Dry Run Preview'),
                          onPressed: _showReviewPreviewDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_analysis != null) _buildCategoryGrid(theme, isDark),
                    const SizedBox(height: 24),

                    // --- Files List Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Managed Files (${displayItems.length})',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedFilePaths.isNotEmpty)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.delete, size: 16),
                            label:
                                Text('Delete (${_selectedFilePaths.length})'),
                            onPressed: _confirmAndDeleteSelected,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Category Filter Pills
                    _buildCategoryFilterBar(theme),
                    const SizedBox(height: 12),

                    // File List
                    if (displayItems.isEmpty)
                      _buildEmptyState(theme)
                    else
                      ...displayItems
                          .map((item) => _buildFileTile(item, theme, isDark)),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _prefetchSampleFile,
        icon: const Icon(Icons.add_to_photos_rounded),
        label: const Text('Prefetch Asset'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  // Widget: Overview Card with Progress Indicator
  Widget _buildStorageGaugeCard(ThemeData theme, bool isDark) {
    final info = _storageInfo!;
    final total = info.totalBytes ?? 1;
    final used = info.usedBytes ?? 0;
    final appUsed = info.appUsedBytes ?? 0;
    final percentage = (used / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Storage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.indigo.shade200
                            : Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_formatBytes(used)} used of ${_formatBytes(total)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: isDark ? Colors.black26 : Colors.indigo.shade100,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildMiniStat(
                      'App Usage', _formatBytes(appUsed), Icons.apps_rounded)),
              Expanded(
                child: _buildMiniStat(
                  'App Cache',
                  _formatBytes(info.appCacheBytes ?? 0),
                  Icons.cached_rounded,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Free Disk',
                  _formatBytes(info.freeBytes ?? 0),
                  Icons.disc_full_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.indigo.shade400),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis),
              Text(value,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  // Widget: Cleanable Categories Grid
  Widget _buildCategoryGrid(ThemeData theme, bool isDark) {
    final categories = _analysis!.categories;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = _getCategoryColor(cat.category);
        final icon = _getCategoryIcon(cat.category);

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _confirmAndClearCategory(cat.category),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.category.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatBytes(cat.sizeBytes),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.clear_rounded,
                      size: 14, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget: Category Filter Bar
  Widget _buildCategoryFilterBar(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            selected: _selectedCategoryFilter == null,
            label: const Text('All Files'),
            onSelected: (_) => setState(() => _selectedCategoryFilter = null),
          ),
          const SizedBox(width: 8),
          ...StorageCategory.values.map((cat) {
            final isSelected = _selectedCategoryFilter == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                avatar: Icon(_getCategoryIcon(cat),
                    size: 16,
                    color: isSelected ? Colors.white : _getCategoryColor(cat)),
                label: Text(cat.name),
                onSelected: (_) =>
                    setState(() => _selectedCategoryFilter = cat),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Widget: Single File Item Tile
  Widget _buildFileTile(StorageItem item, ThemeData theme, bool isDark) {
    final isSelected = _selectedFilePaths.contains(item.path);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _showFileDetailsDialog(item),
        leading: Checkbox(
          value: isSelected,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _selectedFilePaths.add(item.path);
              } else {
                _selectedFilePaths.remove(item.path);
              }
            });
          },
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${item.category.name} • ${item.formattedSize}',
          style: TextStyle(
              fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
          onPressed: () async {
            final confirmed = await _showConfirmationDialog(
              title: 'Delete ${item.name}?',
              message: 'This file will be permanently removed.',
              confirmText: 'Delete',
            );
            if (confirmed) {
              final res = await _manager.deleteItems([item.path]);
              if (mounted) {
                if (res.deletedCount > 0) {
                  _showSnackBar('Deleted ${item.name}');
                } else {
                  _showSnackBar('Failed to delete file', isError: true);
                }
                _loadAllData();
              }
            }
          },
        ),
      ),
    );
  }

  // Widget: Empty State Graphic
  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.folder_off_outlined,
              size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No Files In Storage',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Use "Prefetch Asset" to add a managed sample file.',
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
