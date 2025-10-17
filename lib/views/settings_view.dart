// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'export_utils_web.dart' if (dart.library.io) 'export_utils_io.dart';
import 'io_file_helpers_web.dart' if (dart.library.io) 'io_file_helpers_io.dart';
import 'package:provider/provider.dart';
import '../services/persistence_service.dart';
import '../repository/match_repository.dart';

class SettingsView extends StatefulWidget {
  /// Optional override for the platform-specific saveExport function used in tests.
  final Future<void> Function(String path, String content)? saveExportOverride;

  const SettingsView({super.key, this.saveExportOverride});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _lastMessage = '';

  // On IO platforms this returns a Directory, on web it returns null.
  Future<dynamic> _documentsDir() async {
    return await getDocumentsDirectory();
  }

  Future<void> _exportBackup(BuildContext context) async {
    final repo = Provider.of<MatchRepository>(context, listen: false);
    final svc = repo.persistence ?? PersistenceService();
    try {
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exporter = widget.saveExportOverride ?? saveExport;

      // When a test override is provided, skip writing to disk and let the
      // override handle finalization. This avoids platform method-channel
      // interactions in widget tests.
      if (widget.saveExportOverride != null) {
        final json = await svc.exportBackupJson();
        final syntheticName = 'simple_match_backup_$ts.json';
        await exporter(syntheticName, json);
        if (!mounted) return;
        setState(() => _lastMessage = 'Exported via override as $syntheticName');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported via override as $syntheticName')));
        return;
      }

      // On web we don't have access to an application documents directory and
      // calling `getApplicationDocumentsDirectory()` may trigger a
      // MissingPluginException. For web, directly trigger the browser download
      // using the exporter (which is the web implementation of saveExport).
      if (kIsWeb) {
        final json = await svc.exportBackupJson();
        final syntheticName = 'simple_match_backup_$ts.json';
        await exporter(syntheticName, json);
        if (!mounted) return;
        setState(() => _lastMessage = 'Exported to browser download as $syntheticName');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to browser download as $syntheticName')));
        return;
      }

  final dir = await _documentsDir();
  final path = dir != null ? '${dir.path}/simple_match_backup_$ts.json' : 'simple_match_backup_$ts.json';
  final file = await svc.exportBackupToFile(path);
      // Use platform-specific saveExport to finalize for web vs io
      try {
        await exporter(path, await svc.exportBackupJson());
      } catch (_) {
        // IO saveExport will write to same path; ignore if it fails here
      }
      if (!mounted) return;
      setState(() => _lastMessage = 'Exported to ${file.path}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
    } catch (e) {
      setState(() => _lastMessage = 'Export failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<List<dynamic>> _listBackups() async {
    return await listBackups();
  }

  Future<void> _importBackup(BuildContext context) async {
    final repo = Provider.of<MatchRepository>(context, listen: false);
    final svc = repo.persistence ?? PersistenceService();
    try {
      // On web, use a file picker because we can't access app documents dir.
      if (kIsWeb) {
        final picked = await pickBackupFileViaBrowser();
        if (picked == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file selected')));
          return;
        }
        final bytes = picked['bytes'] as Uint8List;
        final name = picked['name'] as String;

        // Run a dry-run first
        final dry = await svc.importBackupFromBytes(bytes, dryRun: true);
        if (!dry.success) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup validation failed: ${dry.message}')));
          return;
        }

        final confirm = await showDialog<bool?>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm restore'),
            content: Text('This will overwrite current match data. Import ${dry.counts['stages']} stages, ${dry.counts['shooters']} shooters, ${dry.counts['stageResults']} results from $name. Proceed?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Restore')),
            ],
          ),
        );

        if (confirm != true) return;

        final res = await svc.importBackupFromBytes(bytes, dryRun: false, backupBeforeRestore: true);
        if (res.success) {
          try {
            await repo.loadAll();
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import succeeded but failed to reload repository: $e')));
            if (!mounted) return;
            setState(() => _lastMessage = 'Import succeeded, reload failed: $e');
            return;
          }

          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful')));
          if (!mounted) return;
          setState(() => _lastMessage = 'Import successful');
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: ${res.message}')));
          if (!mounted) return;
          setState(() => _lastMessage = 'Import failed: ${res.message}');
        }
        return;
      }

      final files = await _listBackups();
      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No backup files found in app documents directory')));
        return;
      }

      // Let user pick from a simple dialog
  final chosen = await showDialog<dynamic>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Select backup to import'),
          children: files.map((f) {
            final name = f.path.split('/').last;
            return SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(f),
              child: Text(name),
            );
          }).toList(),
        ),
      );

      if (chosen == null) return;

  final bytes = await readFileBytes(chosen.path);

  // Run a dry-run first
  final dry = await svc.importBackupFromBytes(bytes, dryRun: true);
      if (!dry.success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup validation failed: ${dry.message}')));
        return;
      }

      final confirm = await showDialog<bool?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm restore'),
          content: Text('This will overwrite current match data. Import ${dry.counts['stages']} stages, ${dry.counts['shooters']} shooters, ${dry.counts['stageResults']} results. Proceed?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Restore')),
          ],
        ),
      );

  if (confirm != true) return;

      final res = await svc.importBackupFromBytes(Uint8List.fromList(bytes), dryRun: false, backupBeforeRestore: true);
      if (res.success) {
        // Refresh repository state from persistence; loadAll() now notifies listeners
        try {
          await repo.loadAll();
        } catch (e) {
          // Non-fatal: show message but continue
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import succeeded but failed to reload repository: $e')));
          if (!mounted) return;
          setState(() => _lastMessage = 'Import succeeded, reload failed: $e');
          return;
        }

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful')));
        if (!mounted) return;
        setState(() => _lastMessage = 'Import successful');
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: ${res.message}')));
        if (!mounted) return;
        setState(() => _lastMessage = 'Import failed: ${res.message}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import error: $e')));
      if (!mounted) return;
      setState(() => _lastMessage = 'Import error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export Backup'),
              onPressed: () => _exportBackup(context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Backup'),
              onPressed: () => _importBackup(context),
            ),
            const SizedBox(height: 20),
            Text('Status: $_lastMessage'),
          ],
        ),
      ),
    );
  }
}
