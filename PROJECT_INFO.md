
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
- ✅ **Message Star (Favourite)** — long press → Star/Unstar
- ✅ **Message Forward** — kisi bhi user ko forward
- ✅ Photo Bhejna (Base64 format)
- ✅ Image Caching
- ✅ Fast Message Send (Instant UI)
- ✅ Unread Badge (green circle count)
- ✅ Chat List with 4 Filter Chips (All, Unread, Favourites, Groups)
- ✅ **Filter Chips pe Unread Count Badge** — har tab pe count dikhta hai
- ✅ **Pin Chat**
- ✅ Modern Chat Cards (rounded, shadow)
- ✅ **Chat Wallpaper** — 8 preset colors + Gallery se photo
- ✅ **Chat Mute** — notification band karo
- ✅ Voice Message — code ready, mic test pending
- ✅ YouTube/Instagram Link Preview (thumbnail + title)
- ✅ Clickable Links in messages

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
  - ✅ Remove Members (admin)
- ✅ Members List (admin badge 👑 ke saath)
- ✅ **Group Chat mein Sender Avatar + Colored Name** (WhatsApp jaisa)
- ✅ **Group Reply** — kisi bhi message pe reply
- ✅ **Group Edit/Delete** — apne message pe
- ✅ **Group Notification** — har member ko notification jata hai
- ✅ **Group Unread Count** — green badge with number
- ✅ **Group Read Mark** — group kholne pe unread 0 ho jata hai
- ✅ Exit Group
- ✅ Group Unread Badge
- ✅ "GROUPS" section chat list mein
- ✅ Group chat list with unread count

### Status Updates (Stories)
- ✅ Text Status (8 colors mein)
- ✅ Photo Status (Base64 format)
- ✅ 24-hour auto-delete
- ✅ Full-screen viewer
- ✅ Progress bars
- ✅ Viewers tracking
- ✅ **Viewed by List** — kaun-kaun ne dekha (bottom sheet mein)
- ✅ "My Status" tile
- ✅ "Recent Updates" (green ring for unseen)
- ✅ Time ago ("Just now", "5m ago")
- ✅ Reply to Status — status pe reply karo
- ✅ Delete Status — apna status delete karo
- ✅ **Status Forward** (coming soon)

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
- ✅ **Group Notifications** — sabhi members ko parallel
- ✅ **Chat Mute** — notification band karo
- ✅ **Background Notifications** — UI block nahi hota

### Performance Optimizations
- ✅ **Fast Tab Switching** — instant switch, no loading
- ✅ **Debounced Count Updates** — 500ms debounce
- ✅ **3-Second Cache** — dobara query nahi
- ✅ **Parallel Firebase Queries** — Future.wait() use
- ✅ **Background Notification Send** — non-blocking
- ✅ **Image Caching** — image re-render nahi
- ✅ **Instant Message Send** — UI block nahi

---

## 🚧 Features Jo Baaki Hain

### Priority 1
- ⏳ Voice Message — code ready, mic test pending
- ⏳ Group Voice Message — group mein voice bhejo

### Priority 2
- ⏳ Communities Tab — currently "jald aa raha hai"
- ⏳ Chat List Search — search bar hai, filter logic pending
- ⏳ Starred Messages Screen — starred messages ki list
- ⏳ Muted Chats Screen — muted chats list
- ⏳ Message Info — kisne kab padha (group)
- ⏳ Message Reaction — ❤️😂👍
- ⏳ Message Search — messages ke andar search

### Priority 3
- ⏳ Voice/Video Calling (WebRTC + TURN server)
- ⏳ Video Status (Firebase Storage)
- ⏳ Photo + Song Status (Firebase Storage)
- ⏳ End-to-End Encryption
- ⏳ Two-Factor Auth
- ⏳ Chat Statistics
- ⏳ Screenshot Notification
- ⏳ Status Forward
- ⏳ Reply Preview Tap — reply pe tap karke original pe jao

---

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
  permission_handler: ^12.0.0
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

---

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

Filter Chips (Top)

· All — total unread count badge
· Unread — unread chats count badge
· Favourites — pinned chats unread count badge
· Groups — groups unread count badge

Profile Screen Settings

Option Tap Karo Kya Hoga
🛡️ Privacy Tap Bottom sheet
🔔 Notifications Tap Bottom sheet
⬆️ App Update Tap Play Store khulega
🔗 App Share Tap WhatsApp khulega
📱 iPhone App Tap Dialog
🚪 Logout Tap Sign out

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
  "linkUrl": "https://youtu.be/...",
  "linkTitle": "Video Title",
  "linkThumbnail": "https://img.youtube.com/...",
  "linkType": "youtube|instagram|other",
  "timestamp": "timestamp",
  "expiresAt": "timestamp (24h baad)",
  "isEdited": false,
  "isDeleted": false,
  "isRead": false,
  "isStarred": false
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
  "replyTo": {
    "message": "original message",
    "senderName": "User Name",
    "senderId": "uid"
  },
  "linkUrl": "https://...",
  "linkTitle": "Title",
  "linkThumbnail": "url",
  "linkType": "youtube|instagram|other",
  "timestamp": "timestamp",
  "expiresAt": "timestamp",
  "isEdited": false,
  "isDeleted": false
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

Sub-collections:

users/{uid}/wallpapers/{chatId}

```json
{
  "wallpaper": "F5F7FB|IMG:base64...",
  "updatedAt": "timestamp"
}
```

users/{uid}/muted_chats/{chatId}

```json
{
  "mutedAt": "timestamp"
}
```

users/{uid}/muted_groups/{groupId}

```json
{
  "mutedAt": "timestamp"
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

---

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

---

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
3. Personal chat → receiver ko notification
4. Group chat → sabhi members ko parallel notification
5. OneSignal receiver ke device par notification bhejta hai

Mute System

· Chat mute → users/{uid}/muted_chats/{chatId} doc
· Group mute → users/{uid}/muted_groups/{groupId} doc
· Notification bhejne se pehle mute check hota hai

Important Files

· main.dart — OneSignal initialize
· chat_screen.dart — App ID + REST API Key
· LoginScreen — OneSignal.login()
· ProfileScreen — OneSignal.logout()

---

🐛 Known Issues / Fixes

Major Fixes (Latest Update)

Fix 1: Tab Switch pe Flicker/Loading

· Problem: Filter chips pe unread count update karne ke liye addPostFrameCallback infinite loop bana raha tha
· Fix: _isUpdatingCounts flag + 500ms debounce Timer + 3-second cache

Fix 2: Group Message Send Slow

· Problem: Group notification await kar raha tha, message send block ho raha tha
· Fix: _sendGroupNotificationsInBackground() — background mein notification, message instantly send

Fix 3: Tab Switch pe 1 Second Loading

· Problem: _updateUnreadCounts har rebuild pe chal raha tha
· Fix: Future.wait() parallel queries + _lastCountUpdate cache (3 second)

Fix 4: Same Tab pe Tap Flicker

· Problem: Same tab pe tap karo to bhi setState call ho raha tha
· Fix: if (_selectedFilter != label) check

Older Fixes

Fix 5: Photo Bhejne Par Firebase Storage Error

· Firebase Storage hata diya, Base64 use kar rahe hain

Fix 6: Read Receipts Real-Time Update Nahi Ho Rahe

· _getMessages() mein includeMetadataChanges: true add kiya

Fix 7: Images Flicker / Re-render

· _imageCache map banaya

Fix 8: Chat List Mein Messages Nahi Aa Rahe

· chats collection mein members array add kiya

Fix 9: Tab Switch Par Chat List Gayab Hona

· HomeScreen mein IndexedStack use kiya

Fix 10: avatarUrl Missing Hone Par Crash

· containsKey('avatarUrl') se check kiya

Fix 11: Message Send Karne Par Input Box Delay

· _msgController.clear() ko message save karne se pehle call kiya

Fix 12: OneSignal 401 Error

· Nayi REST API Key banayi, GitHub Secret se inject kiya

Fix 13: Group Chat Messages Load Nahi Ho Rahe

· group_messages collection pe composite index banaya

Fix 14: record Package Build Fail

· record hata diya, flutter_sound use kiya

Fix 15: audioplayers Build Fail

· audioplayers hata diya, flutter_sound use kiya

Fix 16: permission_handler Build Fail (v1 embedding)

· permission_handler: 11.0.1 → 12.0.0

Fix 17: Voice Recording _CodecNotSupportedException

· Codec.aacADTS → Codec.aacMP4

Fix 18: Voice Playback Audio Nahi Aa Rahi

· Status: Mic hardware issue hai, dusre phone pe test pending

Fix 19: Friend Request Screen Crash

· flutter_contacts hata diya, manual phone number entry

Fix 20: Message Button Se Chat Nahi Khul Rahi

· ChatScreen alag chat_screen.dart file mein move kiya

Fix 21: Contacts Count Galat Dikha Raha

· _loadStats() — chats collection ki jagah friends collection se count

Fix 22: khate Index Missing

· khate collection pe composite index banaya

Fix 23: hisab Index Missing

· hisab collection pe composite index banaya

Fix 24: friends Collection Mein Random UID

· Purane documents delete karke, app se naya friend add kiya

Fix 25: ChatScreen + GroupChatScreen Duplicate

· chat_screen.dart mein move kiye

Fix 26: khata_screen.dart Duplicate Import

· Duplicate import hata diya

Fix 27: ChatScreen Codec Mismatch (Playback)

· _playVoice() mein Codec.aacADTS → Codec.aacMP4

Fix 28: Hisaab Tab Slow Khul Raha Tha

· FutureBuilder use kiya

Fix 29: linkify Package Build Error

· linkify hata diya, manual regex use kiya

Fix 30: Filter Chips pe Unread Count Nahi Dikhta

· _updateUnreadCounts() function add kiya

Fix 31: Group Unread Count Nahi Dikhta

· lastRead timestamp system + _getGroupUnreadCount() function

Fix 32: Group Notification Nahi Aata

· _sendGroupNotification() function add kiya + background notification

Fix 33: Group Message Send Slow

· Notification background mein, message instant

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
· _sendNotification(message) — OneSignal notification (personal)
· _sendNotificationInBackground(message) — Background notification
· _sendGroupNotification(...) — Group notification
· _sendGroupNotificationsInBackground(...) — Parallel group notification
· _getUnreadCount(chatId) — Unread messages count
· _getGroupUnreadCount(groupId) — Group unread count
· _updateUnreadCounts(chatList, groupsList) — Saare counts update
· _saveStatus({type, content, bgColor}) — Status save
· _markGroupAsRead() — Group read mark
· _exportPDF() — PDF export (khata detail)
· _sendViaWhatsApp() — WhatsApp share (khata detail)
· _showViewersList(viewers) — Status viewers list
· _showForwardPicker(message, data) — Forward picker
· _forwardMessage(receiverUid, message, data) — Forward message
· _showWallpaperPicker() — Wallpaper picker
· _saveWallpaper(value) — Wallpaper save
· _toggleStarMessage(docId, isStarred) — Star toggle
· _toggleMute() — Chat mute toggle
· _showGroupMessageOptions(...) — Group message options
· _editGroupMessage(...) — Edit group message
· _deleteGroupMessage(...) — Delete group message

Code Conventions

· Snake_case for file names
· PascalCase for classes
· camelCase for variables and functions
· Private functions start with _

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
· ☑ Filter Chips with Counts
· ☑ Hisaab Kitaab (Khata Book)
· ☑ PDF Export + WhatsApp Send
· ☑ Bottom nav: Chats, Updates, Calls, Profile
· ☑ Profile stats: Contacts, Hisaab, Blocked
· ☑ Functional Settings
· ☑ Chat List Search
· ☑ Reply to Status
· ☑ Delete Status
· ☑ Viewed by List
· ☑ Link Preview (YouTube/Instagram)
· ☑ Clickable Links
· ☑ Group Reply
· ☑ Group Edit/Delete
· ☑ Message Star
· ☑ Chat Mute
· ☑ Message Forwarding
· ☑ Chat Wallpaper
· ☑ Group Notifications
· ☑ Group Unread Count
· ☑ Performance Optimizations

Phase 2 (Next)

· ☐ Voice Message (mic test pending)
· ☐ Group Voice Message
· ☐ Communities Tab
· ☐ Starred Messages Screen
· ☐ Muted Chats Screen
· ☐ Message Info (kisne padha)
· ☐ Message Reaction
· ☐ Message Search
· ☐ Chat Statistics

Phase 3 (Future)

· ☐ Voice/Video Calling (WebRTC + TURN)
· ☐ End-to-End Encryption
· ☐ Two-Factor Auth
· ☐ Screenshot Notification
· ☐ Status Forward
· ☐ Reply Preview Tap

---

🎯 Important Notes for New Developers

1. Firebase Storage hata diya — sab Base64 use kar rahe hain
2. Voice Message — flutter_sound use, Codec.aacMP4
3. Firestore 1 MB limit — chhoti files hi Base64 mein
4. Firestore Indexes — group_messages, status, khate, hisab pe composite index
5. OneSignal REST API Key — GitHub Secret mein
6. GitHub Actions — har push pe APK automatically build
7. ChatScreen — chat_screen.dart mein hai
8. Hisaab Kitaab — khate + hisab collections
9. PROJECT_INFO.md — sensitive info hide ki hui hai
10. Link Preview — linkify package hata diya, manual regex use
11. Group Notification — background mein, parallel
12. Performance — debounce + cache + parallel queries

```

---

## ✅ Ab ye karo:

1. **`PROJECT_INFO.md`** file kholo GitHub pe
2. **Pencil icon (✏️)** dabao
3. **Poori nayi content paste karo** upar wali
4. **Commit changes** dabao

---

## 🎯 Kya-kya update hua?

| Section | Kya Naya |
|---------|----------|
| **Core Features** | Message Star, Forward, Wallpaper, Mute, Group Reply, Group Edit/Delete, Group Notification, Group Unread Count, Link Preview, Clickable Links, Filter Chips Counts |
| **Performance** | Debounce, Cache, Parallel Queries, Background Notifications |
| **Firestore Structure** | Naye sub-collections (wallpapers, muted_chats, muted_groups), naye fields (isStarred, linkUrl, linkTitle, etc.) |
| **Known Issues** | 33 fixes documented |
| **Important Functions** | 15+ naye functions add kiye |
| **Roadmap** | Saare naye features completed mark kiye |
| **Developer Notes** | 12 important notes |

---
