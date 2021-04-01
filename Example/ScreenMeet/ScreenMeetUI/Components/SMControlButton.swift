//
//  SMControlButton.swift
//  ScreenMeet
//
//  Created by Vasyl Morarash on 24.02.2021.
//

import UIKit

class SMControlButton: UIView {
    
    private var button: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.imageView?.backgroundColor = .clear
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10)
        button.clipsToBounds = true
        return button
    }()
    
    private var badgeBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private var badgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.layer.cornerRadius = button.frame.width / 2
    }
    
    override var backgroundColor: UIColor? {
        get {
            return button.backgroundColor
        }
        set {
            button.backgroundColor = newValue
        }
    }
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(button)
        addSubview(badgeBackgroundView)
        addSubview(badgeImageView)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: 24),
            badgeImageView.widthAnchor.constraint(equalTo: badgeImageView.heightAnchor),
            badgeImageView.topAnchor.constraint(equalTo: topAnchor, constant: -7),
            badgeImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 7),
            badgeBackgroundView.topAnchor.constraint(equalTo: badgeImageView.topAnchor, constant: 5),
            badgeBackgroundView.bottomAnchor.constraint(equalTo: badgeImageView.bottomAnchor, constant: -5),
            badgeBackgroundView.leadingAnchor.constraint(equalTo: badgeImageView.leadingAnchor, constant: 5),
            badgeBackgroundView.trailingAnchor.constraint(equalTo: badgeImageView.trailingAnchor, constant: -5),
            widthAnchor.constraint(equalTo: heightAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ image: UIImage?, for state: UIControl.State, color: UIColor? = nil) {
        button.setImage(image, for: .normal)
        
        if let color = color {
            button.tintColor = color
        }
    }
    
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }
    
    func setBadgeImage(_ image: UIImage?, color: UIColor? = nil, backgroundColor: UIColor? = nil) {
        badgeImageView.isHidden = image == nil
        badgeImageView.image = image
        badgeImageView.tintColor = color
        badgeBackgroundView.isHidden = image == nil || backgroundColor == nil
        badgeBackgroundView.backgroundColor = backgroundColor
    }
}
