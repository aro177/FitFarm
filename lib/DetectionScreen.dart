import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fit_farm/Model/ExerciseDataModel.dart';

import 'main.dart';

class DetectionScreen extends StatefulWidget {
  DetectionScreen({
    Key? key,
    required this.sequence,         // <-- pass a multi-step sequence now
    required this.onEarnCoin,       // same callback you had
  }) : super(key: key);
  final WorkoutSequence sequence;
  final VoidCallback onEarnCoin;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<DetectionScreen> {
  dynamic controller;
  bool isBusy = false;
  late Size size;

  late PoseDetector poseDetector;
  dynamic _scanResults;                 // keep as you had (used by buildResult)
  CameraImage? img;

  int _stepIndex = 0;                   // which step we’re on
  int _currentReps = 0;                 // reps within the current step

  ExerciseStep get _step => widget.sequence.steps[_stepIndex];

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    // Init pose detector
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    poseDetector = PoseDetector(options: options);

    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await controller!.initialize();
    if (!mounted) return;

    controller!.startImageStream((image) {
      if (!isBusy) {
        isBusy = true;
        img = image;
        doPoseEstimationOnFrame();
      }
    });
  }

  /// Called by detectors whenever a rep is confirmed
  void _onRep() {
    if (!mounted) return;
    setState(() => _currentReps++);
    if (_currentReps >= _step.targetReps) {
      _advanceStep();
    }
  }

  Future<void> _advanceStep() async {
    // Reward per completed step (keep your logic)
    widget.onEarnCoin();

    if (_stepIndex + 1 < widget.sequence.steps.length) {
      setState(() {
        _stepIndex++;
        _currentReps = 0;
      });
    } else {
      if (mounted) Navigator.pop(context, true); // finished all steps
    }
  }

  Future<void> doPoseEstimationOnFrame() async {
    final inputImage = _inputImageFromCameraImage(); // your existing helper
    if (inputImage != null) {
      final List<Pose> poses = await poseDetector.processImage(inputImage);
      // debug
      // print("pose=${poses.length}");
      _scanResults = poses;

      if (!mounted) {
        isBusy = false;
        return;
      }

      if (poses.isNotEmpty) {
        // Route ONLY by the current step’s exercise type
        switch (_step.type) {
          case ExerciseType.PushUps:
            detectPushUp(poses.first.landmarks, onRep: _onRep);
            break;
          case ExerciseType.Squat:
            detectSquat(poses.first.landmarks, onRep: _onRep);
            break;
          case ExerciseType.DownwardDogPlank:
            detectPlankToDownwardDog(poses.first, onRep: _onRep);
            break;
          case ExerciseType.JumpingJack:
            detectJumpingJack(poses.first, onRep: _onRep);
            break;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      // keep your overlay up to date
      _scanResults;
      isBusy = false;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    final List<Widget> stackChildren = [];

    if (controller != null) {
      // Camera preview
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: controller!.value.isInitialized
              ? AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: CameraPreview(controller!),
          )
              : const SizedBox.shrink(),
        ),
      );

      // Pose overlay
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: buildResult(),  // your existing overlay
        ),
      );

      // Bottom circular counter: show current reps / target
      stackChildren.add(
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: _step.color,
            ),
            width: 90,
            height: 90,
            child: Center(
              child: Text(
                '$_currentReps / ${_step.targetReps}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );

      // Top banner: show workout name + current step info
      stackChildren.add(
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _step.color,
            ),
            width: MediaQuery.of(context).size.width,
            height: 80,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Left: workout + step title
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.sequence.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            _step.title.isNotEmpty ? _step.title : _step.type.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right: optional image + step index
                  Row(
                    children: [
                      if (_step.image.isNotEmpty)
                        Image.asset('assets/${_step.image}', height: 48),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Step ${_stepIndex + 1} / ${widget.sequence.steps.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(children: stackChildren),
      ),
    );
  }

  bool isLowered = false;
  void detectPushUp(Map<PoseLandmarkType, PoseLandmark> landmarks, {
    required VoidCallback onRep,
  }) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftWrist == null ||
        rightWrist == null ||
        leftHip == null ||
        rightHip == null) {
      return; // Skip if any landmark is missing
    }

    // Calculate elbow angles
    double leftElbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightElbowAngle = calculateAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );
    double avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Calculate torso alignment (ensuring a straight plank)
    double torsoAngle = calculateAngle(
      leftShoulder,
      leftHip,
      leftKnee ?? rightKnee!,
    );
    bool inPlankPosition =
        torsoAngle > 160 && torsoAngle < 180; // Slight flexibility

    if (avgElbowAngle < 90 && inPlankPosition) {
      // User is in the lowered push-up position
      isLowered = true;
    } else if (avgElbowAngle > 160 && isLowered && inPlankPosition) {
      // User returns to the starting position
      onRep();
      isLowered = false;

    }
  }

  bool isSquatting = false;
  void detectSquat(Map<PoseLandmarkType, PoseLandmark> landmarks, {
    required VoidCallback onRep,
  }) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftShoulder == null ||
        rightShoulder == null) {
      return; // Skip detection if any key landmark is missing
    }

    // Calculate angles
    double leftKneeAngle = calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    double hipY = (leftHip.y + rightHip.y) / 2;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;

    bool deepSquat = avgKneeAngle < 90; // Ensuring squat is deep enough

    if (deepSquat && hipY > kneeY) {
      if (!isSquatting) {
        isSquatting = true;
      }
    } else if (!deepSquat && isSquatting) {
      onRep();
      isSquatting = false;
    }
  }

  bool isInDownwardDog = false;
  void detectPlankToDownwardDog(Pose pose, {
    required VoidCallback onRep,
  }) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftHip == null ||
        rightHip == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftWrist == null ||
        rightWrist == null) {
      return; // Skip detection if any key landmark is missing
    }

    // **Step 1: Detect Plank Position**
    bool isPlank =
        (leftHip.y - leftShoulder.y).abs() < 30 &&
        (rightHip.y - rightShoulder.y).abs() < 30 &&
        (leftHip.y - leftAnkle.y).abs() > 100 &&
        (rightHip.y - rightAnkle.y).abs() > 100;

    // **Step 2: Detect Downward Dog Position**
    bool isDownwardDog =
        (leftHip.y < leftShoulder.y - 50) &&
        (rightHip.y < rightShoulder.y - 50) &&
        (leftAnkle.y > leftHip.y) &&
        (rightAnkle.y > rightHip.y);

    // **Step 3: Count Repetitions**
    if (isDownwardDog && !isInDownwardDog) {
      isInDownwardDog = true;
    } else if (isPlank && isInDownwardDog) {
      onRep();
      isInDownwardDog = false;
    }
  }

  bool isJumping = false;
  bool isJumpingJackOpen = false;
  void detectJumpingJack(Pose pose, {
    required VoidCallback onRep,
  }) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftAnkle == null ||
        rightAnkle == null ||
        leftHip == null ||
        rightHip == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftWrist == null ||
        rightWrist == null) {
      return; // Skip detection if any landmark is missing
    }

    // Calculate distances
    double legSpread = (rightAnkle.x - leftAnkle.x).abs();
    double armHeight = (leftWrist.y + rightWrist.y) / 2; // Average wrist height
    double hipHeight = (leftHip.y + rightHip.y) / 2; // Average hip height
    double shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();

    // Define thresholds based on shoulder width
    double legThreshold =
        shoulderWidth * 1.2; // Legs should be ~1.2x shoulder width apart
    double armThreshold =
        hipHeight - shoulderWidth * 0.5; // Arms should be above shoulders

    // Check if arms are raised and legs are spread
    bool armsUp = armHeight < armThreshold;
    bool legsApart = legSpread > legThreshold;

    // Detect full jumping jack cycle
    if (armsUp && legsApart && !isJumpingJackOpen) {
      isJumpingJackOpen = true;
    } else if (!armsUp && !legsApart && isJumpingJackOpen) {
      onRep();
      isJumpingJackOpen = false;
    }
  }

  // Function to calculate angle between three points (shoulder, elbow, wrist)
  double calculateAngle(
    PoseLandmark shoulder,
    PoseLandmark elbow,
    PoseLandmark wrist,
  ) {
    double a = distance(elbow, wrist);
    double b = distance(shoulder, elbow);
    double c = distance(shoulder, wrist);

    double angle = acos((b * b + a * a - c * c) / (2 * b * a)) * (180 / pi);
    return angle;
  }

  // Helper function to calculate Euclidean distance
  double distance(PoseLandmark p1, PoseLandmark p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  InputImage? _inputImageFromCameraImage() {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = cameras[0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(img!.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888))
      return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (img!.planes.length != 1) return null;
    final plane = img!.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(img!.width.toDouble(), img!.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  //Show rectangles around detected objects
  Widget buildResult() {
    if (_scanResults == null ||
        controller == null ||
        !controller.value.isInitialized) {
      return Text('');
    }
    final Size imageSize = Size(
      controller.value.previewSize!.height,
      controller.value.previewSize!.width,
    );
    CustomPainter painter = PosePainter(imageSize, _scanResults);
    return CustomPaint(painter: painter);
  }
}
