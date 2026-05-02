import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// On-device clinical risk predictor powered by a TensorFlow Lite model.
///
/// The model is a small Keras dense neural network trained on 95,756 real
/// clinical records (Cardiovascular Disease Dataset, Pima Indians Diabetes
/// Dataset, Stroke Prediction Dataset).  It accepts an 18-feature vector
/// and outputs a risk level: GREEN | YELLOW | ORANGE | RED.
///
/// Feature vector layout (18 values):
///   [0-11]  Symptom scores q1-q12 (0–3 each; activity questions inverted)
///   [12]    Systolic BP deviation from 120 mmHg
///   [13]    Diastolic BP deviation from 80 mmHg
///   [14]    Glucose deviation from 100 mg/dL
///   [15]    Medication adherence (1.0 = took medication, 0.0 = did not)
///   [16]    Condition code  (0=Hypertension, 1=Diabetes, 2=Cardiovascular)
///   [17]    Age normalised  ((age_years − 25) / 60, clamped 0–1; default 0.33 ≈ 45 yrs)
///
/// Label mapping:  0=GREEN  1=YELLOW  2=ORANGE  3=RED
class RiskPredictor {
  static Interpreter? _interpreter;
  static bool _initialized = false;

  static const List<String> _labels = ['GREEN', 'YELLOW', 'ORANGE', 'RED'];

  /// Loads the TFLite model from the app's asset bundle.
  /// Call once (e.g. from a screen's [initState]); safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/ml_models/risk_model.tflite',
        options: InterpreterOptions()..threads = 1,
      );
      _initialized = true;
      debugPrint('RiskPredictor: TFLite model loaded successfully.');
    } catch (e) {
      debugPrint('RiskPredictor: Failed to load TFLite model — $e');
    }
  }

  /// Predicts the risk level for a patient given their 18-feature vector.
  ///
  /// Returns one of: `'GREEN'`, `'YELLOW'`, `'ORANGE'`, `'RED'`.
  /// Falls back to a simple rule-based estimate if the model is not ready.
  static String predict(List<double> features) {
    assert(features.length == 18,
        'Feature vector must have 18 elements, got ${features.length}');

    if (_interpreter == null) {
      debugPrint('RiskPredictor: Model not ready — using rule-based fallback.');
      return _ruleBased(features);
    }

    try {
      // Input tensor:  shape [1, 18] (float32)
      // Output tensor: shape [1, 4]  (float32 — softmax probabilities)
      final input = [features.map((v) => v.toDouble()).toList()];
      final output = [List.filled(4, 0.0)];

      _interpreter!.run(input, output);

      final probs = output[0];
      int maxIdx = 0;
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > probs[maxIdx]) maxIdx = i;
      }
      debugPrint(
          'RiskPredictor: probs=$probs → ${_labels[maxIdx]}');
      return _labels[maxIdx];
    } catch (e) {
      debugPrint('RiskPredictor: Inference error — $e');
      return _ruleBased(features);
    }
  }

  /// Lightweight rule-based fallback (mirrors the original Flutter logic).
  /// Sums q1-q12 symptom scores (already inverted where needed) and thresholds.
  static String _ruleBased(List<double> features) {
    final score = features.sublist(0, 12).fold<double>(0, (a, b) => a + b);
    if (score < 6) return 'GREEN';
    if (score < 13) return 'YELLOW';
    if (score < 20) return 'ORANGE';
    return 'RED';
  }

  /// Releases the interpreter. Call when the predictor is no longer needed.
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }
}
