package com.deendoon.mobile

import io.flutter.embedding.android.FlutterFragmentActivity

// Mobile Fix #17: local_auth_android 1.0.56 (LocalAuthPlugin.authenticate())
// requires the host Activity to be a FragmentActivity — verified from the
// installed plugin source, not assumed from documentation. Plain
// FlutterActivity does not extend FragmentActivity, which silently made
// every real-device biometric prompt fail before this change.
class MainActivity : FlutterFragmentActivity()
