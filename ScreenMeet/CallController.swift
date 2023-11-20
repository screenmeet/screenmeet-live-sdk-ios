//
//  CallController.swift
//  DemoiOS
//
//  Created by Ross on 13.10.2022.
//
import ScreenMeetLive
import UIKit
import WebRTC

class SMItem {
    var track: RTCVideoTrack?
    var participant: SMParticipant!
    var info: SMTrackInfo!
    
    init(track: RTCVideoTrack? = nil, info: SMTrackInfo? = nil, participant: SMParticipant!) {
        self.track = track
        self.participant = participant
        self.info = info
    }
}

protocol CallPresentable: AnyObject {
    
    func onFeatureRequest(_ featureRequest: SMFeatureRequestData)
    func onFeatureRequestRejected(requestId: String)
    func onScreenShareRequested(_ requestor: SMParticipant)
    func onFeatureStarted(_ featureRequest: SMFeatureRequestData)
    func onFeatureStopped(_ featureRequest: SMFeatureRequestData)
    
    func onUpdateActiveSpeakerItem(_ item: SMItem)
    func onClearActiveSpeakerItem()
    
    func onReloadAllItems()
    
    func onItemMediaStateChanged(_ index: Int, _ item: SMItem)
    func onActiveSpeakerMediaStateChanged(_ participant: SMParticipant)
        
    func onUpdateAudioButton(_ state: Bool)
    func onUpdateVideoButton(_ state: Bool)
    func onUpdateScreenSharingButton(_ state: Bool)
    
    func onConnectionStateChanged(_ connectionState: SMConnectionState)
    func onError(_ error: SMError)
}

class CallController {
    
    weak var presentable: CallPresentable?
    weak var remoteControlledViewController: UIViewController?
    
    private weak var currentDevice: AVCaptureDevice!
    
    private var currentActiveSpeakerItem: SMItem? = nil

    private var items = [SMItem]()
    
    init() {
        currentDevice = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first!
        
        ScreenMeet.delegate = self
        
        updateParticipantItems()
    }
    
    func toggleAudio() {
        if ScreenMeet.getMediaState().isAudioActive {
            ScreenMeet.stopAudioSharing()
        }
        else {
            ScreenMeet.shareMicrophone()
        }
    }
    
    func toggleVideo() {
        if ScreenMeet.getMediaState().isCameraVideoActive {
            ScreenMeet.stopVideoSharing(.camera(SMCameraConfiguration(device: currentDevice, format: currentDevice.activeFormat)))
        }
        else {
            ScreenMeet.shareCamera(SMCameraConfiguration(device: currentDevice, format: currentDevice.activeFormat))
        }
    }
    
    func toggleScreen() {
        if ScreenMeet.getMediaState().isScreenVideoActive {
            ScreenMeet.stopVideoSharing(.screen)
        }
        else {
            ScreenMeet.shareScreen(.screen)
        }
    }
    
    func hangup() {
        ScreenMeet.disconnect()
        items.removeAll()
    }
    
    func getMediaState() -> SMParticipantMediaState {
        return ScreenMeet.getMediaState()
    }
    
    func checkPendingPermissionsRequests() {
        let pendingRequests = ScreenMeet.pendingFeatureRequests()
        
        if let me = findMeAsParticipant(), !pendingRequests.isEmpty {
            pendingRequests.forEach { featureRequestData in
                if featureRequestData.grantorCid == me.id {
                    presentable?.onFeatureRequest(featureRequestData)
                }
            }
        }
        
        let grantedRequests = ScreenMeet.grantedFeatureRequests()
        if let me = findMeAsParticipant(), !grantedRequests.isEmpty {
            grantedRequests.forEach { featureRequestData in
                if featureRequestData.grantorCid == me.id {
                    presentable?.onFeatureStarted(featureRequestData)
                }
            }
        }
        
    }
    
    func itemAt(_ index: Int) -> SMItem? {
        if index < items.count {
            return items[index]
        }
        return nil
    }
    
    func numberOItems() -> Int {
        let participants = ScreenMeet.getParticipants().sorted { $0.name < $1.name }
        var n = 0
        participants.forEach { participant in
            
            var numberOfActiveTracks = 0
            if participant == currentActiveSpeakerItem?.participant {
                let activeTracks = participant.videoTracks.filter { smVideoTrack in
                    smVideoTrack.info.trackId == currentActiveSpeakerItem?.info?.trackId
                }
                numberOfActiveTracks = activeTracks.count
            }
            
            if participant == currentActiveSpeakerItem?.participant {
                n += participant.videoTracks.isEmpty ? 0 : (participant.videoTracks.count - numberOfActiveTracks)
            }
            else {
                n += participant.videoTracks.isEmpty ? 1 : participant.videoTracks.count
            }
        }
        
        return n
    }
    
    func hasActiveSpeaker() -> Bool {
        return currentActiveSpeakerItem != nil
    }
    
    func setRemoteControlledViewController(_ viewController: UIViewController) {
        self.remoteControlledViewController = viewController
    }
    
    private func updateParticipantItems() {
        items = [SMItem]()
        let participants = ScreenMeet.getParticipants().sorted { $0.name < $1.name }
        
        participants.forEach { p in
            
            if p.videoTracks.isEmpty {
                if currentActiveSpeakerItem?.participant != p {
                    items.append(SMItem(track: nil, info: nil, participant: p))
                }
            }
            else {
                p.videoTracks.forEach { smVideoTrack in
                    if currentActiveSpeakerItem?.info?.trackId != smVideoTrack.info.trackId {
                        items.append(SMItem(track: smVideoTrack.rtcTrack, info: smVideoTrack.info, participant: p))
                    }
                }
            }
        }
    }
    
    private func findMeAsParticipant() -> SMParticipant? {
        return ScreenMeet.getParticipants().first { participant in
            participant.isMe
        }
    }
    
}

extension CallController: ScreenMeetDelegate {
    
    func onFeatureRequest(_ featureReqeust: ScreenMeetLive.SMFeatureRequestData, _ decisionHandler: @escaping (Bool) -> Void) {
        decisionHandler(true)
    }
    
    func onParticipantInfoUpdated(_ updatedParticipant: ScreenMeetLive.SMParticipant) {
        
    }
    
    func onWaitingListChanged(_ waitingParticipants: [ScreenMeetLive.SMWaitingParticipantInfo]) {
        
    }
    
    func onLocalAudioCreated() {
        presentable?.onUpdateAudioButton(true)
    }
    
    func onLocalVideoCreated(_ source: SMVideoSource, _ videoTrack: SMVideoTrack) {
        if let me = findMeAsParticipant() {
            onParticipantVideoTrackCreated(me, videoTrack.rtcTrack, videoTrack.info)
        }
        if source == .screen { presentable?.onUpdateScreenSharingButton(true) }
        else { presentable?.onUpdateVideoButton(true) }
    }
    
    func onLocalVideoSourceChanged() {
        if let me = findMeAsParticipant() {
            items.forEach { item in
                if item.participant.id == me.id {
                    
                }
            }
        }
    }
    
    func onLocalVideoStopped(_ source: SMVideoSource, _ track: SMVideoTrack) {
        if let me = findMeAsParticipant() {
            onParticipantVideoTrackStopped(me, track.rtcTrack, track.info)
            
            if source.isScreen { presentable?.onUpdateScreenSharingButton(false) }
            else { presentable?.onUpdateVideoButton(false) }
        }
    }
    
    func onLocalAudioStopped() {
        presentable?.onUpdateAudioButton(false)
    }
    
    func onParticipantJoined(_ participant: SMParticipant) {
        updateParticipantItems()
        presentable?.onReloadAllItems()
    }
    
    func onParticipantVideoTrackCreated(_ participant: SMParticipant, _ track: RTCVideoTrack, _ trackInfo: SMTrackInfo) {
       
        if (currentActiveSpeakerItem?.participant == participant && currentActiveSpeakerItem?.track == nil) || trackInfo.profile == "screen_share" {
            currentActiveSpeakerItem = SMItem(track: track, info: trackInfo, participant: participant)
            presentable?.onUpdateActiveSpeakerItem(currentActiveSpeakerItem!)
        }
        
        updateParticipantItems()
        presentable?.onReloadAllItems()
    }
    
    func onParticipantVideoTrackStopped(_ participant: SMParticipant, _ track: RTCVideoTrack, _ trackInfo: SMTrackInfo) {
       
        if currentActiveSpeakerItem?.participant == participant && currentActiveSpeakerItem?.info?.trackId == trackInfo.trackId {
            currentActiveSpeakerItem = SMItem(track: nil, info: nil, participant: participant)
            presentable?.onUpdateActiveSpeakerItem(currentActiveSpeakerItem!)
        }
        
        updateParticipantItems()
        presentable?.onReloadAllItems()
    }
    
    func onParticipantAudioTrackCreated(_ participant: SMParticipant) {
        var i = 0
        items.forEach { item in
            if item.participant.id == participant.id {
                presentable?.onItemMediaStateChanged(i, item)
            }
            i += 1
        }
        
        if currentActiveSpeakerItem?.participant == participant {
            presentable?.onActiveSpeakerMediaStateChanged(participant)
        }
    }
    
    func onParticipantLeft(_ participant: SMParticipant) {
        if currentActiveSpeakerItem?.participant == participant {
            currentActiveSpeakerItem = nil
            presentable?.onClearActiveSpeakerItem()
        }
        updateParticipantItems()
        presentable?.onReloadAllItems()
    }
    
    func onParticipantMediaStateChanged(_ participant: SMParticipant) {
        var i = 0
        items.forEach { item in
            if item.participant.id == participant.id {
                presentable?.onItemMediaStateChanged(i, item)
            }
            i += 1
        }
        if currentActiveSpeakerItem?.participant == participant {
            presentable?.onActiveSpeakerMediaStateChanged(participant)
        }
    }
    
    func onActiveSpeakerChanged(_ participant: SMParticipant, _ trackInfo: SMTrackInfo?) {
        let track = participant.videoTracks.first { smVideoTrack in
            smVideoTrack.info.trackId == trackInfo?.trackId
        }
        
        currentActiveSpeakerItem = SMItem(track: track?.rtcTrack, info: trackInfo, participant: participant)
        presentable?.onUpdateActiveSpeakerItem(currentActiveSpeakerItem!)
        
        updateParticipantItems()
        presentable?.onReloadAllItems()
    }
    
    func onConnectionStateChanged(_ newState: SMConnectionState) {
        presentable?.onConnectionStateChanged(newState)
    }
    
    func onError(_ error: SMError) {
        presentable?.onError(error)
    }
    
    func onFeatureRequest(_ featureRequest: SMFeatureRequestData) {
        presentable?.onFeatureRequest(featureRequest)
    }
    
    func onFeatureRequestRejected(_ featureRequest: ScreenMeetLive.SMFeatureRequestData) {
        presentable?.onFeatureRequestRejected(requestId: featureRequest.requestId)
    }
    
    func onFeatureRequestsChanged() {
        
    }
    
    
    func onFeatureStopped(_ featureRequest: SMFeatureRequestData) {
        
    }
    
    func onFeatureStarted(_ featureRequest: SMFeatureRequestData) {
        presentable?.onFeatureStarted(featureRequest)
    }
    
    func onRemoteControlEvent(_ event: SMRemoteControlEvent) {
        
    }
    
    func onScreenShareRequested(_ requestor: ScreenMeetLive.SMParticipant) {
        presentable?.onScreenShareRequested(requestor)
    }
    
    var rootViewController: UIViewController? {
        return remoteControlledViewController?.navigationController
    }
    
}
