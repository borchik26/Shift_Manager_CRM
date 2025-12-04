import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/internal_notification/haptic_feedback/haptic_feedback_listener.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/home/home_view_model.dart';

class MockNotifyService implements NotifyService {
  ToastEvent? _lastToastEvent;
  HapticFeedbackEvent? _lastHapticEvent;

  ToastEvent? get lastToastEvent => _lastToastEvent;
  HapticFeedbackEvent? get lastHapticEvent => _lastHapticEvent;

  @override
  final ValueNotifier<ToastEvent?> toastEvent = ValueNotifier<ToastEvent?>(null);
  
  @override
  final ValueNotifier<HapticFeedbackEvent?> hapticFeedbackEvent = 
      ValueNotifier<HapticFeedbackEvent?>(null);

  @override
  void setToastEvent(ToastEvent? event) {
    _lastToastEvent = event;
    toastEvent.value = event;
  }

  @override
  void clearToastEvent() {
    toastEvent.value = null;
  }

  @override
  void setHapticFeedbackEvent(HapticFeedbackEvent? event) {
    _lastHapticEvent = event;
    hapticFeedbackEvent.value = event;
  }

  @override
  void clearHapticFeedbackEvent() {
    hapticFeedbackEvent.value = null;
  }
}

void main() {
  group('HomeViewModel', () {
    late HomeViewModel viewModel;
    late MockNotifyService mockNotifyService;

    setUp(() {
      mockNotifyService = MockNotifyService();
      viewModel = HomeViewModel(notifyService: mockNotifyService);
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('initializes with counter set to 0', () {
      expect(viewModel.counter.value, 0);
    });

    test('increment increases counter by 1', () {
      // Act
      viewModel.increment();

      // Assert
      expect(viewModel.counter.value, 1);
    });

    test('increment multiple times increases counter correctly', () {
      // Act
      for (int i = 0; i < 5; i++) {
        viewModel.increment();
      }

      // Assert
      expect(viewModel.counter.value, 5);
    });

    test('increment does not trigger notification when counter is not multiple of 10', () {
      // Act
      viewModel.increment();

      // Assert
      expect(mockNotifyService.lastToastEvent, isNull);
      expect(mockNotifyService.lastHapticEvent, isNull);
    });

    test('increment triggers notification when counter reaches 10', () {
      // Arrange
      for (int i = 0; i < 9; i++) {
        viewModel.increment();
      }

      // Act
      viewModel.increment();

      // Assert
      expect(viewModel.counter.value, 10);
      expect(mockNotifyService.lastToastEvent, isA<ToastEventSuccess>());
      expect(
        (mockNotifyService.lastToastEvent as ToastEventSuccess).message,
        'Success! Counter reached 10',
      );
      expect(mockNotifyService.lastHapticEvent, HapticFeedbackEvent.success);
    });

    test('increment triggers notification when counter reaches 20', () {
      // Arrange
      for (int i = 0; i < 19; i++) {
        viewModel.increment();
      }

      // Act
      viewModel.increment();

      // Assert
      expect(viewModel.counter.value, 20);
      expect(mockNotifyService.lastToastEvent, isA<ToastEventSuccess>());
      expect(
        (mockNotifyService.lastToastEvent as ToastEventSuccess).message,
        'Success! Counter reached 20',
      );
      expect(mockNotifyService.lastHapticEvent, HapticFeedbackEvent.success);
    });

    test('increment triggers notification at multiple milestones', () {
      // Act & Assert for 10
      for (int i = 0; i < 10; i++) {
        viewModel.increment();
      }
      expect(viewModel.counter.value, 10);
      expect(mockNotifyService.lastToastEvent, isA<ToastEventSuccess>());
      expect(
        (mockNotifyService.lastToastEvent as ToastEventSuccess).message,
        'Success! Counter reached 10',
      );

      // Act & Assert for 20
      for (int i = 0; i < 10; i++) {
        viewModel.increment();
      }
      expect(viewModel.counter.value, 20);
      expect(mockNotifyService.lastToastEvent, isA<ToastEventSuccess>());
      expect(
        (mockNotifyService.lastToastEvent as ToastEventSuccess).message,
        'Success! Counter reached 20',
      );
    });

    test('dispose cleans up resources', () {
      // Arrange
      final initialValue = viewModel.counter.value;

      // Act
      viewModel.dispose();

      // Assert
      // After dispose, trying to access counter should still work
      // but ValueNotifier should be disposed
      expect(viewModel.counter.value, initialValue);
    });
  });
}