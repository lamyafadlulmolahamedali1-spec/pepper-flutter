//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<camera_avfoundation/CameraPlugin.h>)
#import <camera_avfoundation/CameraPlugin.h>
#else
@import camera_avfoundation;
#endif

#if __has_include(<device_info_plus/FPPDeviceInfoPlusPlugin.h>)
#import <device_info_plus/FPPDeviceInfoPlusPlugin.h>
#else
@import device_info_plus;
#endif

#if __has_include(<flutter_secure_storage_darwin/FlutterSecureStorageDarwinPlugin.h>)
#import <flutter_secure_storage_darwin/FlutterSecureStorageDarwinPlugin.h>
#else
@import flutter_secure_storage_darwin;
#endif

#if __has_include(<flutter_tts/FlutterTtsPlugin.h>)
#import <flutter_tts/FlutterTtsPlugin.h>
#else
@import flutter_tts;
#endif

#if __has_include(<google_mlkit_commons/GoogleMlKitCommonsPlugin.h>)
#import <google_mlkit_commons/GoogleMlKitCommonsPlugin.h>
#else
@import google_mlkit_commons;
#endif

#if __has_include(<google_mlkit_face_detection/GoogleMlKitFaceDetectionPlugin.h>)
#import <google_mlkit_face_detection/GoogleMlKitFaceDetectionPlugin.h>
#else
@import google_mlkit_face_detection;
#endif

#if __has_include(<google_mlkit_pose_detection/GoogleMlKitPoseDetectionPlugin.h>)
#import <google_mlkit_pose_detection/GoogleMlKitPoseDetectionPlugin.h>
#else
@import google_mlkit_pose_detection;
#endif

#if __has_include(<package_info_plus/FPPPackageInfoPlusPlugin.h>)
#import <package_info_plus/FPPPackageInfoPlusPlugin.h>
#else
@import package_info_plus;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<printing/PrintingPlugin.h>)
#import <printing/PrintingPlugin.h>
#else
@import printing;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<speech_to_text/SpeechToTextPlugin.h>)
#import <speech_to_text/SpeechToTextPlugin.h>
#else
@import speech_to_text;
#endif

#if __has_include(<sqflite_darwin/SqflitePlugin.h>)
#import <sqflite_darwin/SqflitePlugin.h>
#else
@import sqflite_darwin;
#endif

#if __has_include(<wakelock_plus/WakelockPlusPlugin.h>)
#import <wakelock_plus/WakelockPlusPlugin.h>
#else
@import wakelock_plus;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [CameraPlugin registerWithRegistrar:[registry registrarForPlugin:@"CameraPlugin"]];
  [FPPDeviceInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPDeviceInfoPlusPlugin"]];
  [FlutterSecureStorageDarwinPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterSecureStorageDarwinPlugin"]];
  [FlutterTtsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterTtsPlugin"]];
  [GoogleMlKitCommonsPlugin registerWithRegistrar:[registry registrarForPlugin:@"GoogleMlKitCommonsPlugin"]];
  [GoogleMlKitFaceDetectionPlugin registerWithRegistrar:[registry registrarForPlugin:@"GoogleMlKitFaceDetectionPlugin"]];
  [GoogleMlKitPoseDetectionPlugin registerWithRegistrar:[registry registrarForPlugin:@"GoogleMlKitPoseDetectionPlugin"]];
  [FPPPackageInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPPackageInfoPlusPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [PrintingPlugin registerWithRegistrar:[registry registrarForPlugin:@"PrintingPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [SpeechToTextPlugin registerWithRegistrar:[registry registrarForPlugin:@"SpeechToTextPlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
  [WakelockPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"WakelockPlusPlugin"]];
}

@end
