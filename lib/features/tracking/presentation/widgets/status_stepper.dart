import 'package:flutter/material.dart';

class StatusStepper extends StatelessWidget {
  final String status;

  StatusStepper({super.key, required this.status});

  final List<String> _statusSteps = [
    'Diterima',
    'Dicuci',
    'Dikeringkan',
    'Disetrika',
    'Siap Diambil',
    'Selesai',
  ];

  int _getStatusIndex(String status) {
    return _statusSteps.indexOf(status);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diterima': return Colors.blue;
      case 'Dicuci': return Colors.orange;
      case 'Dikeringkan': return Colors.amber;
      case 'Disetrika': return Colors.purple;
      case 'Siap Diambil': return Colors.green;
      case 'Selesai': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Diterima': return 'Pesanan Diterima';
      case 'Dicuci': return 'Sedang Dicuci';
      case 'Dikeringkan': return 'Sedang Dikeringkan';
      case 'Disetrika': return 'Sedang Disetrika';
      case 'Siap Diambil': return 'Pesanan Siap Diambil';
      case 'Selesai': return 'Pesanan Selesai';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getStatusIndex(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 3,
              color: Colors.grey.shade300,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: MediaQuery.of(context).size.width * (currentIndex / (_statusSteps.length - 1)),
              height: 3,
              color: _getStatusColor(status),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _statusSteps.length,
          itemBuilder: (context, index) {
            final statusStep = _statusSteps[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted ? _getStatusColor(status) : Colors.grey[300],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? _getStatusColor(status) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle_outlined,
                      color: isCompleted ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStatusLabel(statusStep),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? _getStatusColor(status) : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}