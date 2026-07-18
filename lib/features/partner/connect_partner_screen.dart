import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class ConnectPartnerScreen extends StatefulWidget {
  const ConnectPartnerScreen({super.key});

  @override
  State<ConnectPartnerScreen> createState() => _ConnectPartnerScreenState();
}

class _ConnectPartnerScreenState extends State<ConnectPartnerScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  final TextEditingController codeController = TextEditingController();

  bool isLoading = true;
  bool isConnecting = false;

  String myInviteCode = '';

  @override
  void initState() {
    super.initState();
    loadInviteCode();
  }

  Future<void> loadInviteCode() async {
    final user = _authService.currentUser;

    if (user == null) return;

    final profile = await _profileService.getProfile(user.uid);

    if (!mounted) return;

    setState(() {
      myInviteCode = profile?['inviteCode'] ?? '';
      isLoading = false;
    });
  }

  Future<void> copyInviteCode() async {
    await Clipboard.setData(
      ClipboardData(text: myInviteCode),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Invite code copied ❤️"),
      ),
    );
  }

  Future<void> connectPartner() async {
    FocusScope.of(context).unfocus();

    final user = _authService.currentUser;

    if (user == null) return;

    final code = codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      showMessage("Please enter an invite code.");
      return;
    }

    if (code == myInviteCode) {
      showMessage("You can't connect with yourself.");
      return;
    }

    setState(() {
      isConnecting = true;
    });

    try {
      final partner = await _profileService.findPartnerByCode(code);

      if (partner == null) {
        showMessage("Invite code not found.");
        return;
      }

      await _profileService.connectPartners(
        currentUid: user.uid,
        partnerUid: partner["uid"],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❤️ Partner connected successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect Partner ❤️"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.pink,
                size: 70,
              ),

              const SizedBox(height: 16),

              const Text(
                "Invite Your Partner",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Share your invite code or enter your partner's code below.",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "Your Invite Code",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 16),

                      SelectableText(
                        myInviteCode,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: copyInviteCode,
                          icon: const Icon(Icons.copy),
                          label: const Text("Copy Invite Code"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Partner Invite Code",
                  prefixIcon: Icon(Icons.favorite_border),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: isConnecting ? null : connectPartner,
                  icon: isConnecting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.favorite),
                  label: Text(
                    isConnecting
                        ? "Connecting..."
                        : "Connect ❤️",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}