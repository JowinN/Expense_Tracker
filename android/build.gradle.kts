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
    
    val configureAction = Action<Project> {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val compileMethod = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                compileMethod.invoke(androidExt, 35)
            } catch (e: Exception) {
                try {
                    val compileMethod = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    compileMethod.invoke(androidExt, 35)
                } catch (ex: Exception) {}
            }
            try {
                val getDefaultConfig = androidExt.javaClass.getMethod("getDefaultConfig")
                val defaultConfig = getDefaultConfig.invoke(androidExt)
                if (defaultConfig != null) {
                    val setTarget = defaultConfig.javaClass.getMethod("setTargetSdkVersion", Int::class.javaPrimitiveType)
                    setTarget.invoke(defaultConfig, 35)
                }
            } catch (e: Exception) {
                try {
                    val getDefaultConfig = androidExt.javaClass.getMethod("getDefaultConfig")
                    val defaultConfig = getDefaultConfig.invoke(androidExt)
                    if (defaultConfig != null) {
                        val setTarget = defaultConfig.javaClass.getMethod("targetSdkVersion", Int::class.javaPrimitiveType)
                        setTarget.invoke(defaultConfig, 35)
                    }
                } catch (ex: Exception) {}
            }
        }
    }
    
    if (state.executed) {
        configureAction.execute(this)
    } else {
        afterEvaluate(configureAction)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
