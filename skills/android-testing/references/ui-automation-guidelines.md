# UI Automation Guidelines

Automated testing on Android must prioritize verifying the end-to-end user
experience. Relying solely on background deep links, mock databases, or
broadcast receivers can mask critical UI routing failures, layout shifts, or
permission blockers that a real user would face.

______________________________________________________________________

## 1. Behave Like a Real User Policy

By default, automated tests and AI agents must interact with the application
exactly as a human would.

- **Navigate via the UI**: Launch the app from the launcher or via standard
  intents, and click through the UI flow to reach the target state. Do not
  bypass Out-of-Box Experiences (OOBE) or onboarding carousels unless explicitly
  validating a deeply nested sub-state where OOBE validation is redundant.
- **Respect and Handle System Dialogs**: Android handles runtime permissions
  (Location, Physical Activity, Notifications) via OS-level dialogs.
  - **Guideline**: Tests and agents must be instructed to **proactively click
    and accept all permission prompts** (e.g. selecting "While using the app" or
    "Allow") when they appear in sequence, rather than silently granting them in
    the background via `adb shell pm grant`, unless testing the app's *response*
    to a pre-existing permission state.
- **Dismiss Interstitials and Overlays**: Real-world apps frequently display
  unexpected overlays, such as:
  - Onboarding tips ("Got it" or "Next" banners).
  - Promotional popups (e.g., subscription upgrades or discount overlays).
  - System notification prompts.
  - **Guideline**: Automation flows must be designed to **actively locate, tap
    the close/cancel buttons, and dismiss these overlays** to unblock the main
    user journey.
- **Wait for Transitions and Network States**: Real networks experience latency.
  Avoid assuming instantaneous data availability. Test scripts must implement
  intelligent waits (e.g. waiting for loading spinners to disappear or specific
  elements to render) rather than hardcoded sleeps.

______________________________________________________________________

## 2. Visual Timeline Methodology

State validation must be observable, chronological, and verifiable.

- **Capture Step-by-Step Screenshots**: Configure your UI automation or
  interaction tools to save screenshots at every single step, button tap, and
  transition. This forms an extremely valuable, structured visual timeline for
  developers and QA engineers to audit the exact user journey.
- **Document Progress & Deltas**: When validating features that update over time
  (such as active workout timers, distance counters, or map views), capture
  sequential screenshots at distinct intervals (e.g. at Step 2 and Step 5 of a
  run) to prove the delta (e.g. verifying a timer ticks from `0:30` to `0:51` or
  distance increments from `0.00 km` to `0.20 km`).
- **Dynamic Element Interaction (No Blind Taps)**:
  - Never send blind coordinate taps (e.g., `adb shell input tap 250 800`) if
    the layout is dynamic.
  - Dump the active view hierarchy (`uiautomator dump` or equivalent) to parse
    the layout.
  - Dynamically calculate and coordinate taps based on the bounding boxes of
    semantic elements (IDs, text labels, content descriptions) to ensure tests
    do not flake across different screen densities, aspect ratios, or form
    factors.

______________________________________________________________________

## 3. Device Awake & Unlocked States

To prevent automated tests or AI agents from stalling or failing due to
screen-off timeouts or security lockouts, the target device (both phone and
watch) must be configured in an awake, unlocked, and clean visual state before
initiating any UI automation.

### Keep Screen Awake Indefinitely

Automated tests will fail if the device goes to sleep. Configure the device to
stay awake indefinitely while connected to USB charging:

- **Configure Stay Awake**:
  ```bash
  adb shell settings put global stay_on_while_plugged_in 7
  ```
  *(Note: '7' is the Android constant that keeps the screen awake while charging
  via AC, USB, or Wireless).*

### Wake Up and Dismiss Lock Screen

Before starting any test, ensure the device is awake and the lock screen is
dismissed:

- **Wake Up Screen**:
  ```bash
  adb shell input keyevent KEYCODE_WAKEUP
  ```
- **Dismiss Lock Screen (Keyguard)**:
  ```bash
  adb shell wm dismiss-keyguard
  ```

### Clean System UI (Demo Mode)

When capturing screenshots for a visual timeline, background notifications,
changing clocks, or low battery warnings can cause visual clutter and make
screenshot comparisons fail. Enable **SystemUI Demo Mode** to display a clean,
static status bar:

- **Enable Demo Mode**:
  ```bash
  adb shell settings put global sysui_demo_allowed 1
  ```
- **Configure Clean Status Bar**:
  ```bash
  # Enter demo mode
  adb shell am broadcast -a com.android.systemui.demo --es command enter
  # Set clock to a fixed time (e.g. 10:08)
  adb shell am broadcast -a com.android.systemui.demo --es command clock --es hhmm 1008
  # Force battery to 100% (unplugged)
  adb shell am broadcast -a com.android.systemui.demo --es command battery --es level 100 --es plugged false
  # Hide all notification icons
  adb shell am broadcast -a com.android.systemui.demo --es command notifications --es visible false
  ```
- **Exit Demo Mode (Restore Normal UI)**:
  ```bash
  adb shell am broadcast -a com.android.systemui.demo --es command exit
  ```

______________________________________________________________________

## 4. Companion Sync Verification (Phone & Watch)

When testing paired companion applications (e.g. a phone app paired with a Wear
OS watch companion), verify that the synchronization is robust and real-time.

- **Automatic Wake-up**: Verifying that starting an activity on the phone (e.g.
  starting a route navigation or workout) automatically wakes up the watch,
  launches the watch companion app, and prompts the user for any missing
  permissions in sequence.
- **Lockstep Stat Alignment**: Verify that both screens display identical
  real-time statistics. For example, compare the phone's duration timer with the
  watch's companion timer; they should run in lockstep (with an epoch alignment
  within 1 second of difference), indicating they reference a shared clock.
- **Bidirectional Control Latency**: Tapping controls (like "Pause" or "Resume")
  on the watch must propagate instantly (\<500ms) to the phone,
  freezing/resuming both timers and states in sync, and vice-versa.
- **Layout Adaptations**: Verify that the watch UI dynamically adapts to
  different phone-initiated modes (for example, replacing generic elevation
  stats with remaining trail distance when navigating a preconfigured route).
