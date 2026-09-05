import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../cubit/tracking_cubit.dart';
import '../widgets/status_stepper.dart';
import '../widgets/status_stepper_skeleton.dart';

class TrackingScreen extends StatelessWidget {
  final String trackingCode;

  const TrackingScreen({super.key, required this.trackingCode});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (trackingCode.isNotEmpty) {
        context.read<TrackingCubit>().fetchOrder(trackingCode);
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Pesanan'),
        centerTitle: true,
      ),
      body: BlocConsumer<TrackingCubit, TrackingState>(
        listener: (context, state) {
          if (state is TrackingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              if (trackingCode.isNotEmpty) {
                context.read<TrackingCubit>().fetchOrder(trackingCode);
              }
            },
            child: _buildBodyContent(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context, TrackingState state) {
          if (trackingCode.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2_outlined, size: 80, color: Color(0xFF757575)),
                  const SizedBox(height: 24),
                  const Text(
                    'Kode tracking tidak valid',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan kode tracking yang benar untuk melacak pesanan Anda',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (state is TrackingLoading) {
            return _buildSkeletonLoader(context);
          }

          if (state is TrackingError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pesanan Tidak Ditemukan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF757575)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<TrackingCubit>().fetchOrder(trackingCode);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is TrackingLoaded) {
            final order = state.order;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_laundry_service, size: 28, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.trackingCode,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    order.customerName,
                                    style: const TextStyle(color: Color(0xFF757575), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusLabel(order.status),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow(Icons.phone_outlined, order.customerPhone),
                            ),
                            Expanded(
                              child: _buildInfoRow(Icons.work_outline, order.serviceType),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STATUS PESANAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF757575))),
                        const SizedBox(height: 20),
                        StatusStepper(status: order.status),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DETAIL PESANAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF757575))),
                        const SizedBox(height: 16),
                        _buildDetailRow('Nama Pelanggan', order.customerName),
                        _buildDetailRow('Layanan', order.serviceType),
                        if (order.estimatedTime != null)
                          _buildDetailRow('Estimasi Selesai', DateFormat('dd MMM yyyy', 'id').format(order.estimatedTime!)),
                        _buildDetailRow('Tanggal Diterima', DateFormat('dd MMM yyyy', 'id').format(order.createdAt)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Laundry28 - Tracking Laundry', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF757575), fontSize: 12)),
              ],
            );
          }

          return const Center(child: Text('Tidak ada data'));
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF757575)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Color(0xFF757575), fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
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
      case 'Siap Diambil': return 'Siap Diambil';
      case 'Selesai': return 'Selesai';
      default: return status;
    }
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header skeleton
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 24),

        // Status stepper skeleton
        const StatusStepperSkeleton(),
        const SizedBox(height: 24),

        // Details cards skeleton
        ...List.generate(3, (index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            ),
          );
        }),
      ],
    );
  }
}
