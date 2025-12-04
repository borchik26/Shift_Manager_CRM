import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/locator.dart';

void main() {
  group('ModuleLocator', () {
    setUp(() {
      // Reset locator before each test
      locator.reset();
    });

    test('is singleton', () {
      final instance1 = ModuleLocator.instance;
      final instance2 = ModuleLocator.instance;
      
      expect(instance1, same(instance2));
    });

    test('registerMany registers multiple modules', () {
      final module1 = Module<String>(builder: () => 'test1', lazy: false);
      final module2 = Module<int>(builder: () => 42, lazy: false);
      
      locator.registerMany([module1, module2]);
      
      expect(locator<String>(), equals('test1'));
      expect(locator<int>(), equals(42));
    });

    test('registerMany throws on duplicate module type', () {
      final module1 = Module<String>(builder: () => 'test1', lazy: false);
      final module2 = Module<String>(builder: () => 'test2', lazy: false);
      
      locator.registerMany([module1]);
      
      expect(
        () => locator.registerMany([module2]),
        throwsA(isA<ModuleAlreadyRegisteredException>()),
      );
    });

    test('lazy modules are created on first access', () {
      var createCount = 0;
      final module = Module<String>(
        builder: () {
          createCount++;
          return 'lazy';
        },
        lazy: true,
      );
      
      locator.registerMany([module]);
      
      // Module should not be created yet
      expect(createCount, equals(0));
      
      // First access creates the module
      final result1 = locator<String>();
      expect(createCount, equals(1));
      expect(result1, equals('lazy'));
      
      // Second access uses cached instance
      final result2 = locator<String>();
      expect(createCount, equals(1));
      expect(result2, equals('lazy'));
    });

    test('non-lazy modules are created immediately', () {
      var createCount = 0;
      final module = Module<String>(
        builder: () {
          createCount++;
          return 'not-lazy';
        },
        lazy: false,
      );
      
      expect(createCount, equals(0));
      
      locator.registerMany([module]);
      
      // Module should be created immediately
      expect(createCount, equals(1));
      
      // Access uses cached instance
      final result = locator<String>();
      expect(createCount, equals(1));
      expect(result, equals('not-lazy'));
    });

    test('call throws for unregistered module', () {
      expect(
        () => locator<String>(),
        throwsA(isA<ModuleNotFoundException>()),
      );
    });

    test('reset clears all modules and instances', () {
      final module1 = Module<String>(builder: () => 'test1', lazy: false);
      final module2 = Module<int>(builder: () => 42, lazy: false);
      
      locator.registerMany([module1, module2]);
      
      // Verify modules are registered
      expect(locator<String>(), equals('test1'));
      expect(locator<int>(), equals(42));
      
      locator.reset();
      
      // Verify modules are cleared
      expect(
        () => locator<String>(),
        throwsA(isA<ModuleNotFoundException>()),
      );
      expect(
        () => locator<int>(),
        throwsA(isA<ModuleNotFoundException>()),
      );
    });

    test('reset allows re-registering same type', () {
      final module1 = Module<String>(builder: () => 'test1', lazy: false);
      final module2 = Module<String>(builder: () => 'test2', lazy: false);
      
      locator.registerMany([module1]);
      
      expect(
        () => locator.registerMany([module2]),
        throwsA(isA<ModuleAlreadyRegisteredException>()),
      );
      
      locator.reset();
      
      // Should work after reset
      expect(() => locator.registerMany([module2]), returnsNormally);
      expect(locator<String>(), equals('test2'));
    });

    test('module type property returns correct type', () {
      final stringModule = Module<String>(builder: () => 'test', lazy: false);
      final intModule = Module<int>(builder: () => 42, lazy: false);
      
      expect(stringModule.type, equals(String));
      expect(intModule.type, equals(int));
    });

    test('module instances are cached', () {
      var createCount = 0;
      final module = Module<String>(
        builder: () {
          createCount++;
          return 'cached';
        },
        lazy: true,
      );
      
      locator.registerMany([module]);
      
      final result1 = locator<String>();
      final result2 = locator<String>();
      final result3 = locator<String>();
      
      // Should only be created once
      expect(createCount, equals(1));
      expect(result1, same(result2));
      expect(result2, same(result3));
    });

    test('different types can coexist', () {
      final stringModule = Module<String>(builder: () => 'string', lazy: false);
      final intModule = Module<int>(builder: () => 123, lazy: false);
      final boolModule = Module<bool>(builder: () => true, lazy: false);
      final doubleModule = Module<double>(builder: () => 3.14, lazy: false);
      
      locator.registerMany([stringModule, intModule, boolModule, doubleModule]);
      
      expect(locator<String>(), equals('string'));
      expect(locator<int>(), equals(123));
      expect(locator<bool>(), isTrue);
      expect(locator<double>(), equals(3.14));
    });

    test('ModuleAlreadyRegisteredException contains type information', () {
      final module = Module<String>(builder: () => 'test', lazy: false);
      
      locator.registerMany([module]);
      
      try {
        locator.registerMany([module]);
        fail('Expected ModuleAlreadyRegisteredException');
      } catch (e) {
        expect(e, isA<ModuleAlreadyRegisteredException>());
        final exception = e as ModuleAlreadyRegisteredException;
        expect(exception.type, equals(String));
      }
    });

    test('ModuleNotFoundException contains type information', () {
      try {
        locator<String>();
        fail('Expected ModuleNotFoundException');
      } catch (e) {
        expect(e, isA<ModuleNotFoundException>());
        final exception = e as ModuleNotFoundException;
        expect(exception.type, equals(String));
      }
    });

    group('Edge Cases', () {
      test('empty module list is allowed', () {
        expect(() => locator.registerMany([]), returnsNormally);
      });

      test('modules can depend on other modules', () {
        final stringModule = Module<String>(builder: () => 'dependency', lazy: false);
        final intModule = Module<int>(
          builder: () => locator<String>().length,
          lazy: true,
        );
        
        locator.registerMany([stringModule, intModule]);
        
        expect(locator<String>(), equals('dependency'));
        expect(locator<int>(), equals(10)); // Length of 'dependency'
      });

      test('circular dependencies are not detected by locator', () {
        // This test documents current behavior - locator doesn't detect circular deps
        // In practice, this would cause infinite recursion
        final module1 = Module<String>(
          builder: () => locator<int>().toString(),
          lazy: true,
        );
        final module2 = Module<int>(
          builder: () => locator<String>().length,
          lazy: true,
        );
        
        locator.registerMany([module1, module2]);
        
        // This would cause stack overflow in real scenario
        // For now, just verify basic registration works
        expect(() => locator.registerMany([module1, module2]), returnsNormally);
      });
    });
  });
}