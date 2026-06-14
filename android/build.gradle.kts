allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureProject: () -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val namespace = getNamespace.invoke(android)
                if (namespace == null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    val cleanProjectName = project.name.replace(Regex("[^a-zA-Z0-9_]"), "_")
                    setNamespace.invoke(android, "com.example.$cleanProjectName")
                }
            } catch (e: Exception) {
                // Ignore any exceptions
            }
        }

        // Align Java and Kotlin targets to 17
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
        tasks.configureEach {
            if (name.contains("compile", ignoreCase = true) && name.contains("Kotlin", ignoreCase = true)) {
                try {
                    val kotlinOptions = property("kotlinOptions")
                    if (kotlinOptions != null) {
                        val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                        setJvmTarget.invoke(kotlinOptions, "17")
                    }
                } catch (e: Exception) {
                    // Ignore any exceptions
                }
            }
        }
    }
    if (state.executed) {
        configureProject()
    } else {
        afterEvaluate {
            configureProject()
        }
    }
}
