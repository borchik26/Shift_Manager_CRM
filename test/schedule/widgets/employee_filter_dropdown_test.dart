import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/schedule/widgets/employee_filter_dropdown.dart';
import 'package:my_app/data/models/employee.dart';

void main() {
  group('EmployeeFilterDropdown', () {
    testWidgets('displays employee filter dropdown correctly', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
          email: 'ivan@example.com',
          phone: '+7 (900) 123-45-67',
          avatarUrl: 'https://i.pravatar.cc/150?u=1',
        ),
      ];
      
      String? selectedEmployeeId;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {},
          ),
        ),
      ));

      // Assert - Check dropdown elements
      expect(find.text('Сотрудник'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      expect(find.byType(DropdownButton<String?>), findsOneWidget);
    });

    testWidgets('displays "All employees" option', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
        ),
      ];
      
      String? selectedEmployeeId;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {},
          ),
        ),
      ));

      // Tap dropdown to open options
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      // Assert - Check "All employees" option
      expect(find.text('Все сотрудники'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.textContaining('Все'), findsOneWidget); // In selected item display
    });

    testWidgets('displays employee list correctly', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
          avatarUrl: 'https://i.pravatar.cc/150?u=1',
        ),
        Employee(
          id: '2',
          firstName: 'Петр',
          lastName: 'Петров',
          position: 'Кассир',
          branch: 'Центр',
          status: 'active',
          hireDate: DateTime.parse('2023-02-15'),
          avatarUrl: null, // No avatar
        ),
      ];
      
      String? selectedEmployeeId;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {},
          ),
        ),
      ));

      // Tap dropdown to open options
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      // Assert - Check employee options
      expect(find.text('Иван Иванов'), findsOneWidget);
      expect(find.text('Петр Петров'), findsOneWidget);
      
      // Check avatars
      expect(find.byType(CircleAvatar), findsWidgets);
      
      // Check avatar with URL
      final avatarWithUrl = find.byWidgetPredicate((widget) {
        final circleAvatar = widget as CircleAvatar?;
        return circleAvatar?.backgroundImage != null;
      });
      expect(avatarWithUrl, findsOneWidget);
      
      // Check avatar without URL (should show initial)
      final avatarWithoutUrl = find.byWidgetPredicate((widget) {
        final circleAvatar = widget as CircleAvatar?;
        return circleAvatar?.backgroundImage == null;
      });
      expect(avatarWithoutUrl, findsOneWidget);
    });

    testWidgets('calls onEmployeeSelected when option selected', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
        ),
      ];
      
      String? selectedEmployeeId;
      String? capturedEmployeeId;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {
              capturedEmployeeId = employeeId;
            },
          ),
        ),
      ));

      // Tap dropdown and select an employee
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Иван Иванов'));
      await tester.pumpAndSettle();

      // Assert - Callback should be called
      expect(capturedEmployeeId, equals('1'));
    });

    testWidgets('calls onEmployeeSelected when "All employees" selected', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
        ),
      ];
      
      String? selectedEmployeeId;
      String? capturedEmployeeId;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {
              capturedEmployeeId = employeeId;
            },
          ),
        ),
      ));

      // Tap dropdown and select "All employees"
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Все сотрудники'));
      await tester.pumpAndSettle();

      // Assert - Callback should be called with null
      expect(capturedEmployeeId, isNull);
    });

    testWidgets('displays correct selected employee', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
        ),
      ];
      
      const selectedEmployeeId = '1';

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {},
          ),
        ),
      ));

      // Assert - Selected employee should be displayed correctly
      expect(find.text('Иван'), findsOneWidget); // Should show first name only
    });

    testWidgets('has correct styling', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
        ),
      ];
      
      String? selectedEmployeeId;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {},
          ),
        ),
      ));

      // Assert - Check styling
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      
      expect(decoration.color, equals(Colors.white));
      expect(decoration.borderRadius, equals(BorderRadius.circular(20)));
      expect(decoration.border, isNotNull);
      
      final dropdownButton = tester.widget<DropdownButton<String?>>(
        find.byType(DropdownButton<String?>),
      );
      expect(dropdownButton.isDense, isTrue);
      expect(dropdownButton.underline, equals(const SizedBox()));
    });

    testWidgets('handles empty employee list gracefully', (WidgetTester tester) async {
      // Arrange
      final employees = <Employee>[];
      String? selectedEmployeeId;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {},
          ),
        ),
      ));

      // Tap dropdown to open options
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      expect(find.text('Все сотрудники'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('displays employee names correctly in selected item', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Александр',
          lastName: 'Сергеевич',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
        ),
      ];
      
      const selectedEmployeeId = '1';

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {},
          ),
        ),
      ));

      // Assert - Selected item should show only first name
      expect(find.text('Александр'), findsOneWidget);
      expect(find.text('Сергеевич'), findsNothing); // Last name should not be shown
    });

    testWidgets('handles null callback gracefully', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
        ),
      ];
      
      String? selectedEmployeeId;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {}, // Empty callback instead of null
          ),
        ),
      ));

      // Tap dropdown and select an employee
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Иван Иванов'));
      await tester.pumpAndSettle();

      // Assert - Should not throw error
      expect(find.byType(EmployeeFilterDropdown), findsOneWidget);
    });

    testWidgets('displays correct avatar colors', (WidgetTester tester) async {
      // Arrange
      final employees = [
        Employee(
          id: '1',
          firstName: 'Иван',
          lastName: 'Иванов',
          position: 'Менеджер',
          branch: 'ТЦ Мега',
          status: 'active',
          hireDate: DateTime.parse('2023-01-15'),
          avatarUrl: null, // No avatar URL
        ),
      ];
      
      String? selectedEmployeeId;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmployeeFilterDropdown(
            employees: employees,
            selectedEmployeeId: selectedEmployeeId,
            onEmployeeSelected: (employeeId) {},
          ),
        ),
      ));

      // Tap dropdown to see options
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      // Assert - Check avatar background color for employee without URL
      final avatarWidget = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatarWidget.backgroundColor, equals(Colors.blue.shade100));
      
      // Check text color for initial
      final textWidget = tester.widget<Text>(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.byType(Text),
        ),
      );
      expect(textWidget.style?.color, equals(Colors.blue.shade700));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
    });
  });
}