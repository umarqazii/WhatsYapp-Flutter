import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Standard import
import '../../data/models/user_model.dart';
import '../../routes/app_pages.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // This works in v6.2.1
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxBool isLoading = false.obs;

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // 🔥 THIS is the key line
      await _googleSignIn.signOut();
      // or await _googleSignIn.disconnect(); (stronger, see below)

      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        await _checkAndCreateUser(user);
        Get.offAllNamed(Routes.HOME);
      }
    } catch (e) {
      Get.snackbar("Login Failed", e.toString());
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> _checkAndCreateUser(User user) async {
    final userDoc = await _db.collection('users').doc(user.email).get();
    if (!userDoc.exists) {
      final newUser = UserModel(
        email: user.email!,
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL ?? '',
      );
      await _db.collection('users').doc(user.email).set(newUser.toJson());
    }
  }

Future<void> logout() async {
    await _auth.signOut();
    // "Disconnect" revokes access and forces the account picker to appear next time
    try {
      await _googleSignIn.disconnect(); 
    } catch (e) {
      // If disconnect fails (e.g. user already signed out), fall back to basic sign out
      await _googleSignIn.signOut(); 
    }
    Get.offAllNamed(Routes.AUTH);
  }
}