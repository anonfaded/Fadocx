plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Aspose repository for Slides, Words, Cells
repositories {
    maven {
        url = uri("https://repository.aspose.com/repo/")
    }
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
        freeCompilerArgs = listOf("-Xlint:-options")
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fadseclab.fadocx"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26  // Required for Apache POI and log4j compatibility
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
        }
        create("prod") {
            dimension = "environment"
            manifestPlaceholders["appName"] = "Fadocx"
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
                "META-INF/LICENSE-notice.md"
            )
        }
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
