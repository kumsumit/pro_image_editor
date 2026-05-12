import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "ch.waio.pro_image_editor"
version = "1.0-SNAPSHOT"

repositories {
        google()
        mavenCentral()
    }


android {
    namespace = "ch.waio.pro_image_editor"

    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    sourceSets {
        getByName("main") {
            java.setSrcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.setSrcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests.all {
            useJUnitPlatform()

            testLogging {
               events("passed", "skipped", "failed", "standardOut", "standardError")
               outputs.upToDateWhen {false}
               showStandardStreams = true
            }
        }
    }
}

kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_21)
        }
    }

dependencies {
        testImplementation("org.jetbrains.kotlin:kotlin-test")
        testImplementation("org.mockito:mockito-core:5.23.0")
    }