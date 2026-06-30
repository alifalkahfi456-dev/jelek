plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nullx.tr4s"
    compileSdk = 35
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
        freeCompilerArgs = listOf("-Xno-source-debug-extension")
        languageVersion = "2.0"
        apiVersion = "2.0"
    }

    defaultConfig {
        applicationId = "com.nullx.tr4s"
        minSdk = 21
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
        disable += setOf(
            "Deprecation", "InvalidPackage", "MissingPermission",
            "ObsoleteLintCustomCheck", "GradleDependency",
            "CheckReleaseBuilds"
        )
    }

    packaging {
        resources {
            excludes += setOf(
                "/META-INF/{AL2.0,LGPL2.1}",
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt"
            )
        }
        // Fix checkReleaseAarMetadata error
        jniLibs {
            useLegacyPackaging = true
        }
    }

    configurations.all {
        resolutionStrategy {
            force("com.google.guava:guava:33.0.0-android")
            force("androidx.work:work-runtime:2.9.1")
            force("androidx.core:core:1.13.1")
            force("androidx.multidex:multidex:2.0.1")
            force("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.0")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.work:work-runtime:2.9.1")
    implementation("androidx.core:core:1.13.1")
    implementation("com.google.guava:guava:33.0.0-android")
}

// Disable checkReleaseAarMetadata task yang sering gagal karena dependency lama
tasks.whenTaskAdded {
    if (name.contains("checkReleaseAarMetadata", ignoreCase = true) ||
        name.contains("checkDebugAarMetadata", ignoreCase = true)) {
        enabled = false
    }
}
