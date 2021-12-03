//
//  FDTakeController.swift
//  FDTake
//
//  Copyright © 2015 William Entriken. All rights reserved.
//

import Foundation
import MobileCoreServices
import UIKit
import Photos

/// A class for selecting and taking photos
open class FDTakeController: NSObject {

    // MARK: - Initializers & Class Convenience Methods

    /// Convenience method for getting a photo
    open class func getPhotoWithCallback(getPhotoWithCallback callback: @escaping (_ photo: UIImage, _ info: [AnyHashable: Any]) -> Void) {
        let fdTake = FDTakeController()
        fdTake.allowsVideo = false
        fdTake.didGetPhoto = callback
        fdTake.present()
    }

    /// Convenience method for getting a video
    open class func getVideoWithCallback(getVideoWithCallback callback: @escaping (_ video: URL, _ info: [AnyHashable: Any]) -> Void) {
        let fdTake = FDTakeController()
        fdTake.allowsPhoto = false
        fdTake.didGetVideo = callback
        fdTake.present()
    }


    // MARK: - Configuration options

    /// Whether to allow selecting a photo
    open var allowsPhoto = true

    /// Whether to allow selecting a video
    open var allowsVideo = false

    /// Whether to allow capturing a photo/video with the camera
    open var allowsTake = true

    /// Whether to allow selecting existing media
    open var allowsSelectFromLibrary = false

    /// Whether to allow editing the media after capturing/selection
    open var allowsEditing = false

    /// Whether to use full screen camera preview on the iPad
    open var iPadUsesFullScreenCamera = false

    /// Enable selfie mode by default
    open var defaultsToFrontCamera = false

    /// The UIBarButtonItem to present from (may be replaced by overloaded methods)
    open var presentingBarButtonItem: UIBarButtonItem? = nil

    /// The UIView to present from (may be replaced by overloaded methods)
    open var presentingView: UIView? = nil

    /// The UIRect to present from (may be replaced by overloaded methods)
    open var presentingRect: CGRect? = nil

    /// The UITabBar to present from (may be replaced by overloaded methods)
    open var presentingTabBar: UITabBar? = nil

    /// The UIViewController to present from (may be replaced by overloaded methods)
    open lazy var presentingViewController: UIViewController = {
        return UIApplication.shared.windows.first!.rootViewController!
    }()


    // MARK: - Callbacks

    /// A photo was selected
    open var didGetPhoto: ((_ photo: UIImage, _ info: [AnyHashable: Any]) -> Void)?

    /// A video was selected
    open var didGetVideo: ((_ video: URL, _ info: [AnyHashable: Any]) -> Void)?
    
    // Last media fetched
    open var didGetLastMedia: ((PHAsset?) -> Void)?

    /// The user did not attempt to select a photo
    open var didDeny: (() -> Void)?

    /// The user started selecting a photo or took a photo and then hit cancel
    open var didCancel: (() -> Void)?

    /// A photo or video was selected but the ImagePicker had NIL for EditedImage and OriginalImage
    open var didFail: (() -> Void)?


    // MARK: - Localization overrides
    
    /// Custom UI text (skips localization)
    open var cancelText: String? = nil
    
    /// Custom UI text (skips localization)
    open var chooseFromLibraryText: String? = nil
    
    /// Custom UI text (skips localization)
    open var chooseFromPhotoRollText: String? = nil
    
    /// Custom UI text (skips localization)
    open var noSourcesText: String? = nil

    /// Custom UI text (skips localization)
    open var takePhotoText: String? = nil

    /// Custom UI text (skips localization)
    open var takeVideoText: String? = nil

    /// Custom UI text (skips localization)
    open var lastVideoOrPhoto: String? = nil


    // MARK: - Private

    private lazy var imagePicker: UIImagePickerController = {
        [unowned self] in
        let retval = UIImagePickerController()
        retval.delegate = self
        retval.allowsEditing = true
        return retval
        }()

    private var alertController: UIAlertController? = nil

    // This is a hack required on iPad if you want to select a photo and you already have a popup on the screen
    // see: https://stackoverflow.com/a/35209728/300224
    private func topViewController(rootViewController: UIViewController) -> UIViewController {
        var rootViewController = UIApplication.shared.windows.first!.rootViewController!
        repeat {
            guard let presentedViewController = rootViewController.presentedViewController else {
                return rootViewController
            }
            
            if let navigationController = rootViewController.presentedViewController as? UINavigationController {
                rootViewController = navigationController.topViewController ?? navigationController
                
            } else {
                rootViewController = presentedViewController
            }
        } while true
    }

    private func fetchLatestMedia() -> PHAsset? {
        var asset: PHAsset?
        let options = PHFetchOptions()
        options.includeAssetSourceTypes = .typeUserLibrary
        PHAsset.fetchAssets(with: options).enumerateObjects(options: .concurrent) { (assetReturned, _, _) in
            asset = assetReturned
        }
        return asset
    }
    // MARK: - Localization

    private func localizedString(for string: FDTakeControllerLocalizableStrings) -> String {
        let bundleLocalization = string.localizedString
        
        switch string {
        case .cancel:
            return self.cancelText ?? bundleLocalization
        case .chooseFromLibrary:
            return self.chooseFromLibraryText ?? bundleLocalization
        case .chooseFromPhotoRoll:
            return self.chooseFromPhotoRollText ?? bundleLocalization
        case .noSources:
            return self.noSourcesText ?? bundleLocalization
        case .takePhoto:
            return self.takePhotoText ?? bundleLocalization
        case .takeVideo:
            return self.takeVideoText ?? bundleLocalization
        case .lastTakenMedia:
            return self.lastVideoOrPhoto ?? bundleLocalization
        }
    }

    
    /// Presents the user with an option to take a photo or choose a photo from the library
    open func present() {
        //TODO: maybe encapsulate source selection?
        var titleToSource = [(buttonTitle: FDTakeControllerLocalizableStrings, source: UIImagePickerController.SourceType)]()

        if self.allowsTake && UIImagePickerController.isSourceTypeAvailable(.camera) {
            if self.allowsPhoto {
                titleToSource.append((buttonTitle: .takePhoto, source: .camera))
            }
            if self.allowsVideo {
                titleToSource.append((buttonTitle: .takeVideo, source: .camera))
            }
        }
        if self.allowsSelectFromLibrary {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                titleToSource.append((buttonTitle: .chooseFromLibrary, source: .photoLibrary))
                titleToSource.append((buttonTitle: .lastTakenMedia, source: .photoLibrary))
            } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                titleToSource.append((buttonTitle: .chooseFromPhotoRoll, source: .savedPhotosAlbum))
            }
        }

        guard titleToSource.count > 0 else {
            let str = localizedString(for: .noSources)

            //TODO: Encapsulate this
            //TODO: There has got to be a better way to do this
            let alert = UIAlertController(title: nil, message: str, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: localizedString(for: .cancel), style: .default, handler: nil))

            // http://stackoverflow.com/a/34487871/300224
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.rootViewController = UIViewController()
            alertWindow.windowLevel = UIWindow.Level.alert + 1;
            alertWindow.makeKeyAndVisible()
            alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
            return
        }

        var popOverPresentRect : CGRect = self.presentingRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        if popOverPresentRect.size.height == 0 || popOverPresentRect.size.width == 0 {
            popOverPresentRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        }

        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for (title, _) in titleToSource {
            
            var image: UIImage? = nil
            
            if title == .takePhoto {
                if #available(iOS 13.0, *) {
                    image = UIImage(systemName: "photo")
                } else {
                    // Fallback on earlier versions
                }
            }
            if title == .takeVideo {
                if #available(iOS 13.0, *) {
                    image = UIImage(systemName: "film")
                } else {
                    // Fallback on earlier versions
                }
            }
            
            print("Present \(image != nil)")
            
            
            /*let action = UIAlertAction(title: localizedString(for: title), style: .default) {
                (UIAlertAction) -> Void in
                
                
               
            }*/
            
            //action.setValue(image?.withRenderingMode(.alwaysOriginal), forKey: "image")
            //alertController!.addAction(action)
        }
        let cancelAction = UIAlertAction(title: localizedString(for: .cancel), style: .default) {
            (UIAlertAction) -> Void in
            self.didCancel?()
        }
        alertController!.addAction(cancelAction)

        let topVC = topViewController(rootViewController: presentingViewController)

        alertController?.modalPresentationStyle = .popover
        if let presenter = alertController!.popoverPresentationController {
            presenter.sourceView = presentingView;
            if let presentingRect = self.presentingRect {
                presenter.sourceRect = presentingRect
            }
            //WARNING: on ipad this fails if no SOURCEVIEW AND SOURCE RECT is provided
        }
        if let popoverPresentationController = alertController!.popoverPresentationController {
              popoverPresentationController.sourceView = topVC.view
              popoverPresentationController.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
              popoverPresentationController.permittedArrowDirections = []
            }
        
        //topVC.present(alertController!, animated: true, completion: nil)
        
        let title: FDTakeControllerLocalizableStrings = .takePhoto
        let source: UIImagePickerController.SourceType = .camera
        showOnlyPhoto(localizedString(for: title), source)
    }

    /// Dismisses the displayed view. Especially handy if the sheet is displayed while suspending the app,
    open func dismiss() {
        alertController?.dismiss(animated: true, completion: nil)
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    private func showOnlyPhoto(_ title: String, _ source: UIImagePickerController.SourceType) {
        self.imagePicker.sourceType = source
        if source == .camera && self.defaultsToFrontCamera && UIImagePickerController.isCameraDeviceAvailable(.front) {
            self.imagePicker.cameraDevice = .front
        }
        // set the media type: photo or video
        self.imagePicker.allowsEditing = self.allowsEditing
        var mediaTypes = [String]()
        if self.allowsPhoto {
            mediaTypes.append(String(kUTTypeImage))
        }
        if self.allowsVideo {
            mediaTypes.append(String(kUTTypeMovie))
        }
        self.imagePicker.mediaTypes = mediaTypes

        //TODO: Need to encapsulate popover code
        var popOverPresentRect: CGRect = self.presentingRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        if popOverPresentRect.size.height == 0 || popOverPresentRect.size.width == 0 {
            popOverPresentRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        let topVC = self.topViewController(rootViewController: self.presentingViewController)
        
        if UIDevice.current.userInterfaceIdiom == .phone || (source == .camera && self.iPadUsesFullScreenCamera) {
            topVC.present(self.imagePicker, animated: true, completion: nil)
        } else {
            // On iPad use pop-overs.
            self.imagePicker.modalPresentationStyle = .fullScreen
            self.imagePicker.popoverPresentationController?.sourceRect = popOverPresentRect
            
            
            
            
            self.imagePicker.popoverPresentationController?.sourceView = topVC.view
           // self.imagePicker.popoverPresentationController?.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            
            topVC.present(self.imagePicker, animated: true, completion: nil)
        }
    }
}

extension FDTakeController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        switch info[.mediaType] as! CFString {
        case kUTTypeImage:
            let imageToSave: UIImage
            if let editedImage = info[.editedImage] as? UIImage {
                imageToSave = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                imageToSave = originalImage
            } else {
                self.didCancel?()
                return
            }
            self.didGetPhoto?(imageToSave, info)
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.imagePicker.dismiss(animated: true)
            }
        case kUTTypeMovie:
             self.didGetVideo?(info[.mediaURL] as! URL, info)
        default:
            break
        }

        picker.dismiss(animated: true, completion: nil)
    }

    /// Conformance for image picker delegate
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        self.didDeny?()
    }
}

