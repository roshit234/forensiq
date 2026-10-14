// lib/features/evidence/evidence_history_screen.dart
import 'package:flutter/material.dart';
import '../../models/evidence_record.dart';
import '../../services/evidence_storage_service.dart';
import 'evidence_record_screen.dart';

class EvidenceHistoryScreen extends StatefulWidget {
  final String officerId;

  const EvidenceHistoryScreen({
    super.key,
    required this.officerId,
  });

  @override
  State<EvidenceHistoryScreen> createState() => _EvidenceHistoryScreenState();
}

class _EvidenceHistoryScreenState extends State<EvidenceHistoryScreen> {
  final EvidenceStorageService _storageService = const EvidenceStorageService();
  List<EvidenceRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final records = await _storageService.getAllRecords();
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
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
          'Evidence Vault & History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : _records.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
                        SizedBox(height: 12),
                        Text(
                          'No evidence records saved yet.',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete a test session to seal and view records.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final item = _records[index];
                      final bool isPositive = item.classification == 'Positive';
                      final bool isInconclusive = item.classification == 'Inconclusive';

                      final Color badgeColor = isPositive
                          ? const Color(0xFFB91C1C)
                          : isInconclusive
                              ? const Color(0xFFB45309)
                              : const Color(0xFF15803D);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EvidenceRecordScreen(record: item),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.evidenceId,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        item.formattedDateTime,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item.testKit} • ${item.location}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isPositive
                                              ? 'Presumptive Positive'
                                              : isInconclusive
                                                  ? 'Inconclusive'
                                                  : 'Presumptive Negative',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}