import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
// Pepper Clinical — On-Device AI Service
// Google ML Kit (Face + Pose) + TFLite (Emotion)
// 100% offline — no data leaves the device

import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';

/// Complete AI analysis result for one camera frame
class FrameResult {
  // Attention
  final double attention;        // 0–100
  final String attentionLabel;   // low | medium | high | excellent

  // Emotion
  final String emotion;          // happy | sad | angry | fear | surprised | neutral
  final String emotionAr;        // Arabic emotion name
  final double emotionConf;      // 0–1
  final bool smiling;

  // Face
  final bool faceDetected;
  final bool eyeContact;
  final bool mouthOpen;

  // Pose
  final bool poseDetected;
  final double headX;
  final double headY;
  final double headTilt;

  // Hands (from pose)
  final bool handRaised;
  final bool touchingHead;

  // Processing
  final double fps;
  final double ms;

  const FrameResult({
    this.attention = 0,
    this.attentionLabel = 'low',
    this.emotion = 'neutral',
    this.emotionAr = 'محايد',
    this.emotionConf = 0.5,
    this.smiling = false,
    this.faceDetected = false,
    this.eyeContact = false,
    this.mouthOpen = false,
    this.poseDetected = false,
    this.headX = 0.5,
    this.headY = 0.3,
    this.headTilt = 0,
    this.handRaised = false,
    this.touchingHead = false,
    this.fps = 0,
    this.ms = 0,
  });

  static const empty = FrameResult();
}

class AIService {
  static final AIService instance = AIService._();
  AIService._();

  // ML Kit detectors
  FaceDetector? _faceDetector;
  PoseDetector? _poseDetector;

  // TFLite emotion model
  Interpreter? _emotionInterp;
  bool _initialized = false;

  // FPS tracking
  final List<DateTime> _fpsBuffer = [];

  static const _emotions    = ['angry','fear','happy','sad','surprised','neutral','joyful'];
  static const _emotionsAr  = ['غاضب','خائف','سعيد','حزين','مندهش','محايد','مبتهج'];

  Future<void> init() async {
    if (_initialized) return;
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,   // smile, eyes open
          enableLandmarks: true,        // eye/nose/mouth positions
          enableTracking: true,         // track face across frames
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.10,
        ),
      );

      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base,  // fast lightweight model
        ),
      );

      // Load TFLite emotion model
      try {
        _emotionInterp = await Interpreter.fromAsset(
          'assets/models/emotion_model.tflite',
          options: InterpreterOptions()..threads = 2,
        );
      } catch (e) {
        debugPrint('Emotion model not found (optional): $e');
      }

      _initialized = true;
      debugPrint('✅ AI Service initialized');
    } catch (e) {
      debugPrint('AI init error: $e');
    }
  }

  Future<FrameResult> analyzeFrame(CameraImage image, int rotation) async {
    if (!_initialized) await init();

    final sw = Stopwatch()..start();
    double attention = 0;
    String emotion   = 'neutral';
    String emotionAr = 'محايد';
    double emotionConf = 0.5;
    bool faceOk    = false;
    bool eyeContact= false;
    bool mouthOpen = false;
    bool smiling   = false;
    bool poseOk    = false;
    double headX   = 0.5, headY = 0.3, headTilt = 0;
    bool handRaised= false;
    bool touching  = false;

    try {
      final inputImage = _buildInputImage(image, rotation);

      // ── Face Detection ──────────────────────────────────────
      if (_faceDetector != null) {
        final faces = await _faceDetector!.processImage(inputImage);
        if (faces.isNotEmpty) {
          final face = faces.first;
          faceOk = true;

          // Eye contact: head Y rotation near 0 (looking forward)
          final yaw   = face.headEulerAngleY ?? 0;
          final pitch = face.headEulerAngleX ?? 0;
          eyeContact  = yaw.abs() < 15 && pitch.abs() < 15;

          // Smile
          final smileProb = face.smilingProbability ?? 0;
          smiling = smileProb > 0.65;

          // Eyes open (attention signal)
          final leftEye  = face.leftEyeOpenProbability  ?? 1.0;
          final rightEye = face.rightEyeOpenProbability ?? 1.0;
          final eyesOpen = leftEye > 0.5 && rightEye > 0.5;

          // Head tilt
          headTilt = face.headEulerAngleZ ?? 0;

          // Head position from bounding box
          final box = face.boundingBox;
          headX = (box.left + box.width / 2) / image.width;
          headY = (box.top  + box.height/ 2) / image.height;

          // Mouth open (mouth landmarks)
          final upperLip = face.landmarks[FaceLandmarkType.leftMouth];
          final lowerLip = face.landmarks[FaceLandmarkType.leftMouth];
          if (upperLip != null && lowerLip != null) {
            final lipDist = (lowerLip.position.y - upperLip.position.y).abs();
            mouthOpen = lipDist > face.boundingBox.height * 0.06;
          }

          // Emotion
          if (smiling) {
            emotion   = 'happy';
            emotionAr = 'سعيد';
            emotionConf = smileProb;
          }

          // TFLite emotion (if model available)
          if (_emotionInterp != null) {
            final result = _predictEmotion(image, face.boundingBox);
            if (result != null) {
              emotion   = result.$1;
              emotionAr = result.$2;
              emotionConf = result.$3;
            }
          }

          // Attention from face features
          attention += 35; // face detected
          if (eyeContact) attention += 25;
          if (eyesOpen)   attention += 15;
          if (headTilt.abs() < 15) attention += 10;
          if (smiling || emotion == 'happy' || emotion == 'joyful') attention += 10;
          if (mouthOpen) attention += 5;
        }
      }

      // ── Pose Detection ──────────────────────────────────────
      if (_poseDetector != null) {
        final poses = await _poseDetector!.processImage(inputImage);
        if (poses.isNotEmpty) {
          final pose = poses.first;
          poseOk = true;
          attention += 5;

          final nose = pose.landmarks[PoseLandmarkType.nose];
          if (nose != null) {
            headX = nose.x / image.width;
            headY = nose.y / image.height;
          }

          // Hand raised
          final lWrist = pose.landmarks[PoseLandmarkType.leftWrist];
          final rWrist = pose.landmarks[PoseLandmarkType.rightWrist];
          final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
          if (lWrist != null && lShoulder != null) {
            handRaised = lWrist.y < lShoulder.y;
          }
          if (rWrist != null && lShoulder != null) {
            handRaised = handRaised || (rWrist.y < lShoulder.y);
          }

          // Touch head
          if (nose != null && lWrist != null) {
            final d = math.sqrt(math.pow(lWrist.x - nose.x, 2) +
                                math.pow(lWrist.y - nose.y, 2));
            final faceW = image.width * 0.2;
            touching = d < faceW;
          }
        }
      }
    } catch (e) {
      debugPrint('AI analyze error: $e');
    }

    // FPS
    _fpsBuffer.add(DateTime.now());
    _fpsBuffer.removeWhere(
      (t) => DateTime.now().difference(t) > const Duration(seconds: 1)
    );

    final clampedAttention = attention.clamp(0.0, 100.0);
    final label = clampedAttention >= 80 ? 'excellent'
                : clampedAttention >= 60 ? 'high'
                : clampedAttention >= 40 ? 'medium'
                : 'low';

    return FrameResult(
      attention:      clampedAttention,
      attentionLabel: label,
      emotion:        emotion,
      emotionAr:      emotionAr,
      emotionConf:    emotionConf,
      smiling:        smiling,
      faceDetected:   faceOk,
      eyeContact:     eyeContact,
      mouthOpen:      mouthOpen,
      poseDetected:   poseOk,
      headX:          headX,
      headY:          headY,
      headTilt:       headTilt,
      handRaised:     handRaised,
      touchingHead:   touching,
      fps:            _fpsBuffer.length.toDouble(),
      ms:             sw.elapsedMilliseconds.toDouble(),
    );
  }

  (String, String, double)? _predictEmotion(CameraImage image, dynamic boundingBox) {
    try {
      if (_emotionInterp == null) return null;
      // Extract face region as 48x48 grayscale
      final inputShape  = _emotionInterp!.getInputTensor(0).shape;
      final outputShape = _emotionInterp!.getOutputTensor(0).shape;

      // Simple grayscale input [1, 48, 48, 1]
      final input  = List.generate(1, (_) =>
          List.generate(48, (_) =>
          List.generate(48, (_) => [0.5]))); // placeholder

      final output = List.generate(1, (_) =>
          List.filled(outputShape[1], 0.0));

      _emotionInterp!.run(input, output);

      final scores = output[0];
      int maxIdx = 0;
      double maxScore = 0;
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > maxScore) { maxScore = scores[i]; maxIdx = i; }
      }

      return (_emotions[maxIdx], _emotionsAr[maxIdx], maxScore);
    } catch (e) {
      return null;
    }
  }

  InputImage _buildInputImage(CameraImage image, int rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw)
        ?? InputImageFormat.nv21;

    final bytes = _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(rotation)
            ?? InputImageRotation.rotation0deg,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  Future<void> dispose() async {
    await _faceDetector?.close();
    await _poseDetector?.close();
    _emotionInterp?.close();
    _initialized = false;
  }
}
