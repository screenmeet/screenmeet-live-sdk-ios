# ScreenMeetSDK

[![Version](https://img.shields.io/cocoapods/v/ScreenMeetSDK.svg?style=flat)](https://cocoapods.org/pods/ScreenMeetSDK)
[![License](https://img.shields.io/cocoapods/l/ScreenMeetSDK.svg?style=flat)](https://cocoapods.org/pods/ScreenMeetSDK)
[![Platform](https://img.shields.io/cocoapods/p/ScreenMeetSDK.svg?style=flat)](https://cocoapods.org/pods/ScreenMeetSDK)

[![ScreenMeet](https://screenmeet.com/wp-content/uploads/Logo-1.svg)](https://screenmeet.com) 

[ScreenMeet.com](https://screenmeet.com)


## Usage

Join ScreenMeetLive session
```swift
ScreenMeet.config.organizationKey = yourMobileAPIKey //provided by ScreenMeet
let code = "OdeWGubyvsUh"             // session code
ScreenMeet.connect(code) { [weak self] error in  
    if let error = error { 
        // session start error
    } else {
        // session started
    }
}
```

Retrieve Connection state
```swift
let connectionState = ScreenMeet.getConnectionState() 

switch connectionState {
case .connecting:
    print("waiting for connecting to call ...")
case .connected:
    print("joined the call")
case .reconnecting:
    print("trying to restore connection to call ...")
case .disconnected(.callNotStarted):
    print("Call disconnected. Call is not started")
case .disconnected(.callEnded):
    print("Call disconnected. Call is finished")
case .disconnected(.leftCall):
    print("Call disconnected. Client left call")
case .disconnected(.networkError):
    print("Call disconnected. Network error")
}
```

Share Camera
```swift
ScreenMeet.shareCamera() // by default start front camera sharing
```
To specify camera and/or camera configuration use `AVCaptureDevice`
```swift
let device = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera],
                                                    mediaType: .video,
                                                    position: .back).devices.first!
ScreenMeet.shareCamera(device)
```

Share Screen
```swift
ScreenMeet.shareScreen()
```


Share stream of images (Can be used for screen sharing by continuously providing raw images, screen shots for example)
`SMImageHandler` contains a single interface `transferImage(_ image: UIImage)` that you can use to send images 
```swift
ScreenMeet.shareScreenWithImageTransfer(_ completion: @escaping ((SMImageHandler?) -> Void))
```

Stop Video sharing
```swift
ScreenMeet.stopVideoSharing() // Stop Camera or Screen sharing
```

Share Microphone
```swift
ScreenMeet.shareMicrophone()
```

Stop Audio sharing
```swift
ScreenMeet.stopAudioSharing() // Stop audio sharing
```

Retrieve Audio and Video states
```swift
let state = ScreenMeet.getMediaState()

let isAudioActive = state.isAudioActive // true: unmuted, false: muted 
let isVideoActive = state.isVideoActive // true: unmuted, false: muted 

let videoState = state.videoState // VideoState enum [CAMERA, SCREEN, NONE]
let audioState = state.audioState // AudioState enum [MICROPHONE, NONE]
```

Leave Session
```swift
ScreenMeet.disconnect()
```

Call participants
```swift
let partisipantsList =  ScreenMeet.getParticipants() // Returns list of call participants [SMParticipant]
```

## Example

To run the example project, clone the repo, and run `pod install` from the [Example](Example/) directory first.
More advanced sample with SwiftUI see in [FullExample](Example/FullExample) application.

## Requirements

 | | Minimum iOS version
------ | -------
**ScreenMeetSDK** | **iOS 12.0**
[Example](Example/) | iOS 13.0

## Installation

ScreenMeetSDK is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ScreenMeetSDK'
```

Also **bitcode** should be disabled. It can be done manualy in xCode, or add the following lines at the end of your pod file

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

```

# ScreenMeetLive Events handling

## Configure events handler

Set your event handler
```swift
ScreenMeet.delegate = yourSMDelegate
```
where `yourSMDelegate` is your implementation of `ScreenMeetDelegate` protocol

## Local track events

```swift
/// on Audio stream created
func onLocalAudioCreated()

/// on Local Video stream created
/// - Parameter videoTrack: Can be used to preview local video. See `RTCVideoTrack`
func onLocalVideoCreated(_ videoTrack: RTCVideoTrack)

/// on Local Video stream stoped
func onLocalVideoStopped()

/// on Local Audio stream stoped
func onLocalAudioStopped()

```

## Participants events

```swift
/// On participant joins call.
/// - Parameter participant: Participant details. See `SMParticipant`
func onParticipantJoined(_ participant: SMParticipant)

/// On receiving video stream from participant.
/// - Parameter participant: Participant details. See `SMParticipant`
/// - Parameter remoteVideoTrack: Can be used to preview participant video stream. See `RTCVideoTrack`
func onParticipantVideoTrackCreated(_ participant: SMParticipant, _ remoteVideoTrack: RTCVideoTrack)

/// On receiving video stream from participant.
/// - Parameter participant: Participant details. See `SMParticipant`
/// - Parameter remoteAudioTrack: Remote participant audio stream. See `RTCAudioTrack`
func onParticipantAudioTrackCreated(_ participant: SMParticipant, _ remoteAudioTrack: RTCAudioTrack)

/// On participant left call.
/// - Parameter participant: Participant details. See `SMParticipant`
func onParticipantLeft(_ participant: SMParticipant)

/// When participant state was changed. For example participant muted, paused, resumed video, etc
/// - Parameter participant: Participant details. See `SMParticipant`
func onParticipantMediaStateChanged(_ participant: SMParticipant)

/// When active speaker changed. 
/// - Parameter participant: Participant details. See `SMParticipant`
func onActiveSpeakerChanged(_ participant: SMParticipant, _ remoteVideoTrack: RTCVideoTrack)
```
    
## Feature requests (remote control, laser pointer)

```swift
/// Occurs when approval for a feature(remote control or laser pointer) is requested from you
///
/// - Parameters:
///  - feature: Feature being requested. Containes details about type of the feature and participant who requested it
///  - decisionHandler: The callback called after request is accepted or denied
///  - granted: The retrieved decision for request.
func onFeatureRequest(_ feature: SMFeature, _ decisionHandler: @escaping (_ granted: Bool) -> Void)
    
/// Occurs when previous request is rejected
///
/// - Parameters:
/// - feature: Feature request that has been rejested. Containes details about type of the feature and participant who requested it
func onFeatureRequestRejected(feature: SMFeature)
    
/// Occurs when a feature has stopped
///
/// - Parameters:
///  - feture: Feature that has been stopped
func onFeatureStopped(feature: SMFeature)
    
/// Occurs when certain feature (you approved) starts its activity (remote control, laser pointer)
///
/// - Parameters:
///  - feature: Feature that has stated
func onFeatureStarted(feature: SMFeature)
    
```

## Remote Control

```swift
/// Occures during remote control session when an agent triggers and event. Can be a mouse or a keybaord event
///
/// - Parameters:
///  - event: Remote control event. See `SMRemoteControlEvent`
func onRemoteControlEvent(_ event: SMRemoteControlEvent)
    
/// Root view controller to be remote controlled (Allowing viewer to perform touches on your view controller(s)). It should be the root(bottom most superview) view of the entire window
var rootViewController: UIViewController? { get }
```

## Important error events

```swift
/// When error occurred
/// - Parameter error `SMError`
func onError(_ error: SMError)
```

## Connection state changing

```swift
/// On connection state change
/// - Parameter new session state: `SMState`
func onConnectionStateChanged(_ newState: SMConnectionState)

```
# Configuration 
ScreenMeet Live requires initial config to join session
```swift
//Create config object
let config = SMSessionConfig()
```

## Organization Key
To start work with SDK __organizationKey__ (mobileKey) is required
```swift
//Set organization mobile Key
ScreenMeet.shared.config.organizationKey = yourMobileAPIKey //provided by ScreenMeet
```

## Logging level
Represent the severity and importance of log messages ouput
```swift
config.loggingLevel = .debug
```
Possible values:
```swift
public enum LogLevel {
    /// Information that may be helpful, but is not essential, for troubleshooting errors
    case info
    /// Verbose information that may be useful during development or while troubleshooting a specific problem
    case debug
    /// Designates error events that might still allow the application to continue running
    case error
}
```

## Custom Endpoint URL
Set custom endpoint URL
```swift
config.endpoint = yourEndpointURL
```




## License

ScreenMeetLiveSDK is available under the MIT license. See the LICENSE file for more info.
