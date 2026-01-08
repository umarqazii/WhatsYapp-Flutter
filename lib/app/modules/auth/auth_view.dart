import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: Center(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const CircularProgressIndicator();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: Image.asset(
                      'assets/icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),


                  const SizedBox(height: 24),

                  // const Text(
                  //   'WhatsYapp',
                  //   style: TextStyle(
                  //     fontSize: 28,
                  //     fontWeight: FontWeight.w700,
                  //     letterSpacing: 0.5,
                  //   ),
                  // ),
                  //
                  // const SizedBox(height: 8),

                  const Text(
                    'Simple. Private. Fast.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.login, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
