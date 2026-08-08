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
