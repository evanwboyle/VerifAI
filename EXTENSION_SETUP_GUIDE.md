# DeviceActivityMonitor Extension Setup

## What to Put in DeviceActivityMonitor.swift

After creating the extension target, find `DeviceActivityMonitor.swift` in the extension folder and replace its contents with:

```swift
//
//  DeviceActivityMonitor.swift
//  VerifAIMonitor
//
//  Created by Evan Boyle on 11/7/25.
//

import DeviceActivity
import Foundation

class DeviceActivityMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("[VerifAI Monitor] Restriction interval started: \(activity.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("[VerifAI Monitor] Restriction interval ended: \(activity.rawValue)")
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        print("[VerifAI Monitor] Warning: Interval ending soon: \(activity.rawValue)")
    }
}
```

## App Groups Configuration

**CRITICAL**: Your extension and main app must share an App Group:

### For the Main App (VerifAI target):
1. Select **VerifAI** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Enter: `group.com.verifai.screentime`

### For the Extension (VerifAIMonitor target):
1. Select **VerifAIMonitor** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Enter: `group.com.verifai.screentime` (SAME as main app)

## Family Controls Entitlement

Both targets need the Family Controls entitlement:

### For VerifAI target:
- Already configured in `VerifAI.entitlements`

### For VerifAIMonitor target:
1. Right-click the extension folder → **New File**
2. Create a new file named `VerifAIMonitor.entitlements`
3. Paste this content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.family-controls</key>
    <true/>
</dict>
</plist>
```

4. In Xcode, select the extension target
5. Go to **Build Settings**
6. Search for "Code Sign Entitlements"
7. Set it to `VerifAIMonitor/VerifAIMonitor.entitlements`

## Info.plist Configuration

Make sure the extension's Info.plist has:

```xml
<key>NSExtensionPointIdentifier</key>
<string>com.apple.deviceactivity.monitor</string>
```

(This should be auto-configured if you used the template)

## Build & Test

1. Select **VerifAIMonitor** scheme in Xcode
2. Build it (Cmd+B)
3. Switch back to **VerifAI** scheme
4. Run the app
5. Go to **RestrictView**
6. Select apps with "Choose Apps, Categories & Websites"
7. Tap "Start Restricting"
8. Try opening a restricted app — you should see the system shield screen!

## Troubleshooting

- **Extension not loading**: Verify App Groups match between main app and extension
- **Shield not showing**: Check Family Controls entitlement is provisioned on both targets
- **Build errors**: Ensure extension target is in **Build Phases** of main app
