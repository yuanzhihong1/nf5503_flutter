# Adapter classes are instantiated through Class.forName so they can stay
# unloaded on ordinary Android devices that do not include the vendor SDK.
-keep class com.m5stack.nf5503_flutter.AndroidScannerApi { *; }
-keep class com.m5stack.nf5503_flutter.AndroidPrinterApi { *; }
