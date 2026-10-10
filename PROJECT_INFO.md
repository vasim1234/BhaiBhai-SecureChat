
```markdown
# Bhai Bhai Secure Chat - Project Info

## 📱 App Overview

**Bhai Bhai Secure Chat** ek modern, secure messaging app hai jo WhatsApp jaisi features deti hai. Ye Flutter mein bani hai aur Firebase backend use karti hai.

**App ka Main Feature:** 24-hour ephemeral messaging — yani har message 24 ghante baad automatically delete ho jata hai.

---

## ✅ Core Features (Jo Ab Tak Complete Hain)

### Authentication & User Management
- ✅ Email/Password se Login/Signup (modern gradient UI)
- ✅ Unique Username system (jaise `vasim1234`)
- ✅ Forgot Password (email reset link)
- ✅ Google Sign-In button (placeholder, jald aa raha hai)
- ✅ Online/Offline status (real-time green dot)
- ✅ Last Seen time

### User Profile (Modern Design)
- ✅ Gradient Banner (purple-blue) header
- ✅ Avatar with photo upload (Base64 format)
- ✅ Bio field (150 characters)
- ✅ Status/Quote field (50 characters)
- ✅ Birthday (date picker)
- ✅ My QR Code (UID based)
- ✅ Stats — Contacts, Chats, Blocked counts
- ✅ Account Settings — Privacy, Notifications, Storage, Help
- ✅ Modern Edit Profile dialog
- ✅ Camera icon on avatar for quick photo change

### Chat Features
- ✅ Real-time messaging (Firestore)
- ✅ 24-Hour Auto-Delete (har message 24h baad gayab)
- ✅ Read Receipts (✓ single tick, ✓✓ blue double tick)
- ✅ Typing Indicator ("typing..." dikhta hai)
- ✅ Reply to Message (long press karke)
- ✅ Message Edit/Delete (apne message ko)
- ✅ Photo Bhejna (Base64 format - bilkul free)
- ✅ Image Caching (flicker fix)
- ✅ Fast Message Send (Instant UI update)
- ✅ Unread Badge (chat list mein green circle count)
- ✅ Chat List with 4 Filter Chips (All, Unread, Favourites, Groups)
- ✅ Pin Chat (important chat top par)
- ✅ Modern Chat Cards (rounded, shadow, smooth tap)

### Social Features
- ✅ Search Users (username se)
- ✅ Friend Request System (badge ke saath)
- ✅ Accept/Reject Friend Request
- ✅ Unfriend option
- ✅ Block/Unblock Users
- ✅ Blocked Users List

### Group Features (Complete)
- ✅ Group Chat (multiple users ke saath)
- ✅ Group Info Screen with modern UI
- ✅ Group Photo (Base64 format, chat list + header + info mein dikhti hai)
- ✅ Group Bio (150 characters)
- ✅ Admin Controls:
  - ✅ Change Group Name (sirf admin)
  - ✅ Change Group Bio (sirf admin)
  - ✅ Delete Group (sirf admin)
- ✅ Add Members (admin existing users ko add kar sakta hai)
- ✅ Exit Group (sab members ke liye)
- ✅ Group Unread Badge (chat list mein green count)
- ✅ Members List (admin badge ke saath)
- ✅ "GROUPS" section chat list mein top pe
- ✅ Group chat list with unread count

### Status Updates (Stories) — NEW ✅
- ✅ Text Status (6 colors mein)
- ✅ Photo Status (Base64 format)
- ✅ 24-hour auto-delete
- ✅ Full-screen viewer (tap karke dekho)
- ✅ Progress bars (multiple status)
- ✅ Viewers tracking
- ✅ "My Status" tile with + icon
- ✅ "Recent Updates" (friends ke status, green ring)
- ✅ Time ago ("Just now", "5m ago")

### Notifications
- ✅ Push Notifications (OneSignal)
- ✅ App se bheji gayi notification (REST API se)
- ✅ Manual notification (OneSignal Dashboard se)

---

## 🚧 Features Jo Baaki Hain

### Priority 1
- ⏳ Voice Message (code ready, mic test pending)
- ⏳ Chat List Search (search bar already hai, filter logic pending)

### Priority 2
- ⏳ Communities Tab (currently "jald aa raha hai")
- ⏳ Pinned Messages (important message top pe)

### Priority 3
- ⏳ Voice/Video Calling (WebRTC, TURN server chahiye)
- ⏳ Video Status (Firebase Storage setup chahiye)
- ⏳ Photo + Song Status (Firebase Storage setup chahiye)
- ⏳ End-to-End Encryption
- ⏳ Two-Factor Auth
- ⏳ Message Forwarding
- ⏳ Chat Wallpaper
- ⏳ Chat Statistics

---

## 🛠️ Technology Stack

### Frontend
- Flutter (Dart)
- Material 3 design
- Provider/StreamBuilder state management

### Backend
- Firebase Core (project initialization)
- Firebase Auth (Email/Password login)
- Cloud Firestore (real-time database)
- Firebase Storage — HATA DIYA (Base64 use kar rahe hain)

### Notifications
- OneSignal (Push Notifications)
- OneSignal REST API (app se notification bhejne ke liye)
- Firebase Service Account JSON (OneSignal mein upload hai)

### Key Packages (pubspec.yaml)
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
  http: ^1.2.0
  onesignal_flutter: ^5.3.0
  flutter_sound: ^9.2.13
  permission_handler: 11.0.1
```

File Structure

```
lib/
├── main.dart              (Main app - login, chat, profile, home, groups, status)
├── friend_request.dart    (Friend request system)
├── user_profile.dart      (User profile screen - doosre user ki)
├── avatar_builder.dart    (2D avatar builder + AvatarWidget)
├── status_screen.dart     (Status/Stories feature) — NEW
└── group_info.dart        (Group info + admin controls) — NEW
```

---

🔥 Firestore Database Structure

Collections:

users/{uid}

```json
{
  "uid": "user_uid",
  "email": "user@example.com",
  "username": "vasim1234",
  "avatarUrl": "base64_string_or_url",
  "bio": "Apne baare mein...",
  "status": "Jeena yahan, marna yahan",
  "birthday": "timestamp",
  "createdAt": "timestamp",
  "pinnedChats": ["chatId1", "chatId2"],
  "isOnline": true,
  "lastSeen": "timestamp"
}
```

chats/{messageId}

```json
{
  "chatId": "uid1_uid2",
  "members": ["uid1", "uid2"],
  "senderId": "uid1",
  "receiverId": "uid2",
  "message": "Hello",
  "imageBase64": "base64_string_or_null",
  "voiceBase64": "base64_string_or_null",
  "replyTo": {
    "message": "original message",
    "senderName": "User Name",
    "senderId": "uid"
  },
  "timestamp": "timestamp",
  "expiresAt": "timestamp (24h baad)",
  "isEdited": false,
  "isDeleted": false,
  "isRead": false
}
```

friend_requests/{requestId}

```json
{
  "senderId": "uid1",
  "receiverId": "uid2",
  "status": "pending|accepted|rejected",
  "timestamp": "timestamp"
}
```

friends/{uid1_uid2}

```json
{
  "uid1": "uid1",
  "uid2": "uid2",
  "createdAt": "timestamp"
}
```

blocked/{uid1_uid2}

```json
{
  "blockerId": "uid1",
  "blockedId": "uid2",
  "timestamp": "timestamp"
}
```

groups/{groupId}

```json
{
  "name": "Group Name",
  "bio": "Group ke baare mein...",
  "groupPhoto": "base64_string_or_null",
  "members": ["uid1", "uid2", "uid3"],
  "createdBy": "uid1",
  "createdAt": "timestamp",
  "lastRead": {
    "uid1": "timestamp",
    "uid2": "timestamp"
  }
}
```

group_messages/{messageId}

```json
{
  "groupId": "groupId",
  "senderId": "uid1",
  "message": "Hello group",
  "imageBase64": "base64_string_or_null",
  "timestamp": "timestamp",
  "expiresAt": "timestamp"
}
```

status/{statusId}

```json
{
  "userId": "uid1",
  "username": "vasim1234",
  "avatarUrl": "base64_or_url",
  "type": "text|image",
  "content": "text_or_base64",
  "bgColor": "667EEA",
  "timestamp": "timestamp",
  "expiresAt": "timestamp (24h baad)",
  "viewers": ["uid2", "uid3"]
}
```

typing/{chatId}

```json
{
  "uid1": true,
  "uid2": false
}
```

---

🔐 Firestore Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    match /status/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

🔥 Firestore Indexes

chats Collection

· chatId — Ascending
· timestamp — Descending
· members — Array contains (arrayConfig: CONTAINS)
· __name__ — Ascending

friend_requests Collection

· senderId — Ascending
· receiverId — Ascending
· status — Ascending

group_messages Collection

· groupId — Ascending
· timestamp — Descending

status Collection

· timestamp — Descending

---

📲 OneSignal Notifications

OneSignal App ID

```
05bee600-4a45-44e5-b35e-5328544c25c1
```

OneSignal REST API Key

Note: Ye GitHub par public nahi karni chahiye. --dart-define=ONESIGNAL_REST_API_KEY=... ke through inject hoti hai GitHub Secret se.

Firebase Service Account JSON

OneSignal mein upload hai (Settings → Push & In-App → Google Android (FCM)).

Notification Kaise Kaam Karti Hai

1. User login karta hai → OneSignal.login(uid) call hota hai
2. Message bhejta hai → _sendNotification() function HTTP request bhejta hai
3. OneSignal receiver ke device par notification bhejta hai

Important Files

· main.dart line 22 — OneSignal initialize
· ChatScreen — App ID + REST API Key
· LoginScreen — OneSignal.login()
· ProfileScreen — OneSignal.logout()

---

🐛 Known Issues / Fixes

Issue 1: Photo Bhejne Par Firebase Storage Error

Fix: Firebase Storage hata diya, ab Base64 use kar rahe hain.

Issue 2: Read Receipts Real-Time Update Nahi Ho Rahe

Fix: _getMessages() mein includeMetadataChanges: true add kiya.

Issue 3: Images Flicker / Re-render

Fix: _imageCache map banaya.

Issue 4: Chat List Mein Messages Nahi Aa Rahe

Fix: chats collection mein members array add kiya.

Issue 5: Tab Switch Par Chat List Gayab Hona

Fix: HomeScreen mein IndexedStack use kiya.

Issue 6: avatarUrl Missing Hone Par Crash

Fix: containsKey('avatarUrl') se check kiya.

Issue 7: Message Send Karne Par Input Box Delay

Fix: _msgController.clear() ko message save karne se pehle call kiya.

Issue 8: OneSignal 401 Error

Fix: Nayi REST API Key banayi, aur --dart-define ke through GitHub Secret se inject kiya.

Issue 9: Group Chat Messages Load Nahi Ho Rahe (FAILED_PRECONDITION)

Fix: Firestore Composite Index banaya — group_messages collection pe groupId (ASC) + timestamp (DESC).

Issue 10: record Package Build Fail

Fix: record package hata diya, flutter_sound use kiya.

Issue 11: audioplayers Build Fail

Fix: audioplayers hata diya, flutter_sound use kiya.

Issue 12: permission_handler Build Fail (v1 embedding)

Fix: permission_handler: 11.0.1 → 12.0.0 kiya.

Issue 13: Voice Recording _CodecNotSupportedException

Fix: Codec.aacADTS → Codec.aacMP4 kiya (recording + playback).

Issue 14: Voice Playback - Audio Nahi Aa Rahi (mic test pending)

Status: Mic hardware issue hai, dusre phone pe test karna hai.

---

🚀 Build & Deploy

GitHub Actions (Automatic APK Build)

Har push par .github/workflows/build.yml chalega aur APK bana dega.

Workflow File

```yaml
name: Build APK

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Create Google Services JSON File
        env:
          GOOGLE_SERVICES_JSON: ${{ secrets.GOOGLE_SERVICES_JSON }}
        run: echo "$GOOGLE_SERVICES_JSON" > ./android/app/google-services.json

      - name: Get dependencies
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release --dart-define=ONESIGNAL_REST_API_KEY=${{ secrets.ONESIGNAL_REST_API_KEY }}

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

GitHub Secrets Required

· GOOGLE_SERVICES_JSON — Firebase config file ka content
· ONESIGNAL_REST_API_KEY — OneSignal REST API Key

---

👨‍💻 Developer Notes

Firebase Project

· Project Name: Bhai bhai app
· Project ID: bhai-bhai-app
· Package Name: com.example.bhaibhai_securechat

Important Functions

· areFriends(uid1, uid2) — Check karein ki dono friend hain
· sendFriendRequest(receiverUid) — Friend request bhejein
· acceptFriendRequest(requestId, senderId) — Accept karein
· unFriend(otherUid) — Unfriend karein
· _setOnlineStatus(bool) — Online status update
· _setTypingStatus(bool) — Typing status update
· _buildCachedImage(base64String) — Cached image widget
· _sendNotification(message) — OneSignal notification bhejein
· _getUnreadCount(chatId) — Unread messages count
· _getGroupUnreadCount(groupId) — Group unread count
· _saveStatus({type, content, bgColor}) — Status save karein
· _markGroupAsRead() — Group ko read mark karein

Code Conventions

· Snake_case for file names
· PascalCase for classes
· camelCase for variables and functions
· Private functions start with _ (underscore)

---

📝 Roadmap (Future Features)

Phase 1 (Completed ✅)

· ☑ Basic Chat
· ☑ Friend System
· ☑ Photo Sharing (Base64)
· ☑ Read Receipts
· ☑ Typing Indicator
· ☑ Online Status
· ☑ Push Notifications (OneSignal)
· ☑ Unread Badge
· ☑ Fast Message Send
· ☑ Modern Profile Screens
· ☑ Bio, Status, Birthday
· ☑ Group Chat
· ☑ Group Photo
· ☑ Group Admin Controls
· ☑ Add/Remove Group Members
· ☑ Status Updates (Stories)
· ☑ Modern Login Screen
· ☑ Modern Chat List
· ☑ Filter Chips (All, Unread, Favourites, Groups)

Phase 2 (Next)

· ☐ Voice Message (mic test pending)
· ☐ Chat List Search Function
· ☐ Communities Tab
· ☐ Pinned Messages

Phase 3 (Future)

· ☐ Voice/Video Calling (WebRTC + TURN server)
· ☐ Video Status (Firebase Storage)
· ☐ Photo + Song Status (Firebase Storage)
· ☐ End-to-End Encryption
· ☐ Two-Factor Auth
· ☐ Message Forwarding
· ☐ Chat Wallpaper
· ☐ Chat Statistics

---

🎯 Important Notes for New Developers

1. Firebase Storage hata diya — sab Base64 use kar rahe hain (photo, voice, status, group photo)
2. Voice Message — flutter_sound use kar rahe hain, Codec.aacMP4
3. Firestore 1 MB limit — chhoti files hi Base64 mein store karo
4. Firestore Indexes — group_messages aur status collection pe composite index zaroori hai
5. OneSignal REST API Key — GitHub Secret mein hai, code mein hardcode nahi
6. GitHub Actions — har push pe APK automatically build hoti hai

---

📄 License

MIT License — Free to use, modify, and distribute.

Last Updated: October 2026

```

---

## 📋 Ab Kya Karo

| Step | Kaam |
|------|------|
| 1 | GitHub pe `PROJECT_INFO.md` kholo |
| 2 | **Edit** (pencil icon) dabao |
| 3 | **Poora content delete karo** (Ctrl+A → Delete) |
| 4 | **Upar wala naya content paste karo** |
| 5 | **Commit changes** dabao |
| 6 | **Message:** `Update PROJECT_INFO.md with all new features` |
| 7 | **Green `Commit changes`** dabao |

---

**Bhai, ye poora content paste karo `PROJECT_INFO.md` mein aur commit karo — phir naye chat mein mujhe sab pata hoga!** 💪🚀
