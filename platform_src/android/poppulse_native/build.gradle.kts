plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.digitaldiamonds.poppulse"
    compileSdk = 35
    defaultConfig { minSdk = 24 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    // Must match the Godot version of the export templates.
    compileOnly("org.godotengine:godot:4.7.2.stable")
    implementation("androidx.core:core-ktx:1.13.1")
}
