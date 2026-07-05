import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/providers/student_settings_provider.dart';
import 'package:manhaji_app/services/local_storage_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
  FakeLocalStorage({this.stored = false});

  bool stored;
  int writes = 0;

  @override
  bool get isSilentModeEnabled => stored;

  @override
  Future<void> setSilentModeEnabled(bool enabled) async {
    stored = enabled;
    writes++;
  }
}

void main() {
  group('StudentSettingsProvider — الوضع الصامت', () {
    test('defaults to OFF with automatic audio enabled', () {
      final provider = StudentSettingsProvider(FakeLocalStorage());

      expect(provider.silentMode, isFalse);
      expect(provider.autoAudioEnabled, isTrue);
    });

    test('toggling ON notifies listeners and persists locally', () async {
      final storage = FakeLocalStorage();
      final provider = StudentSettingsProvider(storage);
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setSilentMode(true);

      expect(provider.silentMode, isTrue);
      expect(provider.autoAudioEnabled, isFalse);
      expect(storage.stored, isTrue);
      expect(storage.writes, 1);
      expect(notifications, 1);
    });

    test('setting the same value is a no-op (no write, no notify)', () async {
      final storage = FakeLocalStorage();
      final provider = StudentSettingsProvider(storage);
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setSilentMode(false); // already OFF

      expect(storage.writes, 0);
      expect(notifications, 0);
    });

    test('persisted value survives a restart (new provider instance)', () {
      final storage = FakeLocalStorage(stored: true);

      final provider = StudentSettingsProvider(storage);

      expect(provider.silentMode, isTrue);
      expect(provider.autoAudioEnabled, isFalse);
    });

    test('toggling back OFF re-enables automatic audio and persists',
        () async {
      final storage = FakeLocalStorage(stored: true);
      final provider = StudentSettingsProvider(storage);

      await provider.setSilentMode(false);

      expect(provider.silentMode, isFalse);
      expect(provider.autoAudioEnabled, isTrue);
      expect(storage.stored, isFalse);
      expect(storage.writes, 1);
    });
  });
}
