import java.util.Properties
import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // Apply Flutter after Android, which provides built-in Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val environments = listOf("staging", "demo", "production")
val signingProperties = environments.associateWith { environment ->
    Properties().apply {
        val propertiesFile = rootProject.file("signing/$environment/key.properties")
        if (propertiesFile.isFile) {
            propertiesFile.inputStream().use { load(it) }
        }
    }
}

android {
    namespace = "com.midiofa.curvas.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.midiofa.curvas.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        environments.forEach { environment ->
            create(environment) {
                val properties = signingProperties.getValue(environment)
                keyAlias = properties.getProperty("keyAlias")
                keyPassword = properties.getProperty("keyPassword")
                storeFile = properties.getProperty("storeFile")?.let { rootProject.file(it) }
                storePassword = properties.getProperty("storePassword")
            }
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        environments.forEach { environment ->
            create(environment) {
                dimension = "environment"
                applicationIdSuffix = when (environment) {
                    "staging" -> ".stag"
                    "demo" -> ".demo"
                    else -> null
                }
                signingConfig = signingConfigs.getByName(environment)
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
        configureEach {
            if (name == "debug" || name == "profile") {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

// Validate only variants being built, so staging never requires production keys.
androidComponents {
    onVariants(selector().all()) { variant ->
        val environment = variant.productFlavors.single { it.first == "environment" }.second
        val variantName = variant.name.replaceFirstChar { it.uppercaseChar() }
        val expectedPackage = variant.applicationId
        val validateEnvironment = tasks.register("validate${variantName}Environment") {
            group = "verification"
            description = "Checks environment files and signing for ${variant.name}."
            doLast {
                val envFile = rootProject.file("../config/$environment/.env")
                check(envFile.isFile && envFile.length() > 0) {
                    "Missing config/$environment/.env. See docs/android-environments.md."
                }
                val googleServices = file("src/$environment/google-services.json")
                check(googleServices.isFile) {
                    "Missing android/app/src/$environment/google-services.json."
                }
                val json = JsonSlurper().parse(googleServices) as? Map<*, *>
                val clients = json?.get("client") as? List<*> ?: emptyList<Any>()
                val matchesPackage = clients.any { client ->
                    val info = (client as? Map<*, *>)?.get("client_info") as? Map<*, *>
                    val androidInfo = info?.get("android_client_info") as? Map<*, *>
                    androidInfo?.get("package_name") == expectedPackage.get()
                }
                check(matchesPackage) {
                    "Firebase JSON for $environment has no client for ${expectedPackage.get()}. " +
                        "Register this Android app in Firebase and download its official JSON."
                }
                if (variant.buildType == "release") {
                    val properties = signingProperties.getValue(environment)
                    listOf("storeFile", "storePassword", "keyAlias", "keyPassword").forEach { key ->
                        check(!properties.getProperty(key).isNullOrBlank()) {
                            "Missing $key in android/signing/$environment/key.properties."
                        }
                    }
                    check(rootProject.file(properties.getProperty("storeFile")).isFile) {
                        "Keystore for $environment is missing. Check storeFile relative to android/."
                    }
                }
            }
        }
        tasks.matching {
            it.name == "pre${variantName}Build" ||
                it.name == "compileFlutterBuild$variantName" ||
                it.name == "process${variantName}GoogleServices" ||
                it.name == "validateSigning$variantName"
        }.configureEach {
            dependsOn(validateEnvironment)
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
    // WindowCompat.enableEdgeToEdge is available starting with Core 1.17.0.
    implementation("androidx.core:core:1.17.0")
}
