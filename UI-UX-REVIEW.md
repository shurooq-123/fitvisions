# UI/UX and navigation review evidence

## Implemented behavior
- Signed-in account name is provided by the common AppShell header across routes. It reads the profile first/last name, falls back to Firebase displayName, and is not translated as interface text. Long names wrap to two lines; a tooltip and semantic label expose the complete name.
- Common page back buttons have an accessible Back label, directional positioning, and safe maybePop behavior. The first/root screen remains visible when no previous route exists. Forms keep their original route when returning from a pushed page.
- Admin bottom navigation keeps the dashboard beneath Users and System; Back returns to the dashboard. Selecting the current tab does not push duplicates.
- Shared pages constrain form width, reduce horizontal padding on narrow screens and allow vertical scrolling. Size controls use wrapping layouts. Primary shared buttons have minimum 48 logical-pixel height.
- English/Arabic and right-to-left presentation, light/dark appearance and system text scaling remain supported.

## Automated evidence
`test/navigation_accessibility_test.dart`: admin Users -> System -> Back -> dashboard; safe root Back; long profile name at 180 logical-pixel width with 2x text scaling and full semantic label.

`test/prototype_layout_test.dart`: representative screens at 360x640, 360x800, 320x640 with 1.35x text, landscape 568x320, dark theme and Arabic. Checks Flutter layout exceptions, not a claim that every device or screen-reader interaction has been physically tested.

`test/app_shell_test.dart`: header tooltip Overlay, navigation and route preservation across appearance changes.

## Manual demonstration after installation
1. Sign in and show the registered name; visit Profile, History and Notifications.
2. Navigate between admin tabs, then press Back.
3. Rotate the phone, enlarge system text and scroll forms to their final controls.
4. Switch language and theme, then confirm entered form data and navigation remain usable.

Phone installation and physical verification were deferred at the user's request. Welcome/root screens have no preceding application screen to return to; Back must not remove their only route.

## 21 November navigation update
- Authenticated shared header now contains a fixed Back button outside page scrolling.
- Successful user/admin login clears authentication routes from the back stack.
- Home/dashboard PopScope blocks system swipe/back from leaving the root. The explicit fixed Back button closes the Android activity when there is no prior route; it does not sign out. Logout remains the account sign-out action.
- Header remains conditional on Firebase authentication. Fixed scrolling and root-back tests pass with the full 217-test suite.
