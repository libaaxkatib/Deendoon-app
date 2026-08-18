# com.google.crypto.tink:tink-android (pulled in transitively via
# androidx.security:security-crypto, itself a transitive dependency of the
# flutter_secure_storage plugin) references these two annotation packages
# in its bytecode, but only as compileOnly dependencies of its own POM —
# error_prone_annotations and jsr305 are never present on the runtime
# classpath and never invoked at runtime.
#
# Neither dependency in this chain ships R8 guidance for this on its own:
# tink-android is published as a plain JAR (verified in the local Gradle
# cache), which cannot carry a consumer-rules.pro at all; and
# androidx.security:security-crypto:1.1.0-alpha06's AAR was extracted and
# confirmed to ship with no consumer-rules.pro of its own either. Without
# this file, R8 fails the release build with "Missing classes detected"
# for every class matched below.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# Mobile QA Fix — Login Session Persistence. Same root cause as the
# missing-classes warnings above (androidx.security:security-crypto and
# its transitive tink-android dependency ship no consumer-rules.pro), but
# this is a correctness gap, not just a noisy build warning: Tink's AEAD
# primitives are registered and looked up by class name at runtime
# (`com.google.crypto.tink.aead.AeadConfig.register()`), and
# EncryptedSharedPreferences (what flutter_secure_storage's Android
# implementation is actually backed by) is itself constructed through
# Tink's key-management classes. Without explicit `-keep` rules, R8's
# release-only minification is free to rename/strip those classes since
# nothing in the bytecode holds a static reference to them — the reflective
# lookup then fails silently at runtime and the encrypted read/write
# no-ops, which is indistinguishable from "no session was ever saved" on
# every cold start of a release build specifically (debug builds are never
# minified, so this never reproduces there, and no automated test exercises
# the real Android Keystore either).
-keep class com.google.crypto.tink.** { *; }
-keep interface com.google.crypto.tink.** { *; }
-keepclassmembers class com.google.crypto.tink.** { *; }
-keep class androidx.security.crypto.** { *; }

# The blanket keep above pulls in com.google.crypto.tink.util.KeysDownloader
# too — part of Tink's optional remote key-fetch (JWK/JWT-over-HTTP) code
# path, never invoked by this app (only local EncryptedSharedPreferences is
# used, never a remote KMS). It references com.google.api.client.http.** and
# org.joda.time.Instant, neither of which is a dependency of this project,
# so R8 fails the build with "Missing classes detected" without this —
# same class of issue, and same fix, as the error_prone_annotations/jsr305
# rule above: the referencing code exists in the kept class but is never
# actually called at runtime.
-dontwarn com.google.api.client.http.**
-dontwarn org.joda.time.**
