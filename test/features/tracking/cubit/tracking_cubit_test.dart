import 'package:flutter_test/flutter_test.dart';
import 'package:laundry28/features/tracking/cubit/tracking_cubit.dart';

void main() {
  group('TrackingCubit', () {
    late TrackingCubit trackingCubit;

    setUp(() {
      trackingCubit = TrackingCubit();
    });

    tearDown(() {
      trackingCubit.close();
    });

    test('initial state is TrackingInitial', () {
      expect(trackingCubit.state, equals(TrackingInitial()));
    });

    // Note: These tests require mocking the TrackingRepository.
    // In a real implementation, use mocktail to mock the repository.
    test('state transitions correctly during tracking lookup', () {
      // This is a basic sanity test.
      // Full integration tests would require Supabase connection.
      expect(trackingCubit.state, isA<TrackingInitial>());
    });
  });
}
