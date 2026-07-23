import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_profile_model.dart';
import '../../services/friend_request_service.dart';

class RequestsScreen extends StatelessWidget {
  RequestsScreen({super.key});

  final FriendRequestService _friendRequestService =
      FriendRequestService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final String currentUserId =
      FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connection Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _friendRequestService.incomingRequests(
          currentUserId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No pending requests ❤️",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];

              final data =
                  request.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('users')
                    .doc(data['fromUserId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final user =
                      UserProfileModel.fromFirestore(
                    userSnapshot.data!,
                  );

                  return Card(
                    elevation: 3,
                    margin:
                        const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),
                     child: Column(
  children: [
    ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: user.photoUrl.isNotEmpty
            ? NetworkImage(user.photoUrl)
            : null,
        child: user.photoUrl.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        user.bio.isEmpty
            ? "Would like to connect ❤️"
            : user.bio,
      ),
    ),

    const Divider(),

    Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await _friendRequestService.rejectRequest(
                  request.id,
                );
              },
              child: const Text("Reject"),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: FilledButton(
              onPressed: () async {
                await _friendRequestService.acceptRequest(
                  requestId: request.id,
                  currentUserId: currentUserId,
                  otherUserId: data['fromUserId'],
                );
              },
              child: const Text("Accept"),
            ),
          ),
        ],
      ),
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
    );
  }
}