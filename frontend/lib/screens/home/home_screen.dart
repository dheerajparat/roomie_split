import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../room/room_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    await Future.wait([
      roomProv.fetchRooms(),
      roomProv.fetchPendingInvitations(),
    ]);
  }

  void _showCreateRoomDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Room'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Room / Flat Name *',
                  hintText: 'e.g. Flat 402 - 3BHK, Green Villa',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter room name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Near Tech Park',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final roomProv = Provider.of<RoomProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final dialogNavigator = Navigator.of(ctx);

              final success = await roomProv.createRoom(
                nameController.text,
                descController.text,
              );
              dialogNavigator.pop();
              if (!mounted) return;
              if (success && roomProv.currentRoom != null) {
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => RoomDetailScreen(roomId: roomProv.currentRoom!.id),
                  ),
                );
              } else if (roomProv.errorMessage != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(roomProv.errorMessage!),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final roomProv = Provider.of<RoomProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.home_work_rounded, color: Colors.indigo),
            const SizedBox(width: 8),
            Text('RoomieSplit', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                auth.currentUser?.fullName.isNotEmpty == true
                    ? auth.currentUser!.fullName[0].toUpperCase()
                    : 'U',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                auth.logout();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.currentUser?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('@${auth.currentUser?.username ?? ''}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending Invitations Section (Approval Workflow)
                  if (roomProv.pendingInvitations.isNotEmpty) ...[
                    Card(
                      elevation: 0,
                      color: Colors.amber.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.amber.shade400, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.mark_email_unread_rounded, color: Colors.amber.shade900),
                                const SizedBox(width: 8),
                                Text(
                                  'Room Invitations (${roomProv.pendingInvitations.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...roomProv.pendingInvitations.map((inv) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inv.roomName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Invited by ${inv.invitedBy.fullName} (@${inv.invitedBy.username})',
                                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                          ),
                                          if (inv.roomDescription != null && inv.roomDescription!.isNotEmpty)
                                            Text(
                                              inv.roomDescription!,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () async {
                                        await roomProv.respondToInvitation(inv.membershipId, "REJECT");
                                      },
                                      child: const Text('Decline'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: () async {
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        final success = await roomProv.respondToInvitation(inv.membershipId, "ACCEPT");
                                        if (success && mounted) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Joined ${inv.roomName}!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Rooms Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Rooms',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      FilledButton.icon(
                        onPressed: _showCreateRoomDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create Room'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (roomProv.isLoading && roomProv.rooms.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (roomProv.rooms.isEmpty)
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No rooms yet!',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a room for your flat or wait for an invitation from your roommates.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _showCreateRoomDialog,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create Room Now'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: roomProv.rooms.length,
                      itemBuilder: (ctx, index) {
                        final room = roomProv.rooms[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomDetailScreen(roomId: room.id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.group_rounded, color: theme.colorScheme.primary, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          room.name,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        if (room.description != null && room.description!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            room.description!,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${room.totalMembers} active roommates',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                            if (room.roomCode != null) ...[
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Code: ${room.roomCode}',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRoomDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Room'),
      ),
    );
  }
}
