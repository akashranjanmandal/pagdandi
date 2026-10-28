# Release shrinking (R8) rules.

# WorkManager creates its Room database by reflection. Without this the
# release app crashes at start-up with NoSuchMethodException on
# WorkDatabase_Impl.<init>.
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
-keep class * extends androidx.room.RoomDatabase { <init>(); }

# Components Android and the headless core load by name.
-keep class app.pagdandi.pagdandi_native.** { *; }
