android {
    namespace = "com.example.fitvisions"

    compileSdk = 35

    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.fitvisions"

        minSdk = 21

        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}