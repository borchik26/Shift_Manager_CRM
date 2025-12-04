import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/home/home_view.dart';
import 'package:my_app/home/home_view_model.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/internal_notification/toast/toast_event.dart';
import 'package:my_app/core/utils/internal_notification/haptic_feedback/haptic_feedback_listener.dart';

// Mock classes for testing
class MockNotifyService extends NotifyService {
  ToastEvent? lastEvent;
  HapticFeedbackEvent? lastHapticEvent;
  
  @override
  void setToastEvent(ToastEvent? event) {
    lastEvent = event;
  }
  
  @override
  void setHapticFeedbackEvent(HapticFeedbackEvent? event) {
    lastHapticEvent = event;
  }
}

void main() {
  group('HomeView', () {
    late MockNotifyService mockNotifyService;
    late HomeViewModel viewModel;

    setUp(() {
      mockNotifyService = MockNotifyService();
      viewModel = HomeViewModel(notifyService: mockNotifyService);
    });

    tearDown(() {
      viewModel.dispose();
    });

    testWidgets('displays home view correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: HomeView(),
      ));

      // Assert - Check home view elements
      expect(find.text('MVVM Counter'), findsOneWidget);
      expect(find.text('Counter'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('counter increments when button is pressed', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: HomeView(),
      ));

      // Assert - Initial state
      expect(find.text('0'), findsOneWidget);

      // Act - Tap the increment button
      final incrementButton = find.byIcon(Icons.add);
      await tester.tap(incrementButton);
      await tester.pump();

      // Assert - Counter should be incremented
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('counter increments multiple times', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: HomeView(),
      ));

      // Act - Tap the increment button multiple times
      final incrementButton = find.byIcon(Icons.add);
      
      for (int i = 1; i <= 5; i++) {
        await tester.tap(incrementButton);
        await tester.pump();
        
        // Assert - Counter should be incremented
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('shows toast notification every 10 increments', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: HomeView(),
      ));

      final incrementButton = find.byIcon(Icons.add);

      // Act - Increment 9 times (should not show toast)
      for (int i = 1; i <= 9; i++) {
        await tester.tap(incrementButton);
        await tester.pump();
      }

      // Assert - No toast should be shown yet
      expect(mockNotifyService.lastEvent, isNull);

      // Act - Increment 1 more time (should show toast)
      await tester.tap(incrementButton);
      await tester.pump();

      // Assert - Toast should be shown
      expect(mockNotifyService.lastEvent, isNotNull);
      expect(mockNotifyService.lastEvent, isA<ToastEventSuccess>());
      final toastEvent = mockNotifyService.lastEvent as ToastEventSuccess;
      expect(toastEvent.message, contains('Success! Counter reached 10'));
    });

    testWidgets('shows haptic feedback every 10 increments', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: HomeView(),
      ));

      final incrementButton = find.byIcon(Icons.add);

      // Act - Increment 9 times (should not show haptic)
      for (int i = 1; i <= 9; i++) {
        await tester.tap(incrementButton);
        await tester.pump();
      }

      // Assert - No haptic should be shown yet
      expect(mockNotifyService.lastHapticEvent, isNull);

      // Act - Increment 1 more time (should show haptic)
      await tester.tap(incrementButton);
      await tester.pump();

      // Assert - Haptic feedback should be shown
      expect(mockNotifyService.lastHapticEvent, isNotNull);
      expect(mockNotifyService.lastHapticEvent, isA<HapticFeedbackEvent>());
      final hapticEvent = mockNotifyService.lastHapticEvent as HapticFeedbackEvent;
      expect(hapticEvent, HapticFeedbackEvent.success);
    });

    testWidgets('shows toast and haptic at 20 increments', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: HomeView(),
      ));

      final incrementButton = find.byIcon(Icons.add);

      // Act - Increment 20 times
      for (int i = 1; i <= 20; i++) {
        await tester.tap(incrementButton);
        await tester.pump();
      }

      // Assert - Should have shown toast and haptic at 10 and 20
      expect(mockNotifyService.lastEvent, isNotNull);
      expect(mockNotifyService.lastEvent, isA<ToastEventSuccess>());
      final toastEvent = mockNotifyService.lastEvent as ToastEventSuccess;
      expect(toastEvent.message, contains('Success! Counter reached 20'));

      expect(mockNotifyService.lastHapticEvent, isNotNull);
      expect(mockNotifyService.lastHapticEvent, isA<HapticFeedbackEvent>());
      final hapticEvent = mockNotifyService.lastHapticEvent as HapticFeedbackEvent;
      expect(hapticEvent, HapticFeedbackEvent.success);
    });
  });

  group('HomeViewModel', () {
    late MockNotifyService mockNotifyService;
    late HomeViewModel viewModel;

    setUp(() {
      mockNotifyService = MockNotifyService();
      viewModel = HomeViewModel(notifyService: mockNotifyService);
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('initializes with counter value 0', () {
      // Assert
      expect(viewModel.counter.value, equals(0));
    });

    test('increment method increments counter', () {
      // Arrange
      final initialValue = viewModel.counter.value;

      // Act
      viewModel.increment();

      // Assert
      expect(viewModel.counter.value, equals(initialValue + 1));
    });

    test('increment shows toast every 10 increments', () {
      // Act - Increment 9 times
      for (int i = 1; i <= 9; i++) {
        viewModel.increment();
      }

      // Assert - No toast should be shown yet
      expect(mockNotifyService.lastEvent, isNull);

      // Act - Increment 1 more time
      viewModel.increment();

      // Assert - Toast should be shown
      expect(mockNotifyService.lastEvent, isNotNull);
      expect(mockNotifyService.lastEvent, isA<ToastEventSuccess>());
      final toastEvent = mockNotifyService.lastEvent as ToastEventSuccess;
      expect(toastEvent.message, contains('Success! Counter reached 10'));
    });

    test('increment shows haptic feedback every 10 increments', () {
      // Act - Increment 9 times
      for (int i = 1; i <= 9; i++) {
        viewModel.increment();
      }

      // Assert - No haptic should be shown yet
      expect(mockNotifyService.lastHapticEvent, isNull);

      // Act - Increment 1 more time
      viewModel.increment();

      // Assert - Haptic feedback should be shown
      expect(mockNotifyService.lastHapticEvent, isNotNull);
      expect(mockNotifyService.lastHapticEvent, isA<HapticFeedbackEvent>());
      final hapticEvent = mockNotifyService.lastHapticEvent as HapticFeedbackEvent;
      expect(hapticEvent, HapticFeedbackEvent.success);
    });

    test('increment works correctly multiple times', () {
      // Arrange
      final initialValue = viewModel.counter.value;

      // Act - Increment multiple times
      for (int i = 1; i <= 5; i++) {
        viewModel.increment();
      }

      // Assert
      expect(viewModel.counter.value, equals(initialValue + 5));
    });

    test('dispose method cleans up resources', () {
      // Arrange
      final counter = viewModel.counter;

      // Act - Should not throw
      expect(() => viewModel.dispose(), returnsNormally);

      // Assert - Counter should still be accessible
      expect(counter.value, isNotNull);
    });

    test('counter notifies listeners on increment', () {
      // Arrange
      bool wasNotified = false;
      viewModel.counter.addListener(() {
        wasNotified = true;
      });

      // Act
      viewModel.increment();

      // Assert
      expect(wasNotified, isTrue);
    });
  });
}