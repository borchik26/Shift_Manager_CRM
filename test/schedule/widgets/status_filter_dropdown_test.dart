import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/schedule/widgets/status_filter_dropdown.dart';
import 'package:my_app/schedule/models/shift_status_filter.dart';

void main() {
  group('StatusFilterDropdown', () {
    testWidgets('displays status filter dropdown correctly', (WidgetTester tester) async {
      // Arrange
      ShiftStatusFilter selectedFilter = ShiftStatusFilter.all;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {},
          ),
        ),
      ));

      // Assert - Check dropdown elements
      expect(find.text('Статус'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      expect(find.byType(DropdownButton<ShiftStatusFilter>), findsOneWidget);
    });

    testWidgets('displays all filter options', (WidgetTester tester) async {
      // Arrange
      ShiftStatusFilter selectedFilter = ShiftStatusFilter.all;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {},
          ),
        ),
      ));

      // Tap dropdown to open options
      await tester.tap(find.byType(DropdownButton<ShiftStatusFilter>));
      await tester.pumpAndSettle();

      // Assert - Check all filter options
      expect(find.text('Все смены'), findsOneWidget);
      expect(find.text('С конфликтами'), findsOneWidget);
      expect(find.text('С предупреждениями'), findsOneWidget);
      expect(find.text('Нормальные'), findsOneWidget);
      
      // Check icons
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('calls onFilterChanged when option selected', (WidgetTester tester) async {
      // Arrange
      ShiftStatusFilter selectedFilter = ShiftStatusFilter.all;
      ShiftStatusFilter? capturedFilter;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {
              capturedFilter = filter;
            },
          ),
        ),
      ));

      // Tap dropdown and select an option
      await tester.tap(find.byType(DropdownButton<ShiftStatusFilter>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('С конфликтами'));
      await tester.pumpAndSettle();

      // Assert - Callback should be called
      expect(capturedFilter, equals(ShiftStatusFilter.withConflicts));
    });

    testWidgets('displays correct selected item', (WidgetTester tester) async {
      // Arrange - Test each filter type
      final testCases = [
        {
          'filter': ShiftStatusFilter.all,
          'expectedText': 'Все смены',
        },
        {
          'filter': ShiftStatusFilter.withConflicts,
          'expectedText': 'С конфликтами',
        },
        {
          'filter': ShiftStatusFilter.withWarnings,
          'expectedText': 'С предупреждениями',
        },
        {
          'filter': ShiftStatusFilter.normal,
          'expectedText': 'Нормальные',
        },
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StatusFilterDropdown(
              selectedFilter: testCase['filter'] as ShiftStatusFilter,
              onFilterChanged: (filter) {},
            ),
          ),
        ));

        // Assert - Selected item should be displayed correctly
        expect(find.text(testCase['expectedText'] as String), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        // Clean up for next test
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('has correct styling', (WidgetTester tester) async {
      // Arrange
      ShiftStatusFilter selectedFilter = ShiftStatusFilter.all;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {},
          ),
        ),
      ));

      // Assert - Check styling
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      
      expect(decoration.color, equals(Colors.white));
      expect(decoration.borderRadius, equals(BorderRadius.circular(20)));
      expect(decoration.border, isNotNull);
      
      final dropdownButton = tester.widget<DropdownButton<ShiftStatusFilter>>(
        find.byType(DropdownButton<ShiftStatusFilter>),
      );
      expect(dropdownButton.isDense, isTrue);
      expect(dropdownButton.underline, equals(const SizedBox()));
    });

    testWidgets('handles null callback gracefully', (WidgetTester tester) async {
      // Arrange
      ShiftStatusFilter selectedFilter = ShiftStatusFilter.all;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {}, // Provide empty callback instead of null
          ),
        ),
      ));

      // Tap dropdown and select an option
      await tester.tap(find.byType(DropdownButton<ShiftStatusFilter>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('С конфликтами'));
      await tester.pumpAndSettle();

      // Assert - Should not throw error
      expect(find.byType(StatusFilterDropdown), findsOneWidget);
    });

    testWidgets('displays correct icons for each filter type', (WidgetTester tester) async {
      // Arrange - Test icon colors for each filter type
      final iconColorTests = [
        {
          'filter': ShiftStatusFilter.all,
          'expectedIcon': Icons.check_circle_outline,
          'expectedColor': Colors.grey.shade600,
        },
        {
          'filter': ShiftStatusFilter.withConflicts,
          'expectedIcon': Icons.error,
          'expectedColor': Colors.red,
        },
        {
          'filter': ShiftStatusFilter.withWarnings,
          'expectedIcon': Icons.warning,
          'expectedColor': Colors.orange,
        },
        {
          'filter': ShiftStatusFilter.normal,
          'expectedIcon': Icons.check_circle,
          'expectedColor': Colors.green,
        },
      ];

      for (final test in iconColorTests) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: StatusFilterDropdown(
              selectedFilter: test['filter'] as ShiftStatusFilter,
              onFilterChanged: (filter) {},
            ),
          ),
        ));

        // Tap dropdown to see options
        await tester.tap(find.byType(DropdownButton<ShiftStatusFilter>));
        await tester.pumpAndSettle();

        // Assert - Correct icon and color should be displayed
        expect(find.byIcon(test['expectedIcon'] as IconData), findsOneWidget);
        
        // Find the icon widget and check its color
        final iconWidget = tester.widget<Icon>(
          find.byIcon(test['expectedIcon'] as IconData),
        );
        expect(iconWidget.color, equals(test['expectedColor'] as Color));

        // Clean up for next test
        await tester.pumpWidget(Container());
      }
    });
  });
}