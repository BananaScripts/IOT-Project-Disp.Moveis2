import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyD0Et5G3rxfxyDLSDBr-ND__dB0fTBtB0E',
      appId: '1:175027834237:web:9b91d25ca33c807a599014',
      messagingSenderId: '175027834237',
      projectId: 'gersonfraude-42a04',
      authDomain: 'gersonfraude-42a04.firebaseapp.com',
      databaseURL: 'https://gersonfraude-42a04-default-rtdb.firebaseio.com',
      storageBucket: 'gersonfraude-42a04.firebasestorage.app',
      measurementId: 'G-Y1FC4NY48Z',
    );
  }
}
