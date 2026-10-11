
# Bhai Bhai Secure Chat - Project Info

## 📱 App Overview

**Bhai Bhai Secure Chat** ek modern, secure messaging app hai jo WhatsApp jaisi features deti hai. Ye Flutter mein bani hai aur Firebase backend use karti hai.

**App ka Main Feature:** 24-hour ephemeral messaging — yani har message 24 ghante baad automatically delete ho jata hai.

## ✅ Core Features (Jo Ab Tak Complete Hain)

### Authentication & User Management
- ✅ Email/Password se Login/Signup (modern gradient UI)
- ✅ Unique Username system (jaise `vasim1234`)
- ✅ Forgot Password (email reset link)
- ✅ Google Sign-In button (placeholder)
- ✅ Online/Offline status (real-time green dot)
- ✅ Last Seen time

### User Profile (Modern Design)
- ✅ Gradient Banner (purple-blue) header
- ✅ Avatar with photo upload (Base64 format)
- ✅ Bio field (150 characters)
- ✅ Status/Quote field (50 characters)
- ✅ Birthday (date picker)
- ✅ My QR Code (UID based)
- ✅ Stats — Contacts, Hisaab, Blocked counts
- ✅ Account Settings — Privacy, Notifications, App Update, App Share, iPhone App, Logout
- ✅ Modern Edit Profile dialog
- ✅ Camera icon on avatar for quick photo change

### Chat Features
- ✅ Real-time messaging (Firestore)
- ✅ 24-Hour Auto-Delete
- ✅ Read Receipts (✓ single tick, ✓✓ blue double tick)
- ✅ Typing Indicator
- ✅ Reply to Message
- ✅ Message Edit/Delete
- ✅ Photo Bhejna (Base64 format)
- ✅ Image Caching
- ✅ Fast Message Send (Instant UI)
- ✅ Unread Badge (green circle count)
- ✅ Chat List with 4 Filter Chips (All, Unread, Favourites, Groups)
- ✅ Pin Chat
- ✅ Modern Chat Cards (rounded, shadow)
- ✅ Voice Message — code ready, mic test pending

### Social Features
- ✅ Search Users (username se)
- ✅ Friend Request System (badge ke saath)
- ✅ Accept/Reject Friend Request
- ✅ Unfriend option
- ✅ Block/Unblock Users
- ✅ Blocked Users List
- ✅ Friends List — tap pe user profile khulti hai
- ✅ Profile → Message → Chat — direct chat khulti hai

### Group Features (Complete)
- ✅ Group Chat (multiple users)
- ✅ Group Info Screen with modern UI
- ✅ Group Photo (Base64 format)
- ✅ Group Bio (150 characters)
- ✅ Admin Controls:
  - ✅ Change Group Name (sirf admin)
  - ✅ Change Group Bio (sirf admin)
  - ✅ Delete Group (sirf admin)
- ✅ Add Members (admin)
- ✅ Exit Group
- ✅ Group Unread Badge
- ✅ Members List (admin badge ke saath)
- ✅ "GROUPS" section chat list mein
- ✅ Group chat list with unread count

### Status Updates (Stories)
- ✅ Text Status (6 colors mein)
- ✅ Photo Status (Base64 format)
- ✅ 24-hour auto-delete
- ✅ Full-screen viewer
- ✅ Progress bars
- ✅ Viewers tracking
- ✅ "My Status" tile
- ✅ "Recent Updates" (green ring)
- ✅ Time ago ("Just now", "5m ago")

### Hisaab Kitaab (Khata Book)
- ✅ Khata List — bande ki list
- ✅ Per-Person Khata — har bande ka pura hisaab
- ✅ Add Entry — Diya / Liya (amount, note, date)
- ✅ Balance Calculation — automatic
- ✅ Settle / Unsettle — entry settle kar sakte ho
- ✅ Edit / Delete — entries
- ✅ Total Balance — top pe (lena/dena)
- ✅ PDF Export — hisaab ki PDF save karo
- ✅ WhatsApp Send — hisaab WhatsApp pe bhejo
- ✅ Call / WhatsApp — bande ke phone number pe
- ✅ Settled Entries — grey ho jati hain
- ✅ No 24h delete — permanent rahega
- ✅ Access: Profile → Hisaab stat

### Notifications
- ✅ Push Notifications (OneSignal)
- ✅ App se notification (REST API)
- ✅ Manual notification (OneSignal Dashboard)

## 🚧 Features Jo Baaki Hain

### Priority 1
- ⏳ Voice Message — code ready, mic test pending
- ⏳ Chat List Search — search bar hai, filter logic pending

### Priority 2
- ⏳ Communities Tab — currently "jald aa raha hai"
- ⏳ Link Share — Instagram/YouTube/Facebook link clickable + preview

### Priority 3
- ⏳ Voice/Video Calling (WebRTC + TURN server)
- ⏳ Video Status (Firebase Storage)
- ⏳ Photo + Song Status (Firebase Storage)
- ⏳ End-to-End Encryption
- ⏳ Two-Factor Auth
- ⏳ Message Forwarding
- ⏳ Chat Wallpaper
- ⏳ Chat Statistics

## 🛠️ Technology Stack

### Frontend
- Flutter (Dart)
- Material 3 design
- Provider/StreamBuilder state management

### Backend
- Firebase Core (initialization)
- Firebase Auth (Email/Password)
- Cloud Firestore (real-time database)
- Firebase Storage — HATA DIYA (Base64 use kar rahe hain)

### Notifications
- OneSignal (Push Notifications)
- OneSignal REST API (app se notification)
- Firebase Service Account JSON (OneSignal mein upload)

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
  permission_handler: 12.0.0
  url_launcher: ^6.3.0
  pdf: ^3.11.1
  printing: ^5.13.1
```

File Structure

```
lib/
├── main.dart                  (Main app - login, chat list, home, profile, search)
├── friend_request.dart        (Friend request system + FriendsListScreen)
├── user_profile.dart          (User profile screen - doosre user ki)
├── avatar_builder.dart        (2D avatar builder + AvatarWidget)
├── chat_screen.dart           (ChatScreen + GroupChatScreen + CreateGroupScreen)
├── status_screen.dart         (Status/Stories feature)
├── group_info.dart            (Group info + admin controls)
├── khata_screen.dart          (Hisaab Kitaab - khata list)
└── khata_detail_screen.dart   (Bande ka khata - ledger)
```

🎨 App Navigation Structure

Bottom Navigation (4 tabs)

Icon Tab Kya Dikhta Hai
💬 Chats Chat list + Groups
📊 Updates Status/Stories
📞 Calls Call history (placeholder)
👤 Profile Apni profile + Settings

Profile Screen Stats (3 stats)

Stat Tap Karo Kya Khulega
👥 Contacts Tap FriendsListScreen
📒 Hisaab Tap KhataScreen
🚫 Blocked Tap BlockedUsersScreen

Chats List Top-Right

· 👥 Group Add — naya group banao

Profile Screen Settings

Option Tap Karo Kya Hoga
🛡️ Privacy Bottom sheet Last Seen, Profile Photo, Read Receipts, Blocked
🔔 Notifications Bottom sheet 5 toggle switches
⬆️ App Update Play Store khulega Update check
🔗 App Share WhatsApp khulega Download link bhejo
📱 iPhone App Dialog iOS jald aa raha hai
🚪 Logout Sign out 

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

khate/{khataId} — Hisaab Kitaab

```json
{
  "userId": "uid1",
  "personName": "Raju",
  "phoneNumber": "9876543210",
  "createdAt": "timestamp"
}
```

hisab/{entryId} — Hisaab Entries

```json
{
  "userId": "uid1",
  "khataId": "khataId_of_Raju",
  "personName": "Raju",
  "phoneNumber": "9876543210",
  "amount": 300,
  "type": "diya|liya",
  "date": "timestamp",
  "note": "Gym fees",
  "isSettled": false,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

typing/{chatId}

```json
{
  "uid1": true,
  "uid2": false
}
```

🔐 Firestore Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    match /users/{document} {
      allow read, write: if request.auth != null;
    }
    match /friends/{document} {
      allow read, write: if request.auth != null;
    }
    match /status/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /hisab/{document} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    match /khate/{document} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
  }
}
```

🔥 Firestore Indexes

chats Collection

· chatId — Ascending
· timestamp — Descending
· members — Array contains
· name — Ascending

friend_requests Collection

· senderId — Ascending
· receiverId — Ascending
· status — Ascending

group_messages Collection

· groupId — Ascending
· timestamp — Descending

status Collection

· timestamp — Descending

khate Collection

· userId — Ascending
· createdAt — Descending

hisab Collection

· khataId — Ascending
· timestamp — Descending

📲 OneSignal Notifications

OneSignal App ID

Note: Ye GitHub Secrets mein hai — ONESIGNAL_APP_ID.

OneSignal REST API Key

Note: Ye GitHub Secrets mein hai — ONESIGNAL_REST_API_KEY.

Firebase Service Account JSON

OneSignal mein upload hai (Settings → Push & In-App → Google Android (FCM)).

Notification Kaise Kaam Karti Hai

1. User login karta hai → OneSignal.login(uid) call hota hai
2. Message bhejta hai → _sendNotification() function HTTP request bhejta hai
3. OneSignal receiver ke device par notification bhejta hai

Important Files

· main.dart — OneSignal initialize
· chat_screen.dart — App ID + REST API Key
· LoginScreen — OneSignal.login()
· ProfileScreen — OneSignal.logout()

🐛 Known Issues / Fixes

Issue 1: Photo Bhejne Par Firebase Storage Error

Fix: Firebase Storage hata diya, Base64 use kar rahe hain.

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

Fix: Nayi REST API Key banayi, GitHub Secret se inject kiya.

Issue 9: Group Chat Messages Load Nahi Ho Rahe

Fix: group_messages collection pe composite index banaya.

Issue 10: record Package Build Fail

Fix: record hata diya, flutter_sound use kiya.

Issue 11: audioplayers Build Fail

Fix: audioplayers hata diya, flutter_sound use kiya.

Issue 12: permission_handler Build Fail (v1 embedding)

Fix: permission_handler: 11.0.1 → 12.0.0.

Issue 13: Voice Recording _CodecNotSupportedException

Fix: Codec.aacADTS → Codec.aacMP4.

Issue 14: Voice Playback Audio Nahi Aa Rahi

Status: Mic hardware issue hai, dusre phone pe test pending.

Issue 15: Friend Request Screen Crash

Fix: flutter_contacts hata diya, manual phone number entry.

Issue 16: Message Button Se Chat Nahi Khul Rahi

Fix: ChatScreen alag chat_screen.dart file mein move kiya, aur Navigator.push use kiya.

Issue 17: Contacts Count Galat Dikha Raha

Fix: _loadStats() — chats collection ki jagah friends collection se count kiya.

Issue 18: khate Index Missing

Fix: khate collection pe composite index banaya (userId ASC + createdAt DESC).

Issue 19: hisab Index Missing

Fix: hisab collection pe composite index banaya (khataId ASC + timestamp DESC).

Issue 20: friends Collection Mein Random UID

Fix: Purane documents delete karke, app se naya friend add kiya.

Issue 21: ChatScreen + GroupChatScreen Duplicate

Fix: chat_screen.dart mein move kiye, main.dart se delete kiya.

Issue 22: khata_screen.dart Duplicate Import

Fix: Duplicate import hata diya.

Issue 23: ChatScreen Codec Mismatch (Playback)

Fix: _playVoice() mein Codec.aacADTS → Codec.aacMP4.

Issue 24: Hisaab Tab Slow Khul Raha Tha

Fix: FutureBuilder use kiya, StreamBuilder ki jagah.

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

👨‍💻 Developer Notes

Firebase Project

· Project Name: [Firebase Console se lo]
· Project ID: [Firebase Console se lo]
· Package Name: com.example.bhaibhai_securechat

Important Functions

· areFriends(uid1, uid2) — Check friends
· sendFriendRequest(receiverUid) — Friend request bhejein
· acceptFriendRequest(requestId, senderId) — Accept karein
· unFriend(otherUid) — Unfriend karein
· _setOnlineStatus(bool) — Online status
· _setTypingStatus(bool) — Typing status
· _buildCachedImage(base64String) — Cached image widget
· _sendNotification(message) — OneSignal notification
· _getUnreadCount(chatId) — Unread messages count
· _getGroupUnreadCount(groupId) — Group unread count
· _saveStatus({type, content, bgColor}) — Status save
· _markGroupAsRead() — Group read mark
· _exportPDF() — PDF export (khata detail)
· _sendViaWhatsApp() — WhatsApp share (khata detail)

Code Conventions

· Snake_case for file names
· PascalCase for classes
· camelCase for variables and functions
· Private functions start with _

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
· ☑ Filter Chips
· ☑ Hisaab Kitaab (Khata Book)
· ☑ PDF Export + WhatsApp Send
· ☑ chat_screen.dart — Alag file
· ☑ Bottom nav: Chats, Updates, Calls, Profile
· ☑ Profile stats: Contacts, Hisaab, Blocked
· ☑ Functional Settings: Privacy, Notifications, App Update, App Share, iPhone App

Phase 2 (Next)

· ☐ Voice Message (mic test pending)
· ☐ Chat List Search
· ☐ Communities Tab
· ☐ Link Share (Instagram/YouTube/Facebook)

Phase 3 (Future)

· ☐ Voice/Video Calling (WebRTC + TURN)
· ☐ Video Status (Firebase Storage)
· ☐ Photo + Song Status (Firebase Storage)
· ☐ End-to-End Encryption
· ☐ Two-Factor Auth
· ☐ Message Forwarding
· ☐ Chat Wallpaper
· ☐ Chat Statistics

🎯 Important Notes for New Developers

1. Firebase Storage hata diya — sab Base64 use kar rahe hain
2. Voice Message — flutter_sound use, Codec.aacMP4
3. Firestore 1 MB limit — chhoti files hi Base64 mein
4. Firestore Indexes — group_messages, status, khate, hisab pe composite index
5. OneSignal REST API Key — GitHub Secret mein
6. GitHub Actions — har push pe APK automatically build
7. ChatScreen — chat_screen.dart mein hai (main.dart mein nahi)
8. Hisaab Kitaab — khate + hisab collections
9. PROJECT_INFO.md — sensitive info hide ki hui hai
