allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// ============================================================
// 智能修复脚本：解决 "Namespace not specified" 问题
// ============================================================
subprojects {
    // 定义一个动作：尝试给旧插件补上 namespace
    val fixNamespace = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val currentNamespace = getNamespace.invoke(android)
                // 如果没有 namespace，就用 group ID 补上
                if (currentNamespace == null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, group.toString())
                }
            } catch (e: Exception) {
                // 忽略异常，防止卡住构建
            }
        }
    }

    // 关键判断：避免 "already evaluated" 错误
    if (state.executed) {
        fixNamespace()
    } else {
        afterEvaluate {
            fixNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}