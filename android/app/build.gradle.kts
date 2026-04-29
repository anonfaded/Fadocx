plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Versioning (manual control) ──
val appVersionCode = 2
val appVersionName = "0.0.0"

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

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    flavorDimensions += "environment"

    productFlavors {
        create("beta") {
            dimension = "environment"
            applicationIdSuffix = ".beta"
            manifestPlaceholders["appName"] = "Fadocx Beta"
            versionName = "${appVersionName}-beta"
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
                "META-INF/services/*",
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
    implementation("org.apache.poi:poi-ooxml:5.2.3")
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
