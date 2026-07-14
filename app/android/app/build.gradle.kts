plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // FCM: google-services.json 을 읽어 Firebase 를 앱에 연결한다.
    id("com.google.gms.google-services")
}

android {
    namespace = "org.madcamp.memory_pager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications 가 요구하는 코어 라이브러리 디슈가링.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.madcamp.memory_pager"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // firebase_core 3.x 는 minSdk 23 이상을 요구한다(flutter 기본값이 더 높으면 그걸 쓴다).
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // R8 코드 축소를 끈다. 켜져 있으면 keep 규칙 없이 WorkManager 의 Room 구현
            // 클래스(WorkDatabase_Impl 등)를 제거해, 실기기에서 앱 시작 시
            // "Failed to create an instance of androidx.work.impl.WorkDatabase" 로 즉사한다.
            // 이 앱은 minify 가 필요 없고(크기 여유), 이게 실기기 부팅 크래시의 근본 원인이었다.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // flutter_local_notifications 18.x 요구(>= 2.1.4).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
