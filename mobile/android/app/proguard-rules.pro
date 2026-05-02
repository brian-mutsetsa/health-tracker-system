# TFLite GPU delegate — class only present on devices with GPU support.
# Suppress R8 warning about the optional GPU delegate factory options class.
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Keep all TFLite classes so R8 doesn't strip them
-keep class org.tensorflow.** { *; }
