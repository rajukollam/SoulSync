import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  final _profileService = ProfileService();
  final _authService = AuthService();

  bool _loading = true;
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _authService.currentUser!.uid;

    final data = await _profileService.getProfile(uid);

    if (data != null) {
      _nameController.text = data['fullName'] ?? '';
      _bioController.text = data['bio'] ?? '';

      if (data['dateOfBirth'] != null) {
        _dob = data['dateOfBirth'].toDate();
      }
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _save() async {
    final uid = _authService.currentUser!.uid;

    await _profileService.updateProfile(
      uid: uid,
      fullName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      dateOfBirth: _dob,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile Updated ❤️"),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(),
              ),
              title: Text(
                _dob == null
                    ? "Select Date of Birth"
                    : "${_dob!.day}/${_dob!.month}/${_dob!.year}",
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}