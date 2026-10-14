// lib/features/kit_selection/select_testing_kit_screen.dart
import 'package:flutter/material.dart';
import '../camera/camera_screen.dart';

/// Registry structure for future testing kits
class TestingKitOption {
  final String id;
  final String displayName;

  const TestingKitOption({
    required this.id,
    required this.displayName,
  });
}

class SelectTestingKitScreen extends StatefulWidget {
  final String officerId;

  const SelectTestingKitScreen({
    super.key,
    required this.officerId,
  });

  @override
  State<SelectTestingKitScreen> createState() => _SelectTestingKitScreenState();
}

class _SelectTestingKitScreenState extends State<SelectTestingKitScreen> {
  // Extensible list - currently containing ONLY Parichayan Test C1
  static const List<TestingKitOption> _availableKits = [
    TestingKitOption(
      id: 'parichayan_c1',
      displayName: 'Parichayan Test C1',
    ),
  ];

  late String _selectedKitName;

  @override
  void initState() {
    super.initState();
    _selectedKitName = _availableKits.first.displayName;
  }

  void _handleContinue() {
    // Navigate to the existing camera module with the selected kit
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          officerId: widget.officerId,
          selectedKit: _selectedKitName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Testing Kit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TEST CONFIGURATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Testing Kit Used',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Specify the physical presumptive kit being used for this sample session.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedKitName,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF0F172A),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          items: _availableKits.map((kit) {
                            return DropdownMenuItem<String>(
                              value: kit.displayName,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.science_outlined,
                                    size: 20,
                                    color: Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(kit.displayName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedKitName = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Continue Button
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _handleContinue,
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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