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
- ✅ **Fast Message Send (Instant UI update - WhatsApp jaisa)**
- ✅ **Unread Badge (chat list mein green circle count)**

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

### Notifications
- ✅ **Push Notifications (OneSignal)**
- ✅ **App se bheji gayi notification (REST API se)**
- ✅ **Manual notification (OneSignal Dashboard se)**

---

## 🚧 Features Jo Baaki Hain

### Priority 1
- ⏳ Voice/Video Calling (WebRTC)

### Priority 2
- ⏳ Chats List mein Search Function (currently working nahi hai)
- ⏳ Group Admin Controls

### Priority 3
- ⏳ Status Updates (Stories)
- ⏳ End-to-End Encryption
- ⏳ Two-Factor Auth
- ⏳ Message Forwarding

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

### Notifications
- **OneSignal** (Push Notifications)
- **OneSignal REST API** (app se notification bhejne ke liye)
- **Firebase Service Account JSON** (OneSignal mein upload hai)

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
  http: ^1.2.0
  onesignal_flutter: ^5.3.0

lib/
├── main.dart              (Main app - login, chat, profile, home)
├── friend_request.dart    (Friend request system)
├── user_profile.dart      (User profile screen)
└── avatar_builder.dart    (2D avatar builder + AvatarWidget)

Iske Baad Ye Content Add Karein

avatar_builder.dart wali line ke baad, ye pura content copy karke paste karein:

```markdown

---

## 🔥 Firestore Database Structure

### Collections:

#### `users/{uid}`
```json
{
  "uid": "user_uid",
  "email": "user@example.com",
  "username": "vasim1234",
  "avatarUrl": "https://api.dicebear.com/...",
  "createdAt": "timestamp",
  "pinnedChats": ["chatId1", "chatId2"],
  "isOnline": true,
  "lastSeen": "timestamp"
}
```

chats/{chatId}

```json
{
  "chatId": "uid1_uid2",
  "members": ["uid1", "uid2"],
  "senderId": "uid1",
  "receiverId": "uid2",
  "message": "Hello",
  "imageBase64": "base64_string_or_null",
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
  "members": ["uid1", "uid2", "uid3"],
  "createdBy": "uid1",
  "createdAt": "timestamp"
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

---

📲 OneSignal Notifications

OneSignal App ID

```
05bee600-4a45-44e5-b35e-5328544c25c1
```

OneSignal REST API Key

Note: Ye GitHub par public nahi karni chahiye. Sirf testing ke liye ChatScreen mein hai.

Firebase Service Account JSON

OneSignal mein upload hai (Settings -> Push & In-App -> Google Android (FCM)).

Notification Kaise Kaam Karti Hai:

1. User login karta hai → OneSignal.login(uid) call hota hai
2. Message bhejta hai → _sendNotification() function HTTP request bhejta hai
3. OneSignal receiver ke device par notification bhejta hai

Important Files:

· main.dart line 22 — OneSignal initialize
· ChatScreen line 2327 — App ID + REST API Key
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

---

🚀 Build & Deploy

GitHub Actions (Automatic APK Build)

Har push par .github/workflows/build.yml chalega aur APK bana dega.

Workflow File:

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

Code Conventions

· Snake_case for file names
· PascalCase for classes
· camelCase for variables and functions
· Private functions start with _ (underscore)

---

📝 Roadmap (Future Features)

Phase 1 (Completed)

☑ Basic Chat
☑ Friend System
☑ Avatar Builder
☑ Photo Sharing (Base64)
☑ Read Receipts
☑ Typing Indicator
☑ Online Status
☑ Push Notifications (OneSignal)
☑ Unread Badge
☑ Fast Message Send

Phase 2 (Next)

☐ Voice/Video Calling (WebRTC)
☐ Chats Search Function
☐ Group Admin Controls

Phase 3 (Future)

☐ Status Updates (Stories)
☐ End-to-End Encryption
☐ Two-Factor Auth
☐ Message Forwarding

---

📄 License

MIT License — Free to use, modify, and distribute.

---

Last Updated: October 2026

```

---

### Step 4: Commit Changes

Neeche **"Commit changes"** button dabayein.

---

## 🎯 Bhai, Ab Kya Hoga:

- Aapki `PROJECT_INFO.md` **complete** ho jayegi
- Isme **Firestore structure**, **rules**, **indexes**, **OneSignal setup**, **known issues**, **build process**, aur **roadmap** honge
- **Har naye chat mein**, main ise padh kar pura project samajh jaunga

**Bhai, ab ye content add karein aur commit karein!** 🚀

*Bas itna hi karna hai. Samajh nahi aaye toh bataiye, main aur aasaan tarike se batata hoon.*
