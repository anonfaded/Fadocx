plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

// ── Versioning (manual control) ──
val appVersionCode = 3
val appVersionName = "1.0.0"

// ── Release keystore signing ──
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fadseclab.fadocx"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    defaultConfig {
        applicationId = "com.fadseclab.fadocx"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26  // Required for Apache POI and log4j compatibility
        targetSdk = flutter.targetSdkVersion
        versionCode = appVersionCode
        versionName = appVersionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // R8 minification enabled with selective keep rules for POI/XMLBeans/logging
            // Critical classes (POI, XMLBeans, logging, JNI) are kept unobfuscated
            // Everything else (Flutter, app code, unused deps) is aggressively minified
            isMinifyEnabled = true
            isShrinkResources = true
            // Use only our custom ProGuard rules (not the default Android ones)
            proguardFiles("proguard-rules.pro")
        }
    }

    flavorDimensions += "environment"

    productFlavors {
        create("beta") {
            dimension = "environment"
            applicationIdSuffix = ".beta"
            manifestPlaceholders["appName"] = "Fadocx Beta"
            versionName = "${appVersionName}-beta1" // Increment the suffix for each beta release (e.g., -beta2, -beta3, etc.)
        }
        create("prod") {
            dimension = "environment"
            manifestPlaceholders["appName"] = "Fadocx"
            versionName = appVersionName
        }
    }

    // Exclude duplicate META-INF files from transitive dependencies
    packaging {
        resources {
            merges += listOf("META-INF/LICENSE.md", "META-INF/NOTICE.md", "META-INF/LICENSE-notice.md")
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/INDEX.LIST",
                "META-INF/*.md",
                "META-INF/LICENSE-notice.md",
                "org/bouncycastle/pqc/**"
            )
        }
    }

    aaptOptions {
        noCompress += listOf(
            "rdb", "rc", "xcu", "xcs", "xcl", "xcsa", "xcul", "xcd",
            "xslt", "xml", "py", "ttf", "otf", "ttc",
            "dat", "res", "zip", "jar", "class", "txt",
            "conf", "cfg", "svg", "css", "ui", "dtd",
            "sor", "sample", "lm", "mod", ""
        )
    }
}

dependencies {
    // Apache POI for native document parsing (XLSX, XLS, CSV, DOC)
    implementation("org.apache.poi:poi:5.2.3")
    implementation("org.apache.poi:poi-ooxml:5.2.3") {
        exclude(group = "org.apache.poi", module = "poi-ooxml-lite")
    }
    implementation("org.apache.poi:poi-ooxml-full:5.2.3")
    implementation("org.apache.poi:poi-scratchpad:5.2.3")

    // PDFBox for PDF text extraction
    implementation("com.tom-roush:pdfbox-android:2.0.27.0")

    // Required transitive dependencies
    implementation("org.apache.xmlbeans:xmlbeans:5.1.1")
    implementation("commons-io:commons-io:2.11.0")
    implementation("commons-codec:commons-codec:1.15")
    implementation("commons-logging:commons-logging:1.2")
}

flutter {
    source = "../.."
}
