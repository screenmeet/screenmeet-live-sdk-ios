//
//  ViewController.swift
//  DemoiOS
//
//  Created by Ross on 26.08.2022.
//

import UIKit
import ScreenMeetLive
import WebRTC

extension UIColor {
    static public var screenMeetBrandColor: UIColor {
        return UIColor(red: 255.0/255.0, green: 116.0/255.0, blue: 52.0/255.0, alpha: 1.0)
    }
}

class CallViewController: UIViewController {

    /* Active speaker outlets*/
    @IBOutlet weak var activeSpeakerView: UIView!
    @IBOutlet weak var activeSpeakerAvatarView: UIImageView!

    @IBOutlet weak var activeSpeakerNameLabel: UILabel!
    @IBOutlet weak var activeSpeakerNameLabelBackgroundView: UIView!

    @IBOutlet weak var activeSpeakerMicBackgroundView: UIView!
    @IBOutlet weak var activeSpeakerMicIcon: UIImageView!
    @IBOutlet weak var activeSpeakerNameLabelLeftMargin: NSLayoutConstraint!

    /* Participants collection view outlets*/
    @IBOutlet weak var participantsCollectionView: UICollectionView!
    private var gridLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var participantsCollectionViewBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var participantsCollectionViewTopMargin: NSLayoutConstraint!

    
    /* Audio permission error badge*/
    @IBOutlet weak var micPermissionErrorButton: UIButton!
    
    /* Video permission error badge*/
    @IBOutlet weak var cameraPermissionErrorButton: UIButton!
    
    /* Call controls*/
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var screenButton: UIButton!
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var hangupButton: UIButton!
    @IBOutlet weak var remoteControlButton: UIButton!
    
    @IBOutlet weak var sharingOwnScreenView: UIView!
    
    @IBOutlet weak var callControlsView: UIView!

    /* Top info bar*/
    @IBOutlet weak var topInfoView: UIView!
    @IBOutlet weak var topInfoLabel: UILabel!

    /* Current source being shared*/
    private var currentSource: SMVideoSource!
    
    private var alert: UIAlertController? = nil
    
    
    private lazy var controller: CallController =  {
        let controller = CallController()
        controller.presentable = self
        return controller
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        checkVideoPermission()
        checkAudioPermission()
        
        updateCollectionViewLayoutForMaximizedState()
        controller.remoteControlledViewController = navigationController
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
        controller.setRemoteControlledViewController(self)
        controller.checkPendingPermissionsRequests()
    }
    
    @IBAction func micButtonClicked(_ sender: UIButton) {
        controller.toggleAudio()
    }
    
    @IBAction func cameraButtonClicked(_ sender: UIButton) {
        controller.toggleVideo()
    }
    
    @IBAction func screenButtonClicked(_ sender: UIButton) {
        controller.toggleScreen()
    }
    
    @IBAction func hangupButtonClicked(_ sender: UIButton) {
        controller.hangup()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func remoteControlButtonClicked(_ sender: UIButton) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "TabbarViewController") as? TabbarViewController {
            navigationController?.pushViewController(viewController, animated: true)
            controller.setRemoteControlledViewController(viewController)
        }
    }
    
    @objc private func willEnterForeground() {
        checkAudioPermission()
        checkVideoPermission()
    }
    
    private func showReconnectingState() {
        topInfoView.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 0.7)
        topInfoLabel.text = "Reconnecting..."
        topInfoView.isHidden = false
        activeSpeakerView.isHidden = true
        participantsCollectionView.isHidden = true
        hideCallControls()
    }
    
    private func showConnectedState() {
        topInfoView.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
        topInfoLabel.text = "Reconnecting..."
        topInfoView.isHidden = true
        activeSpeakerView.isHidden = false
        participantsCollectionView.isHidden = false
        showCallControls()
    }
    
    private func hideCallControls() {
        micButton.isHidden = true
        cameraButton.isHidden = true
        screenButton.isHidden = true
        detailsButton?.isHidden = true
        hangupButton.isHidden = true
    }
    
    private func showCallControls() {
        micButton.isHidden = false
        cameraButton.isHidden = false
        screenButton.isHidden = false
        detailsButton?.isHidden = false
        hangupButton.isHidden = false
    }
    
    private func presentRequestAlert(for permissionType: SMPermissionType, participant: SMParticipant, _ requestId: String, completion: @escaping (Bool) -> Void) {
        
        
        if let alert = alert {
            alert.dismiss(animated: true)
        }
        
        var title: String = ""
        var message: String = ""
        
        switch permissionType {
            case .laserpointer:
                title = "\"\(participant.name)\" Would you like to start laser pointer?"
                message = "It's needed to help you navigate"
            
            case .remotecontrol:
                title = "\"\(participant.name)\" Would you like to be remote controlled?"
                message = "It will allow making touches and keyboard event by remote participant on your mac"
            @unknown default:
                NSLog("[SM] Unknown permission type  encountered at presentRequestAlert")
        }
        
        alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)

        alert!.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.default, handler: { _ in
            completion(false)
        }))
        
        alert!.addAction(UIAlertAction(title: "Yes",
                                               style: UIAlertAction.Style.default,
                                              handler: {(_: UIAlertAction!) in
            completion(true)
        }))
        
        self.present(alert!, animated: true, completion: nil)
    }
    
    private func showGoToSettingsAlert(_ mediaType: AVMediaType) {
        if mediaType == .video {
            let alert = UIAlertController(title: "Camera", message: "Camera access is necessary to use this app", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { action in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))

            self.present(alert, animated: true)
        }
        else if mediaType == .audio {
            let alert = UIAlertController(title: "Microphone", message: "Microphone access is necessary to use this app", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { action in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))

            self.present(alert, animated: true)
        }
    }
    
    private func showRequestScreenShareAlert(_ participantName: String) {
        let alert = UIAlertController(title: "", message: "\(participantName) asks you a permission to view your screen", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Allow", style: .default, handler: { [weak self]action in
            if let screenButton = self?.screenButton {
                self?.screenButtonClicked(screenButton)
            }
            alert.dismiss(animated: false)
        }))
        alert.addAction(UIAlertAction(title: "Deny", style: .cancel, handler: { action in
            alert.dismiss(animated: false)
        }))

        self.present(alert, animated: true)
    }
    
    
    private func updateCollectionViewLayoutForMinimizedState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [self] in
            if controller.numberOItems() == 0 {
                participantsCollectionViewBottomMargin.constant = view.bounds.height
            }
            else {
                participantsCollectionViewBottomMargin.constant = view.bounds.height - 290
            }
            
            gridLayout = UICollectionViewFlowLayout()
            gridLayout.scrollDirection = .horizontal
           
            gridLayout.itemSize = CGSize(width: 212, height: 212)
            gridLayout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            
            participantsCollectionView.collectionViewLayout = gridLayout
        })
    }
    
    private func updateActiveSpeakerMediaState(_ participant: SMParticipant) {
        activeSpeakerNameLabel.isHidden = false
        activeSpeakerNameLabelBackgroundView.isHidden = false
        activeSpeakerNameLabel.text = participant.name
        activeSpeakerMicBackgroundView.isHidden = !participant.avState.isAudioActive
        activeSpeakerNameLabelLeftMargin.constant = !participant.avState.isAudioActive ? 0 : 24
        
        activeSpeakerMicBackgroundView.backgroundColor = UIColor.screenMeetBrandColor
        activeSpeakerNameLabelBackgroundView.backgroundColor = UIColor.black
    }
                                      
    private func updateCollectionViewLayoutForMaximizedState() {
        DispatchQueue.main.asyncAfter(deadline: (.now() + 0.1), execute: { [self] in
            layoutItems()
        })
    }
    
    private func layoutItems() {
        var cellHeight: CGFloat = 0.0
        var cellWidth: CGFloat = 0.0
        
        participantsCollectionViewBottomMargin.constant = 0
        
        var rowCount = 0
        var interColumnSpacing: CGFloat = 10
        let previousNumberOfItems = participantsCollectionView.numberOfItems(inSection: 0)
        
        let newNumberOfItems = controller.numberOItems()
            participantsCollectionView.isHidden = false
        
        if newNumberOfItems == 1 {
                rowCount = 1
                gridLayout = UICollectionViewFlowLayout()
            
                cellHeight = (view.bounds.size.height - 40) / 2
                cellWidth = (view.bounds.size.width - interColumnSpacing * 2)
            
                gridLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            }
        
            if newNumberOfItems == 2 {
                rowCount = 2
                gridLayout = UICollectionViewFlowLayout()
               
                cellHeight = (view.bounds.size.height - 40) / 4
                cellWidth = (view.bounds.size.width - interColumnSpacing * 3)
                
                gridLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
                
            }
            else if newNumberOfItems == 3 {
                rowCount = 2
                gridLayout = UICollectionViewFlowLayout()
              
                cellHeight = (view.bounds.size.height - 40) / 4
                cellWidth = (view.bounds.size.width - interColumnSpacing * 4) / 2
                
                gridLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            }
            else if newNumberOfItems == 4 {
                rowCount = 2
                gridLayout = UICollectionViewFlowLayout()
                
                cellHeight = (view.bounds.size.height - 40) / 4
                cellWidth = (view.bounds.size.width - interColumnSpacing * 4) / 2
                
                gridLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            }
            else if newNumberOfItems > 4 && newNumberOfItems < 7 {
                rowCount = 3
                gridLayout = UICollectionViewFlowLayout()
                
                cellHeight = (view.bounds.size.height - 40) / 3
                cellWidth = (view.bounds.size.width - 40) / 2
                
                gridLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            }
        
            let numberOfCells = floor(participantsCollectionView.frame.size.width / cellWidth)
            let left = (participantsCollectionView.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
            let right = left
        
            let top = (participantsCollectionView.frame.size.height - (CGFloat(rowCount) * cellHeight)) / CGFloat(rowCount + 1)
            let bottom = top
            
            gridLayout?.scrollDirection = .vertical
            gridLayout?.minimumInteritemSpacing = interColumnSpacing
            gridLayout?.sectionInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            participantsCollectionView.collectionViewLayout = gridLayout
    }
    
    private func checkVideoPermission() {
        authorize(.video) { [weak self] granted in
            self?.cameraPermissionErrorButton.isHidden = granted
        }
        
    }
    
    private func checkAudioPermission() {
        authorize(.audio) { [weak self] granted in
            self?.micPermissionErrorButton.isHidden = granted
        }
    }
}

extension CallViewController: CallPresentable {
    
    func onFeatureRequest(_ featureRequest: SMFeatureRequestData) {
        
        DispatchQueue.main.async {  [weak self] in
            if let requestorParticipant = ScreenMeet.getParticipants().first(where: { p in
                p.id == featureRequest.requestorCid
            }) {
                self?.presentRequestAlert(for: SMPermissionType(rawValue: featureRequest.privilege)!,
                                          participant: requestorParticipant,
                                          featureRequest.requestId,
                                          completion:featureRequest.decisionHandler!)
            }
            
        }
    }
    
    func onFeatureRequestRejected(requestId: String) {
        if let alert = alert {
            alert.dismiss(animated: false)
        }
    }
    
    func onScreenShareRequested(_ requestor: SMParticipant) {
        if !controller.getMediaState().isScreenVideoActive {
            showRequestScreenShareAlert(requestor.name)
        }
        
    }
    
    func onFeatureStarted(_ featureRequest: SMFeatureRequestData) {
        if featureRequest.privilege == SMPermissionType.remotecontrol.rawValue {
            remoteControlButton.isHidden = false
            
        }
    }
    func onFeatureStopped(_ featureRequest: SMFeatureRequestData) {
        if featureRequest.privilege == SMPermissionType.remotecontrol.rawValue {
            remoteControlButton.isHidden = true
        }
    }
    
    func onUpdateActiveSpeakerItem(_ item: SMItem) {
        placeVideoView(activeSpeakerView, item, isActiveSpeaker: true)
        
        view.bringSubviewToFront(callControlsView)
        activeSpeakerView.bringSubviewToFront(activeSpeakerMicBackgroundView)
        activeSpeakerView.bringSubviewToFront(activeSpeakerNameLabelBackgroundView)
        
        updateActiveSpeakerMediaState(item.participant)
                
        updateCollectionViewLayoutForMinimizedState()
    }
    
    func onClearActiveSpeakerItem() {
        if let videoView = activeSpeakerView.subviews.first(where: { view in
            view as? SMVideoView != nil
        }) {
            (videoView as! SMVideoView).removeFromSuperview()
            (videoView as! SMVideoView).track.remove(videoView as! SMVideoView)
            (videoView as! SMVideoView).track = nil
        }
        
        activeSpeakerNameLabel.isHidden = true
        activeSpeakerMicBackgroundView.isHidden = true
        activeSpeakerNameLabelBackgroundView.isHidden = true
        activeSpeakerAvatarView.isHidden = true
    }
    
    func onReloadAllItems() {
        if !controller.hasActiveSpeaker() {
            updateCollectionViewLayoutForMaximizedState()
        }
        else {
            updateCollectionViewLayoutForMinimizedState()
        }
        participantsCollectionView.reloadData()
    }
    
    func onItemMediaStateChanged(_ index: Int, _ item: SMItem) {
        
        if let cell = participantsCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? RemoteParticipantCell {
            arrangeMediaState(cell, item.participant, index)
        }
    }
    
    func onActiveSpeakerMediaStateChanged(_ participant: SMParticipant) {
        updateActiveSpeakerMediaState(participant)
    }
    
    func onUpdateAudioButton(_ state: Bool) {
        micButton.isSelected = state
        micButton.backgroundColor = micButton.isSelected ? .screenMeetBrandColor : .lightGray
    }
    
    func onUpdateVideoButton(_ state: Bool) {
        cameraButton.isSelected = state
        cameraButton.backgroundColor = cameraButton.isSelected ? .screenMeetBrandColor : .lightGray
    }
    
    func onUpdateScreenSharingButton(_ state: Bool) {
        screenButton.isSelected = state
        screenButton.backgroundColor = screenButton.isSelected ? .screenMeetBrandColor : .lightGray
    }
    
    func onConnectionStateChanged(_ connectionState: SMConnectionState) {
        if connectionState == .reconnecting {
            showReconnectingState()
        }
        if connectionState == .connected  {
            showConnectedState()
        }
    }
    
    func onError(_ error: SMError) {
        if error.code == .permissionError {
            if error.message.lowercased().contains("microphone") {
                if micPermissionErrorButton.isHidden == false {
                    showGoToSettingsAlert(.audio)
                }
                
                checkAudioPermission()
            }
            else if error.message.lowercased().contains("video") {
                if cameraPermissionErrorButton.isHidden == false {
                    showGoToSettingsAlert(.video)
                }
                
                checkVideoPermission()
            }
        }
    }
    
    private typealias MediaAuthorization = (_ granted: Bool) -> Void
    
    private func authorize(_ type: AVMediaType, _ completion: @escaping MediaAuthorization) {
        switch AVCaptureDevice.authorizationStatus(for: type) {
            case .authorized:
                completion(true)
            
            case .notDetermined:
                completion(true)
            
            case .denied:
                completion(false)
                

            case .restricted:
                completion(false)
            
        @unknown default:
            break
        }
    }
    
}

extension CallViewController: UICollectionViewDelegateFlowLayout {
    
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - 30, height: collectionView.bounds.height / 3)
    }*/
}

extension CallViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewItem = collectionView.dequeueReusableCell(withReuseIdentifier: "RemoteParticipantCell", for: indexPath) as! RemoteParticipantCell
        
        if let item = controller.itemAt(indexPath.item) {
            arrangeRemoteVideo(collectionViewItem, item.participant, item)
            arrangeMediaState(collectionViewItem, item.participant, indexPath.item)
        }
        return collectionViewItem
    }
    
    private func arrangeRemoteVideo(_ cellItem: RemoteParticipantCell, _ participant: SMParticipant, _ item: SMItem) {
        
        let videoContainerView = cellItem.videoContainerView!
        placeVideoView(videoContainerView, item)
       
        cellItem.youAreSharingScreenOverlayView.isHidden = !(participant.isMe && item.info?.profile == "screen_share")
    }
    
    private func arrangeMediaState(_ cell: RemoteParticipantCell, _ participant: SMParticipant, _ indexOfCell: Int) {
        cell.micIcon.isHidden = !participant.avState.isAudioActive
        cell.micBackgroundView.isHidden = !participant.avState.isAudioActive
        cell.nameBackgroundLefMargin.constant = participant.avState.isAudioActive ? 24 : 0
        let shouldHide = participant.avState.isCameraVideoActive || participant.avState.isScreenVideoActive
        cell.logoImageView.isHidden = shouldHide
        
        cell.nameLabel.text = " \(participant.name) [\(indexOfCell)]"
        
        cell.micBackgroundView.backgroundColor = UIColor.screenMeetBrandColor
    }
    
    private func placeVideoView(_ videoContainerView: UIView, _ item: SMItem, isActiveSpeaker: Bool = false) {
        
        var myOwnScreenTrack = false
        
        if isActiveSpeaker && item.participant.isMe && item.info?.profile == "screen_share" {
            myOwnScreenTrack = true
        }
        
        if let existingVideoView = videoContainerView.subviews.first(where: { view in
            view as? SMVideoView != nil
        }) as? SMVideoView {
            if existingVideoView.track == item.track {
                // Do nothing
                return
            }
            else {
                existingVideoView.track?.remove(existingVideoView)
                existingVideoView.removeFromSuperview()
                existingVideoView.track = nil
            }
            activeSpeakerAvatarView.isHidden = true
        }
        
        if isActiveSpeaker {
            sharingOwnScreenView.isHidden = true
        }
        
        if item.track != nil && !myOwnScreenTrack {
            let videoView = SMVideoView()
            videoView.track = item.track
            videoView.info = item.info
            
            videoView.frame = videoContainerView.bounds
            videoView.translatesAutoresizingMaskIntoConstraints = false
            
            if item.info.profile.contains("screen"){
                videoView.videoContentMode = .scaleAspectFit
            }
            else {
                videoView.videoContentMode = .scaleAspectFill
            }
           
            
            item.track?.add(videoView)
            videoContainerView.addSubview(videoView)
            
            NSLayoutConstraint.activate([
                videoView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
                videoView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),
                videoView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
                videoView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor)
            ])
            activeSpeakerAvatarView.isHidden = true
        }
        else {
            if isActiveSpeaker {
                activeSpeakerAvatarView.isHidden = false
            }
            
            if myOwnScreenTrack {
                activeSpeakerAvatarView.isHidden = true
                sharingOwnScreenView.isHidden = false
            }
            
        }
    }
}

extension CallViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return controller.numberOItems()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

extension CallViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}



