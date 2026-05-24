import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.tasks.testing.Test

plugins {
    id("com.android.library")
}

group = "ch.waio.pro_image_editor"
version = "1.0-SNAPSHOT"

repositories {
        google()
        mavenCentral()
    }


extensions.configure<LibraryExtension>("android") {
    namespace = "ch.waio.pro_image_editor"

    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    sourceSets {
        getByName("main") {
            kotlin.directories.add("src/main/kotlin")
        }
        getByName("test") {
            kotlin.directories.add("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }
}

tasks.withType<Test>().configureEach {
    useJUnitPlatform()

    testLogging {
       events("passed", "skipped", "failed", "standardOut", "standardError")
       showStandardStreams = true
    }
    outputs.upToDateWhen { false }
}


dependencies {
        testImplementation("org.jetbrains.kotlin:kotlin-test")
        testImplementation("org.mockito:mockito-core:5.23.0")
    }
