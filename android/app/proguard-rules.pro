# حماية كلاسات WorkManager و Room من التشفير
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class * extends androidx.room.RoomDatabase { *; }