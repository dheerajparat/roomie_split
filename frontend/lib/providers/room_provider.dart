import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/room.dart';

class RoomProvider with ChangeNotifier {
  List<Room> _rooms = [];
  List<RoomInvitation> _pendingInvitations = [];
  Room? _currentRoom;
  bool _isLoading = false;
  String? _errorMessage;

  List<Room> get rooms => _rooms;
  List<RoomInvitation> get pendingInvitations => _pendingInvitations;
  Room? get currentRoom => _currentRoom;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRooms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient().dio.get('/rooms');
      final list = response.data as List;
      _rooms = list.map((r) => Room.fromJson(r)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> fetchPendingInvitations() async {
    try {
      final response = await ApiClient().dio.get('/rooms/invitations/pending');
      final list = response.data as List;
      _pendingInvitations = list.map((inv) => RoomInvitation.fromJson(inv)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching pending invites: $e");
    }
  }

  Future<bool> createRoom(String name, String? description) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient().dio.post(
        '/rooms',
        data: {
          'name': name.trim(),
          'description': description?.trim(),
        },
      );
      final newRoom = Room.fromJson(response.data);
      _rooms.insert(0, newRoom);
      _currentRoom = newRoom;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchRoomDetails(int roomId) async {
    try {
      final response = await ApiClient().dio.get('/rooms/$roomId');
      _currentRoom = Room.fromJson(response.data);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> inviteUser(int roomId, String usernameOrEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient().dio.post(
        '/rooms/$roomId/invite',
        data: {'username_or_email': usernameOrEmail.trim()},
      );
      // Refresh room details to show new pending member
      await fetchRoomDetails(roomId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> respondToInvitation(int membershipId, String action) async {
    try {
      await ApiClient().dio.post(
        '/rooms/invitations/$membershipId/respond',
        data: {'action': action},
      );
      // Remove from pending list
      _pendingInvitations.removeWhere((inv) => inv.membershipId == membershipId);
      // Refresh rooms list
      await fetchRooms();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
