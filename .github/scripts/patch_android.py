"""
Patch the generated android/ directory for Lumin India.

Handles both Kotlin DSL (.kts) and Groovy (.gradle) Gradle formats.
Run after `flutter create` has generated the android/ platform directory.

Patches applied:
  - google-services plugin wired at project + app level
  - applicationId fixed to com.luminapp.india (matches Firebase registration)
  - minSdk set to 26 (Android API 26+, per CLAUDE.md)
  - Release signing config wired if android/key.properties exists
  - INTERNET permission added to AndroidManifest.xml
"""

import os
import re
import sys

APP_ID = "com.luminapp.india"
MIN_SDK = 26


def patch_kts():
    proj = "android/build.gradle.kts"
    content = open(proj).read()
    if "com.google.gms.google-services" not in content:
        content = content.rstrip() + (
            "\n\nplugins {\n"
            '    id("com.google.gms.google-services") version "4.4.2" apply false\n'
            "}\n"
        )
        open(proj, "w").write(content)
        print(f"patched {proj}: google-services plugin declaration")

    app = "android/app/build.gradle.kts"
    content = open(app).read()

    if "com.google.gms.google-services" not in content:
        content = re.sub(
            r"(plugins\s*\{)",
            r'\1\n    id("com.google.gms.google-services")',
            content,
            count=1,
        )
        print(f"patched {app}: applied google-services plugin")

    content = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", f"minSdk = {MIN_SDK}", content)
    content = re.sub(r'applicationId\s*=\s*"[^"]*"', f'applicationId = "{APP_ID}"', content)

    # Release signing — only wired when key.properties exists (CI with keystore secret)
    if os.path.exists("android/key.properties") and "signingConfigs" not in content:
        signing_block = """
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = java.util.Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
    }
"""
        signing_config = """
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
"""
        release_signing = '            signingConfig = signingConfigs.getByName("release")'

        # Insert Properties read before android { block
        content = re.sub(r"(android\s*\{)", signing_block + r"\1", content, count=1)
        # Insert signingConfigs block inside android { before buildTypes
        content = re.sub(r"(buildTypes\s*\{)", signing_config + r"\1", content, count=1)
        # Wire release signing inside the release buildType
        content = re.sub(
            r"(release\s*\{[^}]*)",
            r"\1\n" + release_signing + "\n",
            content,
            count=1,
        )
        print(f"patched {app}: release signing config wired from key.properties")

    open(app, "w").write(content)
    print(f"patched {app}: minSdk={MIN_SDK}, applicationId={APP_ID}")


def patch_groovy():
    proj = "android/build.gradle"
    content = open(proj).read()
    if "com.google.gms:google-services" not in content:
        content = content.replace(
            "buildscript {",
            "buildscript {\n"
            "    dependencies {\n"
            '        classpath "com.google.gms:google-services:4.4.2"\n'
            "    }",
            1,
        )
        open(proj, "w").write(content)
        print(f"patched {proj}: google-services classpath")

    app = "android/app/build.gradle"
    content = open(app).read()

    if "apply plugin: 'com.google.gms.google-services'" not in content:
        content = content.replace(
            "apply plugin: 'com.android.application'",
            "apply plugin: 'com.android.application'\n"
            "apply plugin: 'com.google.gms.google-services'",
            1,
        )
        print(f"patched {app}: google-services plugin applied")

    content = re.sub(r"minSdk\s*=?\s*flutter\.minSdkVersion", f"minSdk = {MIN_SDK}", content)
    content = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", f"minSdkVersion {MIN_SDK}", content)
    content = re.sub(r'applicationId\s+"[^"]*"', f'applicationId "{APP_ID}"', content)

    if os.path.exists("android/key.properties") and "signingConfigs" not in content:
        signing = """
    signingConfigs {
        release {
            def props = new Properties()
            file("../key.properties").withInputStream { props.load(it) }
            keyAlias props['keyAlias']
            keyPassword props['keyPassword']
            storeFile file(props['storeFile'])
            storePassword props['storePassword']
        }
    }
"""
        content = re.sub(r"(buildTypes\s*\{)", signing + r"\1", content, count=1)
        content = re.sub(
            r"(release\s*\{[^}]*)",
            r"\1\n            signingConfig signingConfigs.release\n",
            content,
            count=1,
        )
        print(f"patched {app}: release signing config wired from key.properties")

    open(app, "w").write(content)
    print(f"patched {app}: minSdk={MIN_SDK}, applicationId={APP_ID}")


def patch_manifest():
    m = "android/app/src/main/AndroidManifest.xml"
    content = open(m).read()
    if "android.permission.INTERNET" not in content:
        content = content.replace(
            "<application",
            '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
            1,
        )
        open(m, "w").write(content)
        print("manifest: added INTERNET permission")


if __name__ == "__main__":
    kts = os.path.exists("android/build.gradle.kts")
    print(f"Gradle format: {'Kotlin DSL (.kts)' if kts else 'Groovy (.gradle)'}")
    if kts:
        patch_kts()
    else:
        patch_groovy()
    patch_manifest()
    print("Android patch complete")
