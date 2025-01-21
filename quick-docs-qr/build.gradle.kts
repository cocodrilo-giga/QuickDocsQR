buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.4")
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
