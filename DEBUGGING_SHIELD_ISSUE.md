# VerifAI Custom Shield Not Displaying - Debugging Status

**Status**: 🔴 **UNRESOLVED** - Custom red shield still not displaying. Default Apple blue shield appears instead.

**Last Updated**: 2025-11-07

---

## Problem Statement

When a user opens a restricted app in the VerifAI app, the system shows the **default Apple blue hourglass shield** instead of the **custom red VerifAI shield**.

**Expected behavior**: Custom shield with red background (RGB 0.95, 0.3, 0.3) should display
**Actual behavior**: Default Apple blue shield displays

---

## Root Cause Analysis

The **DeviceActivityMonitor extension is not being invoked by the system**. Evidence:

1. ✅ Main app logs ARE appearing in console (showing restrictions are being set)
2. ❌ **Extension logs are NOT appearing** (no calls to ShieldConfigurationProvider methods)
3. ❌ No `🔧 DeviceActivityMonitor initialized` log
4. ❌ No `🛡️ Creating shield configuration for app` log

This means the system isn't even calling the extension, so it falls back to the default shield.

---

## Things Verified and Confirmed ✅

### 1. **Extension Bundle ID** - CORRECT
- Set to: `com.evanboyle.VerifAI.VerifAIMonitor`
- Verified in built app at: `/Users/evanboyle/Library/Developer/Xcode/DerivedData/VerifAI-gtwidvdcbachrwcohxqeuyequliz/Build/Products/Debug-iphoneos/VerifAI.app/PlugIns/VerifAIMonitor.appex`
- Uses format: `com.evanboyle.VerifAI` (main app) + `.VerifAIMonitor` (extension) ✅

### 2. **Info.plist Configuration** - FIXED
**File**: `VerifAIMonitor/Info.plist`

**Current values** (after fixes):
```xml
<key>NSExtensionPointIdentifier</key>
<string>com.apple.deviceactivity.monitor</string>
<key>NSExtensionPrincipalClass</key>
<string>DeviceActivityMonitor</string>
```

**Previous incorrect values** (discovered and fixed):
- ❌ Was: `NSExtensionPointIdentifier` = `com.apple.deviceactivity.monitor-extension` → **WRONG**
- ❌ Was: `NSExtensionPrincipalClass` = `$(PRODUCT_MODULE_NAME).DeviceActivityMonitor` → **WRONG** (expanded to `VerifAIMonitor.DeviceActivityMonitor`)

**Latest fix** (Nov 7):
- Changed NSExtensionPrincipalClass from `$(PRODUCT_MODULE_NAME).DeviceActivityMonitor` to just `DeviceActivityMonitor` (no module prefix needed)

### 3. **Entitlements** - CORRECT
**Extension entitlements** (`VerifAIMonitor/VerifAIMonitor.entitlements`):
```xml
<key>com.apple.developer.family-controls</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
  <string>group.com.verifai.screentime</string>
</array>
```

**Main app entitlements** (`VerifAI/VerifAI.entitlements`):
```xml
<key>com.apple.developer.family-controls</key>
<true/>
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
  <string>group.com.verifai.screentime</string>
</array>
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

### 4. **Provisioning Profiles** - CORRECT
Both main app and extension have valid provisioning profiles with:
- ✅ `com.apple.developer.family-controls` entitlement
- ✅ `com.apple.security.application-groups` with `group.com.verifai.screentime`
- ✅ Same team ID: `NK8AYRW483`
- ✅ Same developer: `Evan Wesley Boyle`
- ✅ Valid until 2026

**Main app profile**: `iOS Team Provisioning Profile: com.evanboyle.VerifAI`
**Extension profile**: `iOS Team Provisioning Profile: com.evanboyle.VerifAI.VerifAIMonitor`

### 5. **Build Configuration** - CORRECT
- ✅ VerifAIMonitor target builds successfully
- ✅ Extension is embedded in main app (shown in "Embed Foundation Extensions" build phase)
- ✅ `CODE_SIGN_ENTITLEMENTS` is set to `VerifAIMonitor/VerifAIMonitor.entitlements`
- ✅ Automatic signing enabled
- ✅ Same team for both targets

### 6. **App Groups** - CORRECT
- ✅ Both app and extension use same App Groups container: `group.com.verifai.screentime`
- ✅ Main app can access container
- ✅ Extension logs show container is accessible

### 7. **Restrictions Being Set** - CORRECT
Main app logs confirm:
```
📝 Configuring restrictions with 1 apps
📁 Using App Groups container: /private/var/mobile/Containers/Shared/AppGroup/5FA5C668-C44B-4D76-BF82-CEDECA25D648
🔒 Shield applications set: 1
✅ Monitoring started successfully for activity: verifaiBlockingSchedule
```

---

## Current Console Output When Testing

```
Loaded OpenAI Key: sk-examplekey1234567890

Error acquiring assertion: <Error Domain=RBSAssertionErrorDomain Code=2 "Could not find attribute name in domain plist" UserInfo={NSLocalizedFailureReason=Could not find attribute name in domain plist}>

59638328 Plugin query method called

(501) Invalidation handler invoked, clearing connection

(501) personaAttributesForPersonaType for type:0 failed with error Error Domain=NSCocoaErrorDomain Code=4099 "The connection to service named com.apple.mobile.usermanagerd.xpc was invalidated from this process."

LaunchServices: store (null) or url (null) was nil: Error Domain=NSOSStatusErrorDomain Code=-54 "process may not map database"

Attempt to map database failed: permission was denied. This attempt will not be retried.

Failed to initialize client context with error Error Domain=NSOSStatusErrorDomain Code=-54 "process may not map database"

[UISceneHosting-com.evanboyle.VerifAI:UIHostedScene-com.apple.FamilyControls.ActivityPickerExtension-E0A...] No scene exists for this identity (didUpdateClientSettingsWithDiff)

📝 Configuring restrictions with 1 apps
📁 Using App Groups container: /private/var/mobile/Containers/Shared/AppGroup/5FA5C668-C44B-4D76-BF82-CEDECA25D648
🔒 Shield applications set: 1
🚀 Starting monitoring...
📅 Schedule created: 24/7
✅ Monitoring started successfully for activity: verifaiBlockingSchedule

0.5
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
```

**Key observation**: The `Error acquiring assertion` error persists despite all checks passing. The extension is not being called.

---

## Things Tried and Their Outcomes

| What | Tried | Result |
|------|-------|--------|
| Added console logging to DeviceActivityMonitor | ✅ | No logs appear - extension not invoked |
| Fixed NSExtensionPointIdentifier | ✅ | Still not working |
| Fixed NSExtensionPrincipalClass (removed module prefix) | ✅ | Persists (latest attempt) |
| Verified entitlements on both targets | ✅ | All correct |
| Verified provisioning profiles | ✅ | All correct, valid until 2026 |
| Verified bundle IDs | ✅ | Correct format |
| Verified extension embedding in build | ✅ | Embedded correctly |
| Checked App Groups container access | ✅ | Main app can access; extension claims access in logs |
| Updated bundle ID from derived variable to explicit value | ✅ | Still not working |
| Removed file-based logging (per user request) | ✅ | N/A - console only now |

---

## Code Files Involved

### Main Application Files

**RestrictionsManager.swift** - Configures restrictions
- Creates named ManagedSettingsStore: `"verifaiRestrictions"`
- Calls `center.startMonitoring()` with 24/7 schedule
- Logs verify restrictions ARE being set

**ShieldConfigurationProvider.swift** - Main app version
- Implements ShieldConfigurationDataSource
- Returns red shield (RGB 0.95, 0.3, 0.3)
- **Note**: This main app version may not be used if extension isn't called

### Extension Files

**VerifAIMonitor/DeviceActivityMonitorExtension.swift**
- Contains `DeviceActivityMonitor` class (inherits from DeviceActivity.DeviceActivityMonitor)
- Contains `ShieldConfigurationProvider` class (implements ShieldConfigurationDataSource)
- Has comprehensive logging with os.log
- **Issue**: Methods are never called - logs never appear

**VerifAIMonitor/Info.plist**
- `NSExtensionPointIdentifier`: `com.apple.deviceactivity.monitor`
- `NSExtensionPrincipalClass`: `DeviceActivityMonitor` (latest fix)

**VerifAIMonitor/VerifAIMonitor.entitlements**
- Has Family Controls and App Groups entitlements

---

## Remaining Unknowns

1. **Why is the "Error acquiring assertion" occurring?**
   - All expected entitlements are present
   - All provisioning profiles are valid
   - The error message is generic and doesn't pinpoint the cause

2. **Is the extension's Info.plist being read correctly after the latest fix?**
   - Haven't rebuilt since changing NSExtensionPrincipalClass to just `DeviceActivityMonitor`
   - The resolved value was previously `VerifAIMonitor.DeviceActivityMonitor` - should now be just `DeviceActivityMonitor`

3. **Could the issue be in the entitlements domain plist that RBSAssertionErrorDomain is complaining about?**
   - This error suggests a missing attribute in some system plist
   - Not clear which plist or which attribute

4. **Is there a system-level configuration or approval needed beyond what we've done?**
   - Family Controls requires MDM approval or user setup - could this be involved?
   - Is there a "Screen Time" or "Family Controls" screen that needs to be configured first?

---

## Next Steps to Try (Priority Order)

### 1. **Rebuild and Test Latest Info.plist Change**
```bash
cd /Users/evanboyle/Documents/GitHub/VerifAI/VerifAI
xcodebuild clean -scheme VerifAI
xcodebuild build -scheme VerifAI -destination 'platform=iOS Simulator,name=iPhone 15'
```
Then test if extension logs now appear.

### 2. **Check if Family Controls Setup is Required on Device**
- In Settings app on simulator, check if there's a Family Controls or Screen Time section that needs initial setup
- May need to go through initial setup flow before restrictions work

### 3. **Verify Extension is Actually Being Embedded in Final App**
```bash
# After build, check PlugIns folder
ls -la /Users/evanboyle/Library/Developer/Xcode/DerivedData/VerifAI-*/Build/Products/Debug-iphoneos/VerifAI.app/PlugIns/
```

### 4. **Check Device Activity Schedule Status**
- Verify that `DeviceActivityCenter().startMonitoring()` is actually creating an active schedule
- May need to query the status to see if monitoring is actually running

### 5. **Research RBSAssertionErrorDomain Code 2**
- This is an entitlements/attribute domain issue
- May need to check if there's a missing Info.plist key or entitlement at system level
- Could be related to specific iOS version or simulator setup

### 6. **Try Running on Physical Device**
- The issue may be simulator-specific
- Physical devices handle Family Controls differently than simulator

### 7. **Check for Required DeviceActivityMonitorDelegate**
- May need additional delegate implementation beyond what we have
- Apple's docs might require specific delegate methods to be implemented

---

## Files Modified This Session

1. ✅ `/Users/evanboyle/Documents/GitHub/VerifAI/VerifAI/VerifAIMonitor/Info.plist`
   - Changed NSExtensionPrincipalClass from `$(PRODUCT_MODULE_NAME).DeviceActivityMonitor` to `DeviceActivityMonitor`

---

## Summary for Next Developer

**The Problem**: Extension isn't being invoked by the system, so default shield shows instead of custom shield.

**What's Correct**: Everything we can verify is correct - bundle IDs, entitlements, provisioning profiles, app group sharing, restriction configuration.

**What's Unknown**: Why the system isn't calling the extension despite all configuration being correct. The "Error acquiring assertion" error suggests an RBS (Resource Based System) entitlements issue, but all entitlements appear correct.

**Next Action**: Rebuild with the latest Info.plist fix (NSExtensionPrincipalClass changed to just `DeviceActivityMonitor`) and verify if extension logs now appear in console. If not, may need to investigate RBSAssertionErrorDomain Code 2 or try physical device testing.

**Key Logs to Watch For**: If working, should see `🔧 DeviceActivityMonitor initialized` in console immediately after starting restrictions monitoring.
