import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/love_profile.dart';
import '../../services/storage_service.dart';
import '../home/home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController yourNameController =
      TextEditingController();

  final TextEditingController partnerNameController =
      TextEditingController();

  DateTime? relationshipDate;

  bool isSaving = false;

  @override
  void dispose() {
    yourNameController.dispose();
    partnerNameController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        relationshipDate = selected;
      });
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (relationshipDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your relationship date"),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    final profile = LoveProfile(
      yourName: yourNameController.text.trim(),
      partnerName: partnerNameController.text.trim(),
      relationshipDate: relationshipDate!,
    );

    await StorageService.saveProfile(profile);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to SoulSync"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 70,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Let's know you both ❤️",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 35),

                TextFormField(
                  controller: yourNameController,
                  decoration: inputDecoration("Your Name"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter your name";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: partnerNameController,
                  decoration: inputDecoration("Partner Name"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter your partner's name";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                InkWell(
                  onTap: pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            relationshipDate == null
                                ? "Select Relationship Date"
                                : DateFormat(
                                    "dd MMM yyyy",
                                  ).format(relationshipDate!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),
                                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveProfile,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "Continue ❤️",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}