import 'package:flutter/material.dart';

import '../../models/user_profile_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/friend_request_service.dart';


class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final UserService _userService = UserService();
 final AuthService _authService = AuthService();
  final TextEditingController _controller = TextEditingController();
  final FriendRequestService _friendRequestService = FriendRequestService();


  bool _loading = false;
  bool _requestSent = false;
  UserProfileModel? _user;
  String? _error;

  Future<void> _search() async {
    final code = _controller.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _error = "Please enter an invite code.";
        _user = null;
      });
      return;
    }

   setState(() {
  _loading = true;
  _error = null;
  _user = null;
  _requestSent = false;
});

    final result = await _userService.findByInviteCode(code);

    setState(() {
      _loading = false;

      if (result == null) {
        _error = "No user found.";
      } else {
        _user = result;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Friend"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "Enter Invite Code",
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _search,
                icon: const Icon(Icons.search),
                label: const Text("Search"),
              ),
            ),

            const SizedBox(height: 30),

            if (_loading)
              const CircularProgressIndicator(),

            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),

            if (_user != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        child: Text(
                          _user!.fullName.isNotEmpty
                              ? _user!.fullName[0].toUpperCase()
                              : "?",
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _user!.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                     const SizedBox(height: 20),
                      SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
   onPressed: _requestSent
    ? null
    : () async {
      final currentUser = _authService.currentUser;

      if (currentUser == null || _user == null) {
        return;
      }

      try {
        if (currentUser.uid == _user!.uid) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("You can't send a request to yourself."),
    ),
  );
  return;
}
      await _friendRequestService.sendRequest(
  fromUserId: currentUser.uid,
  toUserId: _user!.uid,
);

        if (!mounted) return;

        setState(() {
  _requestSent = true;
});
      
      } catch (e) {
  if (!mounted) return;

  if (e.toString().contains("Request already sent")) {
   setState(() {
  _requestSent = true;
  _controller.clear();
});
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString()),
    ),
  );
}
    },
   icon: Icon(
  _requestSent
      ? Icons.check_circle
      : Icons.person_add,
),
   label: Text(
  _requestSent
      ? "Request Sent"
      : "Send Request",
),
  ),
),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}