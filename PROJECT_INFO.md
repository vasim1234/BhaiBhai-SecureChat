# Bhai Bhai Secure Chat - Project Info

## 📱 App Overview

**Bhai Bhai Secure Chat** ek modern, secure messaging app hai jo WhatsApp jaisi features deti hai. Ye Flutter mein bani hai aur Firebase backend use karti hai.

**App ka Main Feature:** 24-hour ephemeral messaging — yani har message 24 ghante baad automatically delete ho jata hai.

---

## 🎯 Core Features (Jo Ab Tak Complete Hain)

### Authentication & User Management
- ✅ Email/Password se Login/Signup
- ✅ Unique Username system (jaise `vasim1234`)
- ✅ User Profile (avatar, email, member since)
- ✅ 2D Cartoon Avatar Builder (DiceBear API se)
- ✅ Online/Offline status (real-time green dot)
- ✅ Last Seen time

### Chat Features
- ✅ Real-time messaging (Firestore se)
- ✅ 24-Hour Auto-Delete (har message 24h baad gayab)
- ✅ Read Receipts (✓ single tick, ✓✓ blue double tick)
- ✅ Typing Indicator ("typing..." dikhta hai)
- ✅ Reply to Message (long press karke)
- ✅ Message Edit/Delete (apne message ko)
- ✅ Photo Bhejna (Base64 format mein - bilkul free)
- ✅ Image Caching (flicker fix)

### Social Features
- ✅ Search Users (username se)
- ✅ Friend Request System (badge ke saath)
- ✅ Accept/Reject Friend Request
- ✅ Unfriend option
- ✅ Block/Unblock Users
- ✅ Blocked Users List

### Group Features
- ✅ Group Chat (multiple users ke saath)
- ✅ Group mein Photo Bhejna
- ✅ Pin Chat (important chat top par)

### Profile Features
- ✅ Avatar Builder (6 styles: avataaars, bottts, fun-emoji, adventurer, big-ears, croodles)
- ✅ QR Code (UID ka)
- ✅ Stats (Contacts, Chats, Blocked)
- ✅ Account Settings

---

## 🚧 Features Jo Baaki Hain

### Priority 1
- ⏳ Voice/Video Calling (WebRTC)
- ⏳ Push Notifications (FCM/OneSignal)

### Priority 2
- ⏳ Chats List mein Unread Badge
- ⏳ Chats List mein Search Function (currently working nahi hai)
- ⏳ Group Admin Controls

### Priority 3
- ⏳ Status Updates (Stories)
- ⏳ End-to-End Encryption
- ⏳ Two-Factor Auth

---

## 🛠️ Technology Stack

### Frontend
- **Flutter** (Dart)
- **Material 3** design
- **Provider/StreamBuilder** state management

### Backend
- **Firebase Core** (project initialization)
- **Firebase Auth** (Email/Password login)
- **Cloud Firestore** (real-time database)
- **Firebase Storage** — **HATA DIYA** (Base64 use kar rahe hain)

### Key Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^4.15.0
  firebase_auth: ^6.7.0
  cloud_firestore: ^6.10.0
  flutter_webrtc: ^1.6.2+hotfix.3
  intl: ^0.20.3
  uuid: ^4.6.0
  image_picker: ^1.0.7
  flutter_image_compress: ^2.1.0
  file_picker: ^10.3.8
  path_provider: ^2.1.1
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.1.0


lib/
├── main.dart              (Main app - login, chat, profile, home)
├── friend_request.dart    (Friend request system)
├── user_profile.dart      (User profile screen)
└── avatar_builder.dart    (2D avatar builder + AvatarWidget)

## 📲 OneSignal Notifications

- **OneSignal App ID:** `05bee600-4a45-44e5-b35e-5328544c25c1`
- **REST API Key:** (GitHub par **mat** daalein — secret hai)
- **Firebase Service Account JSON:** OneSignal mein upload hai

### Notification Kaise Kaam Karti Hai:
1. User login karta hai → `OneSignal.login(uid)` call hota hai
2. Message bhejta hai → `_sendNotification()` function HTTP request bhejta hai
3. OneSignal receiver ke device par notification bhejta hai

### Important Files:
- `main.dart` line 22 — OneSignal initialize
- `ChatScreen` line 2277-2278 — App ID + REST API Key
- `LoginScreen` — OneSignal.login()
- `ProfileScreen` — OneSignal.logout()
