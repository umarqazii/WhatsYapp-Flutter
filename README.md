# WhatsYapp 💬

A full-featured real-time messaging application built with **Flutter**, **Firebase**, and **GetX**. This app supports text messaging, image sharing, voice notes, and real-time voice calling.

---

## 🚀 Features

- **Authentication:** Secure Email/Password login via Firebase Auth.
- **Real-time Messaging:** Instant message delivery using Cloud Firestore.
- **Media Sharing:**
    - **Images:** Send photos from Camera or Gallery (stored via Cloudinary).
    - **Voice Notes:** Record and send audio messages with playback controls.
- **Voice Calling:** Crystal clear 1-on-1 voice calls using ZegoCloud.
- **Push Notifications:**
    - Background notifications via FCM (V1 API).
    - Foreground "Heads-up" notifications using Flutter Local Notifications.
    - Deep linking: tapping a notification opens the specific chat.
- **User Search:** Search for other users by email to start conversations.
- **Unread Counters:** Real-time tracking of unread messages.

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** GetX
- **Backend:** Firebase (Firestore, Auth, Messaging)
- **Storage:** Cloudinary (Free Tier)
- **Calling SDK:** ZegoCloud UIKit
- **Audio:** `record` (recording) & `audioplayers` (playback)

---

## ⚙️ Setup & Configuration

This project relies on several third-party services. You must configure these keys for the app to function properly.

### 1. Firebase Setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable Authentication (Email/Password).
3. Enable Cloud Firestore and create a database.
4. Download `google-services.json` and place it in `android/app/`.

**FCM V1 API:**
- Go to **Project Settings → Service Accounts → Generate New Private Key**.
- Rename the file to `service_account.json`.
- Place it in `assets/service_account.json`.

### 2. Cloudinary Setup (Media Storage)
1. Create a free account at [Cloudinary](https://cloudinary.com/).
2. Go to **Settings → Upload → Add Upload Preset**.
    - Important: Set Signing Mode to "Unsigned".
3. Update `ChatController` with your **Cloud Name** and **Upload Preset**.

### 3. ZegoCloud Setup (Voice Calling)
1. Create a project at [ZegoCloud Console](https://console.zegocloud.com/).
2. Get your **AppID** (Integer) and **AppSign** (String).
3. Update `main.dart` (`initZegoService`) and `call_page.dart` with these credentials.

---

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/umarqazii/WhatsYapp-Flutter.git
cd WhatsYapp-Flutter

# Install dependencies
flutter pub get
