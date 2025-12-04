import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/schedule/widgets/date_range_filter_dropdown.dart';
import 'package:my_app/schedule/models/date_range_filter.dart';

void main() {
  group('DateRangeFilterDropdown', () {
    testWidgets('displays date range filter dropdown correctly', (WidgetTester tester) async {
      // Arrange
      DateRangeFilter selectedFilter = DateRangeFilter.all;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DateRangeFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {},
          ),
        ),
      ));

      // Assert - Check dropdown elements
      expect(find.text('Период'), findsOneWidget);
      expect(find.byIcon(Icons.date_range), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      expect(find.byType(DropdownButton<DateRangeFilter>), findsOneWidget);
    });

    testWidgets('displays all filter options', (WidgetTester tester) async {
      // Arrange
      DateRangeFilter selectedFilter = DateRangeFilter.all;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DateRangeFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {},
          ),
        ),
      ));

      // Tap dropdown to open options
      await tester.tap(find.byType(DropdownButton<DateRangeFilter>));
      await tester.pumpAndSettle();

      // Assert - Check all filter options
      expect(find.text('Все время'), findsOneWidget);
      expect(find.text('Сегодня'), findsOneWidget);
      expect(find.text('Неделя'), findsOneWidget);
      expect(find.text('Месяц'), findsOneWidget);
      
      // Check icons
      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.byIcon(Icons.view_week), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('calls onFilterChanged when option selected', (WidgetTester tester) async {
      // Arrange
      DateRangeFilter selectedFilter = DateRangeFilter.all;
      DateRangeFilter? capturedFilter;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DateRangeFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {
              capturedFilter = filter;
            },
          ),
        ),
      ));

      // Tap dropdown and select an option
      await tester.tap(find.byType(DropdownButton<DateRangeFilter>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Сегодня'));
      await tester.pumpAndSettle();

      // Assert - Callback should be called
      expect(capturedFilter, equals(DateRangeFilter.today));
    });

    testWidgets('displays correct selected item', (WidgetTester tester) async {
      // Arrange - Test each filter type
      final testCases = [
        {
          'filter': DateRangeFilter.all,
          'expectedText': 'Все время',
        },
        {
          'filter': DateRangeFilter.today,
          'expectedText': 'Сегодня',
        },
        {
          'filter': DateRangeFilter.week,
          'expectedText': 'Неделя',
        },
        {
          'filter': DateRangeFilter.month,
          'expectedText': 'Месяц',
        },
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: DateRangeFilterDropdown(
              selectedFilter: testCase['filter'] as DateRangeFilter,
              onFilterChanged: (filter) {},
            ),
          ),
        ));

        // Assert - Selected item should be displayed correctly
        expect(find.text(testCase['expectedText'] as String), findsOneWidget);
        expect(find.byIcon(Icons.date_range), findsOneWidget);

        // Clean up for next test
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('has correct styling', (WidgetTester tester) async {
      // Arrange
      DateRangeFilter selectedFilter = DateRangeFilter.all;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DateRangeFilterDropdown(
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
      
      final dropdownButton = tester.widget<DropdownButton<DateRangeFilter>>(
        find.byType(DropdownButton<DateRangeFilter>),
      );
      expect(dropdownButton.isDense, isTrue);
      expect(dropdownButton.underline, equals(const SizedBox()));
    });

    testWidgets('displays correct icons for each filter type', (WidgetTester tester) async {
      // Arrange - Test icons for each filter type
      final iconTests = [
        {
          'filter': DateRangeFilter.all,
          'expectedIcon': Icons.all_inclusive,
        },
        {
          'filter': DateRangeFilter.today,
          'expectedIcon': Icons.today,
        },
        {
          'filter': DateRangeFilter.week,
          'expectedIcon': Icons.view_week,
        },
        {
          'filter': DateRangeFilter.month,
          'expectedIcon': Icons.calendar_month,
        },
      ];

      for (final test in iconTests) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: DateRangeFilterDropdown(
              selectedFilter: test['filter'] as DateRangeFilter,
              onFilterChanged: (filter) {},
            ),
          ),
        ));

        // Tap dropdown to see options
        await tester.tap(find.byType(DropdownButton<DateRangeFilter>));
        await tester.pumpAndSettle();

        // Assert - Correct icon should be displayed
        expect(find.byIcon(test['expectedIcon'] as IconData), findsOneWidget);

        // Clean up for next test
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('handles null callback gracefully', (WidgetTester tester) async {
      // Arrange
      DateRangeFilter selectedFilter = DateRangeFilter.all;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DateRangeFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {}, // Provide empty callback instead of null
          ),
        ),
      ));

      // Tap dropdown and select an option
      await tester.tap(find.byType(DropdownButton<DateRangeFilter>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Сегодня'));
      await tester.pumpAndSettle();

      // Assert - Should not throw error
      expect(find.byType(DateRangeFilterDropdown), findsOneWidget);
    });

    testWidgets('displays correct text styling', (WidgetTester tester) async {
      // Arrange
      DateRangeFilter selectedFilter = DateRangeFilter.all;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DateRangeFilterDropdown(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) {},
          ),
        ),
      ));

      // Assert - Check text styling in hint
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      
      // Find the hint text with "Период"
      final hintTextWidget = textWidgets.firstWhere(
        (widget) => widget.data == 'Период',
        orElse: () => throw Exception('Hint text not found'),
      );
      
      expect(hintTextWidget.style?.fontSize, equals(14));
      expect(hintTextWidget.style?.color, equals(Colors.blue.shade700));
      expect(hintTextWidget.style?.fontWeight, equals(FontWeight.w600));
      
      // Check selected item text styling
      final selectedTextWidgets = textWidgets.where(
        (widget) => widget.data != 'Период',
      );
      
      for (final widget in selectedTextWidgets) {
        expect(widget.style?.fontSize, equals(14));
        expect(widget.style?.color, equals(Colors.blue.shade700));
        expect(widget.style?.fontWeight, equals(FontWeight.w600));
      }
    });
  });
}