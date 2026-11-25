# 🚨 DisasterMesh - Complete Codebase & Viva Explanation Guide

Intha file ah VS Code la direct ah open panni read/present pannu bro!

---

## 📁 1. VS Code Project Folder Structure Overview

```text
lib/
 ├── main.dart                  --> App Entry Point (App initialize aagi start aagum lugar)
 ├── models/                    --> Data Structures (Data format defining classes)
 │    ├── user_model.dart       --> User profile details (ID, Name, Blood Group, Emergency Contact)
 │    ├── sos_model.dart        --> SOS Emergency Alert details (Lat/Lng, Urgency, Hops, Battery)
 │    ├── message_model.dart    --> Chat/Text message structure
 │    └── device_model.dart     --> Nearby P2P Mesh node details
 ├── services/                  --> Core Logic & Backend Engines
 │    ├── communication_service.dart --> 🌟 Main Mesh Networking (Google Nearby Connections)
 │    ├── sos_service.dart       --> SOS trigger, Broadcast & Handlers
 │    ├── storage_service.dart   --> Offline SQLite Database (`sqflite`) storage
 │    ├── location_service.dart  --> Device GPS Location fetcher (`geolocator`)
 │    ├── speech_service.dart    --> Voice Emergency speech-to-text logic
 │    ├── priority_service.dart  --> Urgency level priority calculation
 │    └── classification_service.dart --> AI/Rule-based emergency categorization
 ├── screens/                   --> UI Pages (User Display Screens)
 │    ├── splash_screen.dart     --> Initial loading screen
 │    ├── registration_screen.dart --> User registration & local profile saving
 │    ├── home_screen.dart       --> Main Dashboard & SOS Action Center
 │    ├── create_sos_screen.dart --> Manual SOS Form Screen
 │    ├── voice_emergency_screen.dart --> Mic voice-based emergency trigger
 │    ├── nearby_devices_screen.dart --> Live Mesh nodes & active connections list
 │    ├── rescue_dashboard_screen.dart --> Rescuers/Volunteers SOS tracking view
 │    ├── sos_details_screen.dart --> Individual SOS detail page
 │    └── map_screen.dart        --> GPS Map visualization of SOS alerts
 └── widgets/                   --> Reusable UI Components (SOS Cards, Custom Buttons)
```

---

## 🧠 2. Core Code Explanation (Step-by-Step for Presentation)

### Step A: App Startup ([`lib/main.dart`](file:///d:/Design%20thinking/lib/main.dart))
- `WidgetsFlutterBinding.ensureInitialized()`: Flutter Engine and Native Plugins (Bluetooth/GPS) binding ready pannum.
- `MaterialApp`: App wide Dark Theme, Roboto Font set panni, initial screen ah Web illana Android/iOS ah nu check panni `SplashScreen` or `LandingPage` launch pannum.

---

### Step B: Models & Serialization ([`lib/models/`](file:///d:/Design%20thinking/lib/models/))
Take [`user_model.dart`](file:///d:/Design%20thinking/lib/models/user_model.dart) as example:
* **Properties**: `id`, `name`, `bloodGroup`, `emergencyContact`, `registeredAt`.
* **`toMap()`**: Dart Object ah `Map<String, dynamic>` (JSON/Database format) ah convert pannum. SQLite Database la save panna ithu zaroor.
* **`fromMap()`**: Database or Mesh Network raw JSON Data va marubadiyum Dart `UserModel` Object ah parse/convert pannum.

---

### Step C: The Heart - Mesh Communication ([`lib/services/communication_service.dart`](file:///d:/Design%20thinking/lib/services/communication_service.dart))
Examiners intha file ah thaan kandippa kepanga!
1. **Advertising & Discovery**:
   - `startAdvertising()`: Phone ah discoverable mode la podum (Other devices identify panna).
   - `startDiscovery()`: Surrounding la irukura other DisasterMesh devices ah search/scan pannum.
2. **P2P Mesh Connection**:
   - `requestConnection()` & `acceptConnection()`: Bluetooth / Wi-Fi Direct handshake establishing connection without Internet.
3. **Relay & Multi-hop Logic**:
   - When device receives an SOS payload via `onPayloadReceived()`, app checks the `sosId`.
   - If `sosId` is new (not in SQLite DB), it increments `hopCount + 1` and automatically re-broadcasts (`relaySOS()`) to all connected nearby nodes!
   - This allows an SOS alert to travel miles across multiple phones until it reaches a Rescue Team node.

---

### Step D: Offline Database ([`lib/services/storage_service.dart`](file:///d:/Design%20thinking/lib/services/storage_service.dart))
- Uses `sqflite` (SQLite plugin).
- Network illatha time la create aagura SOS alerts, User profiles, & Incoming messages DB tables (`sos_table`, `messages_table`) la secure ah save aagum.
- Connection kedaikumpodhu instant sync / broadcast aagum.

---

### Step E: Voice Emergency & AI Classification
- **`speech_service.dart`**: Microphone access vachu user speech ah text ah parse pannum.
- **`classification_service.dart`**: Speech text la *"Flood"*, *"Injured"*, *"Trapped"*, *"Bleeding"* edhavadhu keywords irukaa nu check panni Priority Level (`CRITICAL`, `HIGH`, `MEDIUM`) assign pannum.

---

## ❓ 3. Viva Question & Answer Cheat Sheet

| Question | Short & Sharp Answer |
| :--- | :--- |
| **Q1: What is the main uniqueness of this app?** | It enables communication & SOS emergency relay completely **OFFLINE** using Bluetooth/Wi-Fi P2P Mesh networking during cellular tower failures. |
| **Q2: Which package handles device-to-device connection?** | `nearby_connections` (Google Nearby API for Android/iOS P2P). |
| **Q3: How do you prevent infinite looping of the same SOS message?** | Every SOS has a unique UUID and local SQLite check. Duplicate SOS IDs are discarded immediately. |
| **Q4: How does offline data persistence work?** | We use `sqflite` SQLite DB with `toMap()` and `fromMap()` serialization. |

---
*Generated for DisasterMesh Project Presentation in VS Code.*
