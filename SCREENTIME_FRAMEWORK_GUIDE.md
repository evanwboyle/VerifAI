# Screen Time & Family Controls Framework Implementation Guide

## Executive Summary

This document provides a comprehensive overview of Apple's Screen Time APIs and how to build a screen time restriction app similar to Opal. The framework consists of three interconnected components: **FamilyControls**, **ManagedSettings**, and **DeviceActivity**. Together, these enable developers to create parental control and digital wellness applications that can selectively block apps and websites based on custom schedules and rules.

---

## 1. High-Level Architecture Overview

### How Opal Works (Reference Implementation)

Opal Screen Time is a market-leading app that demonstrates several key approaches:

1. **Modern Approach (iOS 16+)**: Uses Apple's `ManagedSettings` framework to enforce restrictions locally on the device
2. **Privacy-First Design**: All processing happens locally on the device; no data is sent to remote servers
3. **Session-Based Blocking**: Users can set timed "Focus Sessions" with varying restriction levels
4. **Deep Focus Mode**: Provides maximum protection—users cannot cancel timers
5. **Previously Used VPN Layer**: Earlier versions used VPN to intercept app connections, but now leverages native APIs

### Three-Framework Collaboration Model

```
┌─────────────────────────────────────────┐
│      User Interface (SwiftUI)            │
│    - Settings & Configuration            │
│    - Activity Selection UI               │
└─────────────────────────────────────────┘
           ▼
┌─────────────────────────────────────────┐
│   FamilyControls Framework               │
│   - Request Authorization                │
│   - Select Apps/Categories/Websites      │
└─────────────────────────────────────────┘
           ▼
┌─────────────────────────────────────────┐
│   ManagedSettings Framework              │
│   - Define Restriction Rules             │
│   - Store Shield Settings                │
└─────────────────────────────────────────┘
           ▼
┌─────────────────────────────────────────┐
│   DeviceActivity Framework               │
│   - Schedule When Rules Apply            │
│   - Monitor Intervals                    │
└─────────────────────────────────────────┘
           ▼
┌─────────────────────────────────────────┐
│   DeviceActivityMonitor Extension        │
│   - Enforce Rules (System Level)         │
│   - Send Notifications/Warnings          │
└─────────────────────────────────────────┘
```

---

## 2. Framework Deep Dive

### 2.1 FamilyControls Framework

**Purpose**: Authorization and activity selection. This framework provides the permission layer and UI for users to select which apps, categories, and websites to manage.

#### Key Components

**AuthorizationCenter**
- Singleton class that manages permission requests
- Must be used to request authorization before using other frameworks
- Two authorization patterns available:

```swift
// Modern approach (async/await)
try await AuthorizationCenter.shared.requestAuthorization(for: .individual)

// Legacy approach (completion handler)
AuthorizationCenter.shared.requestAuthorization { result in
    switch result {
    case .success:
        // Authorization granted
    case .failure(let error):
        // Handle error
    }
}
```

**Authorization Status**
- `.notDetermined`: First-time request
- `.denied`: User declined
- `.approved`: User approved

**FamilyActivityPicker**
- SwiftUI view modifier that presents an activity selection interface
- Users select apps, categories (Social Media, Games, etc.), and web domains
- Does not reveal user selections to the app itself—selections are opaque tokens
- Implemented via `.familyActivityPicker(isPresented:selection:)` modifier

**FamilyActivitySelection**
- Stores user-selected apps, categories, and websites
- Contains:
  - `apps`: Set of selected application tokens
  - `categories`: Set of selected category tokens
  - `webDomains`: Set of selected web domain tokens

**ActivityCategoryToken**
- Opaque token representing a category (cannot be created directly; only obtained via FamilyActivityPicker)
- Used to reference categories when creating restrictions

#### Implementation Pattern

```swift
@State private var selection = FamilyActivitySelection()
@State private var showPicker = false

// Request authorization first
Task {
    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
}

// In your UI:
Button("Select Apps to Block") {
    showPicker = true
}
.familyActivityPicker(
    isPresented: $showPicker,
    selection: $selection
)
```

---

### 2.2 ManagedSettings Framework

**Purpose**: Define and enforce the actual restriction rules. This framework specifies what apps/websites to shield and under what conditions.

#### Key Components

**ManagedSettingsStore**
- Primary configuration object for restrictions
- Can be instantiated with a name: `ManagedSettingsStore(named: "scheduleA")`
- Up to 50 unique stores can be instantiated per app
- Settings persist across app launches and sync between host app and extensions

**Shield Properties**
- `store.shield.applications`: Specific apps to block
- `store.shield.applicationCategories`: Categories of apps to block (Games, Social Media, etc.)
- `store.shield.webDomainCategories`: Categories of websites to block

**ActivityCategoryPolicy**
- Defines which items are blocked and which are allowed
- Used with both app and web domain categories
- Can be set to block everything: `ActivityCategoryPolicy(blockedCategories: .all())`
- Or block with exceptions: `ActivityCategoryPolicy(blockedCategories: [gameToken], allowedCategories: [beneficialAppsToken])`

**Configuration Example**
```swift
let store = ManagedSettingsStore(named: "workFocus")

// Block specific apps
store.shield.applications = Set([appToken1, appToken2])

// Block categories with exceptions
store.shield.applicationCategories = ActivityCategoryPolicy(
    blockedCategories: [socialMediaToken],
    allowedCategories: [messengersToken]
)

// Block web domains
store.shield.webDomainCategories = ActivityCategoryPolicy(
    blockedCategories: .all()
)
```

**Shielding Customization**
- Can customize shield appearance with company branding
- Shield shown when user tries to launch blocked app/website
- Supports custom buttons and messaging

#### Limitations

- Cannot restrict ALL apps on the device
- Can only shield specific apps or entire app categories
- The system always allows certain system apps (Phone, Emergency, etc.)

---

### 2.3 DeviceActivity Framework

**Purpose**: Define when restrictions should be active. This framework handles scheduling and time-based monitoring.

#### Key Components

**DeviceActivityCenter**
- Singleton class responsible for starting/stopping monitoring
- Called from the main app (not the extension)
- Registers which schedules and restrictions should be enforced

**DeviceActivityName**
- Identifier for a specific schedule/restriction pair
- Referenced in both the app and the extension
- Example: `let activityName = DeviceActivityName("focusTime")`

**DeviceActivitySchedule**
- Defines the time intervals when restrictions are active
- Components:
  - `intervalStart`: DateComponents for when the interval begins
  - `intervalEnd`: DateComponents for when the interval ends
  - `repeats`: Boolean for recurring schedules (daily, weekly, etc.)
  - `warningTime`: Optional DateComponents for pre-end warning

**Common Schedule Examples**
```swift
// All day (midnight to 11:59 PM)
let allDaySchedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
    intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
    repeats: true
)

// Business hours (9 AM to 5 PM)
let workSchedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 9, minute: 0),
    intervalEnd: DateComponents(hour: 17, minute: 0),
    repeats: true
)

// With warning 15 minutes before end
let warningSchedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 18, minute: 0),
    intervalEnd: DateComponents(hour: 22, minute: 0),
    repeats: true,
    warningTime: DateComponents(minute: -15)
)
```

**Starting Monitoring**
```swift
let center = DeviceActivityCenter()

try await center.startMonitoring(
    .focusTime,
    during: workSchedule
)
```

#### Important Constraints

- Minimum interval duration: 15 minutes (enforced for testing purposes)
- Maximum schedules: 20 active schedules per app
- Warning time must be sufficient (typically 5-60 minutes before end)
- Requires `com.apple.developer.family-controls` entitlement

---

### 2.4 DeviceActivityMonitor Extension

**Purpose**: Runs at the system level to enforce restrictions and monitor intervals. This is a separate target that receives lifecycle events.

#### How to Create

1. In Xcode: File → New → Target
2. Select "Device Activity Monitor Extension"
3. Configure the extension target with necessary entitlements

#### Core Callback Methods

**Interval Lifecycle**
- `intervalDidStart(for activity:)`: Called when restriction period begins
- `intervalDidEnd(for activity:)`: Called when restriction period ends
- `intervalWillStartWarning(for activity:)`: Called at warningTime before end

**Threshold Events** (if monitoring app usage)
- `eventWillReachThresholdWarning(_:activity:)`: App/category approaching usage limit
- `eventDidReachThreshold(_:activity:)`: Usage limit reached

**Example Extension Implementation**
```swift
import DeviceActivity

class DeviceActivityMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Restrictions are now active
        print("Interval started: \(activity.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Restrictions no longer active
        print("Interval ended: \(activity.rawValue)")
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Show user warning before end
        print("Warning: interval ending soon for \(activity.rawValue)")
    }
}
```

#### Memory Constraints

- Hard memory limit: 5 MB
- System will force-terminate extension if memory exceeded (Jetsam crash)
- Keep event handlers lightweight; avoid complex processing

---

## 3. Data Flow & Synchronization

### App Group Requirement

**Critical**: Both the main app and extensions must use an App Group to share data.

```
Main App                          Extension
     ↓                                ↓
ManagedSettingsStore ←→ (App Group) ←→ ManagedSettingsStore
(same named store)                    (same named store)
```

**Configuration**
```swift
// In Signing & Capabilities
// Add: App Groups
// ID: group.com.yourcompany.appblocker
```

**Why This Matters**
- Without App Group, restrictions set in the app won't be visible to the extension
- Settings must be persisted and shared for enforcement to work
- Same store instance can be accessed from both app and extension targets

### Settings Persistence Flow

1. User selects apps/categories in main app UI
2. `FamilyActivitySelection` captured via picker
3. Main app creates `ManagedSettingsStore` and configures `shield` properties
4. Store persists to shared App Group container
5. Extension reads from same App Group container
6. System enforces restrictions when schedule is active

---

## 4. Implementation Roadmap for VerifAI

### Phase 1: Core Setup
1. **Add Entitlements**
   - Add `com.apple.developer.family-controls` to main app
   - Configure App Groups in Signing & Capabilities
   - Request entitlement from Apple via developer portal

2. **Request Authorization**
   - Create AuthorizationManager to handle AuthorizationCenter requests
   - Add UI flow for first-time authorization request
   - Handle .individual or .child authorization types

3. **Create Settings Model**
   - Design data model for saving restriction schedules
   - Use SwiftData (existing in VerifAI) to persist schedules
   - Store serialized schedule configurations

### Phase 2: Activity Selection & Configuration
1. **Implement FamilyActivityPicker**
   - Add view modifier to display activity picker
   - Store `FamilyActivitySelection` in SwiftData
   - Create UI to manage multiple activity selections

2. **Create Schedule Builder**
   - UI to define `DeviceActivitySchedule` (start, end, repeat)
   - Support for time-of-day selection
   - Warning time configuration

3. **Set Up ManagedSettingsStore**
   - Create stores for each schedule
   - Configure `shield.applications` and `shield.applicationCategories`
   - Handle store naming and lifecycle

### Phase 3: Monitoring & Enforcement
1. **Create Device Activity Monitor Extension**
   - New target in Xcode project
   - Implement callback methods
   - Send local notifications

2. **Activate Schedules**
   - Use `DeviceActivityCenter.startMonitoring()` from main app
   - Handle schedule updates
   - Implement pause/resume functionality

3. **Add Event Handling**
   - Process `intervalDidStart`, `intervalDidEnd` events
   - Update UI based on enforcement status
   - Display active restrictions to user

### Phase 4: User Experience Enhancements
1. **Shield Customization**
   - Add custom messaging when apps are blocked
   - Create branded shield screen
   - Add unlock mechanisms (if authorized)

2. **Analytics & Reporting**
   - Track when restrictions are active
   - Log interval start/end events
   - Display usage statistics

3. **Advanced Features**
   - Multiple concurrent schedules
   - Category-based blocking
   - Exception handling (emergency contacts, etc.)

---

## 5. Entitlement & Apple Approval

### Required Entitlements

**Development**
```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

**App Groups** (in Signing & Capabilities)
- Identifier: `group.com.verifai.screentime`

### Approval Requirements

- **Family Controls is a privileged entitlement**: Must request from Apple
- Submit request via developer.apple.com with:
  - Use case description (parental controls, digital wellness, etc.)
  - Business rationale
  - Privacy policy
- Approval required before TestFlight/App Store submission
- No sandbox testing possible; must use physical device

### Important Notes

- Cannot test with free developer account
- Requires a registered Apple Developer Program membership
- Rejection possible if use case deemed inappropriate
- Apple has been selective with approvals; provide clear justification

---

## 6. Key Limitations & Constraints

### System Limitations

| Constraint | Impact |
|-----------|--------|
| Max 20 active schedules | Don't exceed this limit; raises `MonitoringError.excessiveActivities` |
| Max 50 ManagedSettingsStores | Create stores strategically; consider consolidation |
| 15-minute minimum interval | Testing requires >= 15 min schedules |
| 5 MB extension memory limit | Keep extension lightweight; avoid heavy processing |
| Cannot block all apps | System apps always accessible |
| App tokens are opaque | Cannot persist FamilyActivitySelection across app launches directly |

### API Limitations

- No direct app usage tracking (requires separate DeviceActivity events)
- No notification delivery to user about blocked apps (via DeviceActivityMonitor)
- Limited shield customization options
- Cannot distinguish between user-initiated block and system block

---

## 7. Code Example: Minimal Working Implementation

### 1. Request Authorization
```swift
import FamilyControls

@MainActor
class AuthorizationManager: ObservableObject {
    @Published var isAuthorized = false

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(
                for: .individual
            )
            isAuthorized = true
        } catch {
            print("Authorization failed: \(error)")
        }
    }
}
```

### 2. Select Activities
```swift
import SwiftUI
import FamilyControls

struct ActivitySelectionView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false

    var body: some View {
        VStack {
            Button("Select Apps to Block") {
                showPicker = true
            }
            .familyActivityPicker(
                isPresented: $showPicker,
                selection: $selection
            )

            Text("Selection saved")
        }
    }
}
```

### 3. Configure Store
```swift
import ManagedSettings

func configureRestrictions(selection: FamilyActivitySelection) {
    let store = ManagedSettingsStore(named: "defaultRestrictions")
    store.shield.applications = selection.apps
    store.shield.applicationCategories = ActivityCategoryPolicy(
        blockedCategories: selection.categories
    )
}
```

### 4. Start Monitoring
```swift
import DeviceActivity

func startFocusSession() async {
    let center = DeviceActivityCenter()
    let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 9, minute: 0),
        intervalEnd: DateComponents(hour: 17, minute: 0),
        repeats: true
    )

    do {
        try await center.startMonitoring(.focusTime, during: schedule)
    } catch {
        print("Failed to start monitoring: \(error)")
    }
}
```

### 5. Extension Handler
```swift
import DeviceActivity

class DeviceActivityMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("Focus session started")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("Focus session ended")
    }
}
```

---

## 8. Comparison: Opal vs. Native Screen Time vs. VerifAI Implementation

| Feature | Native Screen Time | Opal | Proposed VerifAI |
|---------|-------------------|------|-----------------|
| App blocking | ✓ | ✓ | ✓ |
| Website blocking | ✓ | ✓ | ✓ |
| Custom schedules | ✓ | ✓ | ✓ |
| Custom UI | ✗ | ✓ | ✓ |
| Deep Focus (no bypass) | ✗ | ✓ | Possible |
| Multiple users | Parent/child | Individual | Individual |
| Privacy-first | ✓ | ✓ | ✓ |
| VPN-based | ✗ | Older versions | No (use native APIs) |
| AI features | ✗ | ✓ | Possible via OpenAI |

---

## 9. Testing Strategy

### Physical Device Testing
- Must use real device (simulator doesn't support Family Controls)
- Use iPhone/iPad or Mac
- Requires > 15 minutes per test cycle (minimum interval)

### Test Cases
1. **Authorization Flow**: Request → User acceptance → Confirmation
2. **Activity Selection**: Open picker → Select apps/categories → Verify storage
3. **Schedule Creation**: Create schedule → Verify ManagedSettingsStore → Confirm persistence
4. **Monitoring**: Start monitoring → Wait for interval → Check restrictions active
5. **Interval End**: Monitor end of interval → Verify restrictions lifted
6. **Event Handlers**: Verify extension callbacks fire at correct times

### Debugging
- Use Console app to view extension logs
- Check DeviceActivityMonitor extension output
- Verify ManagedSettingsStore values in app group container
- Test authorization status via `AuthorizationCenter.shared.authorizationStatus`

---

## 10. Privacy & Security Considerations

### Privacy First
- All restriction data stored locally on device
- No cloud synchronization required
- User retains full control over selections
- Opal and similar apps demonstrate this model works

### Security Notes
- Family Controls requires explicit authorization
- Authorization cannot be revoked without settings reset
- Activity selections are opaque tokens (cannot be read by app)
- Extension runs in isolated sandbox (5 MB memory limit)

### User Experience
- Authorization prompt appears once
- Users see shield screen when blocked (can be customized)
- No hidden restrictions; UI clearly shows active sessions
- Transparency builds user trust

---

## 11. Resources & References

### Official Apple Documentation
- [FamilyControls Documentation](https://developer.apple.com/documentation/familycontrols)
- [ManagedSettings Documentation](https://developer.apple.com/documentation/managedsettings)
- [DeviceActivity Documentation](https://developer.apple.com/documentation/deviceactivity)
- [WWDC 2022: What's new in Screen Time API](https://developer.apple.com/videos/play/wwdc2022/110336/)

### Third-Party References
- A Developer's Guide to Apple's Screen Time APIs (Medium)
- ScreenBreak project (GitHub - example implementation)
- Opal blog: Building Opal's Screen Time Framework
- Various Stack Overflow discussions on Screen Time API

### Community
- Apple Developer Forums: Family Controls tag
- Stack Overflow: screen-time tag
- GitHub: Open-source implementations for reference

---

## 12. Next Steps for VerifAI

1. **Apply for Entitlement**: Submit `com.apple.developer.family-controls` request to Apple
2. **Create Extension Target**: Add DeviceActivityMonitor extension to Xcode project
3. **Design Data Model**: Define SwiftData models for schedules and restrictions
4. **Prototype UI**: Build authorization and activity selection flows
5. **Test Authorization**: Verify FamilyControls authorization works on device
6. **Implement ManagedSettingsStore**: Create store configuration logic
7. **Build Monitoring**: Implement DeviceActivityCenter monitoring
8. **Extend Extension**: Complete DeviceActivityMonitor callbacks
9. **End-to-End Testing**: Verify full flow from selection to enforcement
10. **Refine UX**: Add custom shields, notifications, and advanced features

---

## Conclusion

Apple's Screen Time frameworks provide a powerful, privacy-respecting foundation for building screen time restriction apps. By understanding how FamilyControls, ManagedSettings, and DeviceActivity work together, you can build a VerifAI feature that matches or exceeds the capabilities of market leaders like Opal. The key is careful planning around entitlements, proper use of App Groups for data sharing, and thorough testing on physical devices.
