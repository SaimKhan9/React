import 'package:flutter_test/flutter_test.dart';
import 'package:devarena_live_mobile/core/constants/app_constants.dart';
import 'package:devarena_live_mobile/core/constants/languages.dart';

void main() {
  test('Language configs are properly initialized', () {
    expect(kLanguages.isNotEmpty, true);
    expect(kLanguages.length >= 9, true);

    final python = getLanguageById('python');
    expect(python.id, 'python');
    expect(python.starterCode.contains('def solve'), true);
  });

  test('App constants match backend URL', () {
    expect(kServerUrl, 'https://devarena-server-9z6z.onrender.com');
    expect(kIceServers.isNotEmpty, true);
  });
}
