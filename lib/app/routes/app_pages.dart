import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whatsyapp/app/modules/chat/chat_binding.dart';
import 'package:whatsyapp/app/modules/chat/chat_view.dart';
import 'package:whatsyapp/app/modules/home/home_binding.dart';
import 'package:whatsyapp/app/modules/home/home_view.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/auth_view.dart';
// import '../modules/home/home_binding.dart'; // Create these later
// import '../modules/home/home_view.dart';     // Create these later

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.AUTH;

  static final routes = [
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(), // Add this!
    ),
    GetPage(
      name: _Paths.CHAT,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
  ];
}