import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    group('Constructor', () {
      test('creates with specified delay', () {
        final debouncer = Debouncer(milliseconds: 300);
        expect(debouncer.milliseconds, equals(300));
      });
    });

    group('run method', () {
      test('executes action immediately', () async {
        final debouncer = Debouncer(milliseconds: 100);
        var callCount = 0;
        
        debouncer.run(() => callCount++);
        
        // Wait for debouncing
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Should only call once due to debouncing
        expect(callCount, equals(1));
      });

      test('cancels previous timer', () async {
        final debouncer = Debouncer(milliseconds: 100);
        var callCount = 0;
        
        // First call
        debouncer.run(() => callCount++);
        
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Second call should cancel first timer
        debouncer.run(() => callCount++);
        
        // Wait for debouncing
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Should still only have 2 calls
        expect(callCount, equals(2));
      });

      test('disposes timer', () {
        final debouncer = Debouncer(milliseconds: 100);
        
        debouncer.run(() {});
        debouncer.dispose();
        
        // Should not throw when disposing
        expect(() => debouncer.run(() {}), returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('handles zero millisecond delay', () async {
        final debouncer = Debouncer(milliseconds: 0);
        var callCount = 0;
        
        debouncer.run(() => callCount++);
        
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Should execute immediately
        expect(callCount, equals(1));
      });

      test('handles rapid successive calls', () async {
        final debouncer = Debouncer(milliseconds: 10);
        var callCount = 0;
        
        // Make multiple rapid calls
        for (int i = 0; i < 5; i++) {
          debouncer.run(() => callCount++);
          await Future.delayed(const Duration(milliseconds: 1));
        }
        
        // Should only execute the last call due to debouncing
        expect(callCount, equals(1));
      });

      test('dispose cancels pending timer', () async {
        final debouncer = Debouncer(milliseconds: 100);
        var callCount = 0;
        
        debouncer.run(() => callCount++);
        
        // Dispose before timer executes
        debouncer.dispose();
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Timer should be cancelled, no additional calls
        expect(callCount, equals(1));
      });

      test('multiple dispose calls are safe', () {
        final debouncer = Debouncer(milliseconds: 100);
        
        debouncer.run(() {});
        debouncer.dispose();
        expect(() => debouncer.dispose(), returnsNormally);
        expect(() => debouncer.dispose(), returnsNormally);
      });
    });
  });
}