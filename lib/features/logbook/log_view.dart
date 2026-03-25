import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_001/features/log_editor_page.dart';
import 'package:logbook_app_001/services/access_control_service.dart';

import 'log_controller.dart';
import 'models/log_model.dart';
import 'models/user_model.dart';

class LogView extends StatefulWidget {
  final UserModel currentUser;

  const LogView({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = LogController(currentUser: widget.currentUser);

    _controller.loadFromDisk().then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshLogs() {
    setState(() => _isLoading = true);
    _controller.loadFromDisk().then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _navigateToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(controller: _controller),
      ),
    );
  }

  void _navigateToEdit(int index, LogModel log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(
          controller: _controller,
          log: log,
          index: index,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int index, LogModel log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Hapus "${log.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.removeLog(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.cloud_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(success
                    ? "Catatan berhasil dihapus"
                    : "Gagal hapus dari Cloud (terhapus lokal)"),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logbook: ${widget.currentUser.username}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshLogs,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingView(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Ya, Keluar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari berdasarkan judul...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _controller.searchQuery.value = value;
              },
            ),
          ),

          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Mengambil data dari Cloud..."),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ValueListenableBuilder<List<LogModel>>(
                valueListenable: _controller.logsNotifier,
                builder: (context, allLogs, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _controller.searchQuery,
                    builder: (context, query, _) {
                      final logs = query.isEmpty
                          ? allLogs
                          : allLogs
                              .where((log) => log.title
                                  .toLowerCase()
                                  .contains(query.toLowerCase()))
                              .toList();

                      if (logs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.note_alt_outlined,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(query.isEmpty
                                  ? "Belum ada catatan."
                                  : "Tidak ada hasil pencarian."),
                              const SizedBox(height: 8),
                              if (query.isEmpty)
                                ElevatedButton(
                                  onPressed: _navigateToAdd,
                                  child: const Text("Buat Catatan Pertama"),
                                ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final realIndex = allLogs.indexOf(log);
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.note, color: Colors.indigo),
                              title: Text(log.title),
                              subtitle: Text(
                                log.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (AccessControlService.canPerform(
                                    widget.currentUser.role,
                                    'update',
                                    isOwner: log.authorId == widget.currentUser.id,
                                  ))
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _navigateToEdit(realIndex, log),
                                    ),
                                  if (AccessControlService.canPerform(
                                    widget.currentUser.role,
                                    'delete',
                                    isOwner: log.authorId == widget.currentUser.id,
                                  ))
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(realIndex, log),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}