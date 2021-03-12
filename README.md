# ScreenMeetSDK

[![Version](https://img.shields.io/cocoapods/v/ScreenMeetSDK.svg?style=flat)](https://cocoapods.org/pods/ScreenMeetSDK)
[![License](https://img.shields.io/cocoapods/l/ScreenMeetSDK.svg?style=flat)](https://cocoapods.org/pods/ScreenMeetSDK)
[![Platform](https://img.shields.io/cocoapods/p/ScreenMeetSDK.svg?style=flat)](https://cocoapods.org/pods/ScreenMeetSDK)

[![ScreenMeet](https://screenmeet.com/wp-content/uploads/Logo-1.svg)](https://screenmeet.com) 

[ScreenMeet.com](https://screenmeet.com)


## Quick start

Join ScreenMeetLive session
```swift
ScreenMeet.config.organizationKey = yourMobileAPIKey //provided by ScreenMeet
let code = "123456"             // session code
let videoSource =  .backCamera  // select video source [ .backCamera | .frontCamera | .screen ]
ScreenMeet.connect(code, videoSource) { [weak self] error in  
    if let error = error { 
        // session start error
    } else {
        // session started
    }
}
```

Leave Session
```swift
ScreenMeet.disconnect { [weak self] error in
    if let error = error { 
        // error during disconnection
    }
}
```

Retrieve Connection state
```swift
let connectionState = ScreenMeet.getConnectionState() // [ .connecting | .connected | .disconnected ]
```

Mute | Unmute Audio
```swift
let isAudioActive = ScreenMeet.isAudioActive() // true: unmuted, false: muted 

ScreenMeet.toggleLocalAudio() // toggle mute/unmute
```

Mute | Unmute Video
```swift
let isVideoActive = ScreenMeet.isVideoActive() // true: unmuted, false: muted 

ScreenMeet.toggleLocalVideo() // toggle mute/unmute
```

Call participants
```swift
let partisipantsList =  ScreenMeet.getParticipants() // Returns list of call participants [SMParticipant]
```

Change Video Source

- Camera: `.backCamera`, `.frontCamera`
- Screen: `.screen`

```swift
ScreenMeet.changeVideoSource(.backCamera, {error in 
    if let error = error { 
        // change video source error
    }
})
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

## Video Source
Video source can be selected

- Camera: `.backCamera`, `.frontCamera`
- Screen: `.screen`

```swift
//Set video source
config.setVideoSource(.backCamera) 
```

You can specify video device as video source. See `AVCaptureDevice`
```swift
config.setVideoSourceDevice(device: yourAVCaptureDevice)
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
