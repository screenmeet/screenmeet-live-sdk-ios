//
//  ViewController.swift
//  ScreenMeet
//
//  Created by Ross on 11.01.2021.
//

import UIKit
import AVFoundation
import WebRTC
import ScreenMeetSDK

class ViewController: UIViewController {

    // temp
    private var currentRemoteVideoTrack: RTCVideoTrack!
    
    @IBOutlet weak var gifImageView: UIImageView!
    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var screenButton: UIButton!
    
    @IBOutlet weak var connectButton: UIButton!
    
    @IBOutlet var localVideoView: RTCEAGLVideoView!
    @IBOutlet var remoteVideoView: RTCEAGLVideoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        controlsView.isHidden = true
    }

    @IBAction func connect() {
        connectButton.isHidden = true
        remoteVideoView.isHidden = false
        localVideoView.isHidden = false
        checkDevicePermissions()
    }
    
    @IBAction func disconnect() {
        connectButton.isHidden = false
        connectButton.alpha = 0.0
        
        ScreenMeet.disconnect { [weak self] error in
            self?.showConnectButton()
        }
        
        if let currentRemoteVideoTrack = currentRemoteVideoTrack {
            currentRemoteVideoTrack.remove(remoteVideoView)
            self.currentRemoteVideoTrack = nil
            remoteVideoView.isHidden = true
            localVideoView.isHidden = true
        }
    }
    
    @IBAction func audioButtonClicked() {
        var state = ScreenMeet.isAudioActive()
        state = !state
        ScreenMeet.toggleLocalAudio()
    }
    
    @IBAction func videoButtonClicked() {
        var state = ScreenMeet.isVideoActive()
        state = !state
        ScreenMeet.toggleLocalVideo()
    }
    
    @IBAction func screenButtonClicked(_ sender: Any) {
        if (ScreenMeet.getVideoSourceDevice() == nil) {
            ScreenMeet.changeVideoSource(.frontCamera, {error in
                print("Error: \(error.debugDescription)")
            })
        } else {
            ScreenMeet.changeVideoSource(.screen, {error in
                print("Error: \(error.debugDescription)")
            })
        }
    }
    
    private func showConnectButton() {
        UIView.animate(withDuration: 0.4) { [weak self] in
            self?.controlsView.alpha = 0.0
            self?.connectButton.alpha = 1.0
        }
        gifImageView.image = nil
    }
    
    private func checkDevicePermissions() {
        // Camera permission
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (isGranted: Bool) in
                self?.start()
            })
        } else {
            start()
        }
    }
    
    private func start() {
        let gif = UIImage.gifImageWithName("stars")
        gifImageView.image = gif
        ScreenMeet.config.organizationKey = "[INSERT MOBILE API KEY HERE]"
        ScreenMeet.delegate = self
        ScreenMeet.connect("[INSERT SESSION CODE]", .backCamera) { [weak self] error in
            if let error = error {
                NSLog("Could not connect: " + error.message)
                self?.showConnectButton()
            }
            else {
                DispatchQueue.main.async {
                    self?.showControls()
                }
                
                NSLog("Started")
            }
        }
        
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 89.5) {
            ScreenMeet.changeVideoSource(.screen)
        }*/
    }
    
    private func showControls() {
        controlsView.alpha = 0.0
        controlsView.isHidden = false
        
        UIView.animate(withDuration: 0.4) { [self] in
            controlsView.alpha = 1.0
            connectButton.alpha = 0.0
        }
        
        let participants = ScreenMeet.getParticipants()
        NSLog("Particpants: %@", participants)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension ViewController: SMDelegate {
    
    func onLocalAudioCreated() {
        NSLog("Local audio created")
    }
    
    func onLocalVideoCreated(_ videoTrack: RTCVideoTrack) {
        videoTrack.add(localVideoView)
    }
    
    func onLocalVideoStopped() {
        videoButton.backgroundColor = UIColor.gray
    }
    
    func onLocalVideoResumed() {
        videoButton.backgroundColor = UIColor.white
    }
    
    func onLocalAudioStopped() {
        audioButton.backgroundColor = UIColor.gray
    }
    
    func onLocalAudioResumed() {
        audioButton.backgroundColor = UIColor.white
    }
    
    func onActiveSpeakerChanged(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant became active speaker: " + participant.identity.user!.name)
        
        if let currentRemoteVideoTrack = currentRemoteVideoTrack {
            currentRemoteVideoTrack.remove(remoteVideoView)
        }
        currentRemoteVideoTrack = participant.videoTrack
        participant.videoTrack?.add(remoteVideoView)
    }
    
    func onParticipantJoined(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant joined: " + participant.identity.user!.name)
    }
    
    func onParticipantVideoTrackCreated(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.identity.user!.name + " started video")
        
        if let currentRemoteVideoTrack = currentRemoteVideoTrack {
            currentRemoteVideoTrack.remove(remoteVideoView)
        }
        currentRemoteVideoTrack = participant.videoTrack
        participant.videoTrack?.add(remoteVideoView)
    }
    
    func onParticipantAudioTrackCreated(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.identity.user!.name + " started audio")
    }
    
    func onParticipantMediaStateChanged(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant " + participant.identity.user!.name + " has changed its media state (muted, resumed, etc)")
    }
    
    func onParticipantLeft(_ participant: SMParticipant) {
        NSLog("[ScreenMeet] Participant left: " + participant.identity.user!.name)
    }
    
    func onIceConnectionStateChanged(_ transportDirection: String, _ newState: SMIceConnectionState) {
        NSLog("[ScreenMeet] Ice connection state. Direction: " + transportDirection + " :" + newState.rawValue)
    }
    
    func onConnectionStateChanged(_ newState: SMConnectionState) {
        NSLog("[ScreenMeet] Connection state: " + String(newState.rawValue))
    }
    
}

