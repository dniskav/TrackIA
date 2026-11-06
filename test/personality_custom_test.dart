import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/domain/companion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('custom personality persists per profile and companion', () async {
    const profileA = CompanionStore(profileId: 'profile-a');
    const profileB = CompanionStore(profileId: 'profile-b');
    final initial = Companion(
      id: 'lectura',
      name: 'Lectura',
      description: 'Leer',
      prompt: 'Instrucciones anteriores',
    );
    await profileA.save([initial]);
    await profileB.save([initial]);

    await profileA.upsert(initial.copyWith(prompt: 'Cálida, breve y curiosa.'));

    expect((await profileA.load()).single.prompt, 'Cálida, breve y curiosa.');
    expect((await profileB.load()).single.prompt, 'Instrucciones anteriores');
    expect((await profileA.load()).single.description, 'Leer');
  });

  test('personalities support up to four thousand characters', () {
    final companion = Companion(
      id: 'lectura',
      name: 'Lectura',
      description: '',
      prompt: 'x' * 4000,
    );
    expect(companion.prompt, hasLength(4000));
  });
}
