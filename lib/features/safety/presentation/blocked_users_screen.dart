import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/features/safety/data/safety_service.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final users = await ref.read(safetyServiceProvider).getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.unexpectedError),
          ),
        );
      }
    }
  }

  Future<void> _confirmUnblockUser(String blockedId) async {
    final loc = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.unblock),
        content: Text(loc.unblockUserConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.unblock),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _unblockUser(blockedId);
    }
  }

  Future<void> _unblockUser(String blockedId) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await ref.read(safetyServiceProvider).unblockUser(blockedId);
      await _loadBlockedUsers(); // Reload list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.userUnblockedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.unexpectedError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.blockedUsers)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    localizations.noBlockedUsers,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final item = _blockedUsers[index];
                final profile = item['profiles'] as Map<String, dynamic>? ?? {};
                final fullName =
                    (profile['full_name'] as String?)?.trim().isNotEmpty == true
                    ? profile['full_name'] as String
                    : localizations.unknown;
                final avatarUrl = profile['avatar_url'] as String?;
                final blockedId = item['blocked_id'] as String;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        avatarUrl != null && avatarUrl.trim().isNotEmpty
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.trim().isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(fullName),
                  trailing: TextButton(
                    onPressed: () => _confirmUnblockUser(blockedId),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(localizations.unblock),
                  ),
                );
              },
            ),
    );
  }
}
