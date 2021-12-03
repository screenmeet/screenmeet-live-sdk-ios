//
//  SMChatBubbleView.swift
//  ScreenMeet
//
//  Created by Ross on 20.08.2021.
//

import UIKit
import ScreenMeetSDK

protocol SMChatMessagesProtocol: AnyObject {
    func shouldRevealOrClose(_ translation: CGFloat)
    func shouldMove(_ translation: CGFloat)
}

class SMChatMessagesView: UIView, InputBarAccessoryViewDelegate {

    private var messages = [SMTextMessage]()
    
    private let chatDateformatter = DateFormatter()
    private let chatDateformatterFull = DateFormatter()
    
    private var shouldScrollToBottom = true
    private var lastKeyboardHeight: CGFloat = 0.0
    private var keyboardManager = KeyboardManager()
    
    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.register(SMRemoteVideoTableViewCell.self, forCellReuseIdentifier: "SMRemoteVideoTableViewCell")
        return tableView
    }()
    
    var inputBar: InputBarAccessoryView = {
        let inputBar = InputBarAccessoryView()
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        return inputBar
    }()
    
    weak var delegate: SMChatMessagesProtocol?
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = .systemBackground
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged(gesture:)))
        gesture.cancelsTouchesInView = true
        self.addGestureRecognizer(gesture)
        
        inputBar.delegate = self
        addSubview(inputBar)
        
        addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
        ])
        
        tableView.alwaysBounceVertical = true
        tableView.backgroundColor = .clear
        tableView.register(UINib(nibName: "TextMessageCell", bundle: nil), forCellReuseIdentifier: "TextMessageCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
        
        let barHeight: CGFloat = 55.0
        tableView.contentInset.bottom = barHeight
        tableView.verticalScrollIndicatorInsets.bottom = barHeight
        
        inputBar.inputTextView.keyboardType = .default
        inputBar.inputTextView.placeholderLabel.font = UIFont(name: "HelveticaNeue-Light", size: 15)
        // Binding the inputBar will set the needed callback actions to position the inputBar on top of the keyboard
        keyboardManager.bind(inputAccessoryView: inputBar)
        
        // Binding to the tableView will enabled interactive dismissal
        keyboardManager.bind(to: tableView)
        
        // Add some extra handling to manage content inset
        keyboardManager.on(event: .didChangeFrame) { [weak self] (notification) in
                 //self?.tableView.contentInset.bottom = barHeight + notification.endFrame.height
                 //self?.tableView.verticalScrollIndicatorInsets.bottom = barHeight + notification.endFrame.height
                 if self?.shouldScrollToBottom ?? false {
                     //self?.scrollToBottom()
                 }
                 self?.lastKeyboardHeight = notification.endFrame.height
        }.on(event: .didHide) { [weak self] _ in
                 self?.lastKeyboardHeight = 0.0
                 self?.updateBottomTableInset()
        }
        .on(event: .didShow) { [weak self] (notification) in
            if self?.shouldScrollToBottom ?? false {
                self?.scrollToBottom()
            }
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized))
        tap.cancelsTouchesInView = false
        self.addGestureRecognizer(tap)
        
        chatDateformatter.dateFormat = "HH:mm a"
        chatDateformatterFull.dateFormat = "MMM dd, HH:mm a"
        
        ScreenMeet.chatDelegate = self
    }
    
    func updateMessages() {
        messages = ScreenMeet.getChatMessages().sorted(by: { $0.createdOn.compare($1.createdOn) == .orderedAscending })
        tableView.reloadData()
    }
    
    func scrollToBottom(afterDelay: Bool = false, checkTheVeryBottom: Bool = false) {
            DispatchQueue.main.asyncAfter(deadline: .now() + (afterDelay ? 0.6 : 0)) { [weak self] in
                
                if let viewController = self {
                    let bottomOffset = CGPoint(x: 0, y: viewController.tableView.contentSize.height - viewController.tableView.bounds.size.height + viewController.tableView.contentInset.bottom)
                    if bottomOffset.y > 0 {
                        viewController.tableView.setContentOffset(bottomOffset, animated: true)
                        
                        /* This is needed because the rows height is .automatic so sometimes the bottom of the last row
                         is not yet visbile beacsue it's not resized yet*/
                        if checkTheVeryBottom {
                            self?.adjustScroll()
                        }
                    }
                }
            }
        }
        
        func adjustScroll() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                
                if let tableView = self?.tableView {
                    let rows = tableView.numberOfRows(inSection: 0)
                    
                    if rows > 0 {
                        let indexPath = NSIndexPath(row: rows-1, section: 0)
                        tableView.scrollToRow(at: indexPath as IndexPath, at: .none, animated: true)
                    }
                }
            }
        }
        
        func updateBottomTableInset() {
            DispatchQueue.main.asyncAfter(deadline: .now() +  0.2) { [weak self] in
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    let barHeight = self?.inputBar.bounds.height ?? 0
                    self?.tableView.contentInset.bottom = barHeight + (self?.lastKeyboardHeight ?? CGFloat(0.0))
                    self?.tableView.verticalScrollIndicatorInsets.bottom = barHeight + (self?.lastKeyboardHeight ?? CGFloat(0.0))
                }) { isCompleted in
                    //self?.scrollToBottom()
                }
            }
        }
    
    @objc func tapGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
           inputBar.inputTextView.resignFirstResponder()
       }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open var isInputBarHidden: Bool = false {
        didSet {
            isInputBarHiddenDidChange()
        }
    }

    /*
    open override var inputAccessoryView: UIView? {
        return isInputBarHidden ? nil : inputBar
    }*/

    open override var canBecomeFirstResponder: Bool {
        return !isInputBarHidden
    }

    /// Invoked when `isInputBarHidden` changes to become or
    /// resign first responder
    open func isInputBarHiddenDidChange() {
        if isInputBarHidden, isFirstResponder {
            resignFirstResponder()
        } else if !isFirstResponder {
            becomeFirstResponder()
        }
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        inputBar.inputTextView.resignFirstResponder()
        return super.resignFirstResponder()
    }
    
    @objc func wasDragged(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)

        if gesture.state == UIGestureRecognizer.State.began || gesture.state == UIGestureRecognizer.State.changed {
            delegate?.shouldMove(translation.x)
        }
        
        if gesture.state == UIGestureRecognizer.State.ended {
            delegate?.shouldRevealOrClose(translation.x)
        }
    }
    
    func dismissKeyboard() {
        inputBar.endEditing(true)
    }

    // MARK: - InputBarAccessoryViewDelegate

    open func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        ScreenMeet.sendTextMessage(text)
        inputBar.inputTextView.text = ""
    }

    open func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) { }

    open func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) { }

    open func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer) { }
    
    open func didPressCameraButton() {
        
    }
    open func didPressGalleryButton() {}
}

extension SMChatMessagesView: UITableViewDelegate {
    
}

extension SMChatMessagesView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextMessageCell", for: indexPath) as! TextMessageCell
        let message = messages[indexPath.row]
        let date = message.createdOn
        cell.messageLabel.text = message.text
        
        var isPreviousMessageAlmostSameTime = false
        var isPreviousMessageOfSameUser = false
        
        if indexPath.row > 0 {
            let previousMessage = messages[indexPath.row - 1]
            
            if (previousMessage.senderId == message.senderId) {
                isPreviousMessageOfSameUser = true
            }
            
            if (message.createdOn.timeIntervalSince1970 -  previousMessage.createdOn.timeIntervalSince1970 / (1000 * 60)  < 1) {
                isPreviousMessageAlmostSameTime = true
            }
        }
        
        let difference = date.timeIntervalSince1970 - Date().timeIntervalSince1970
        if (difference / (1000 * 60 * 60) > 24) {
            cell.dateLabel.text = "\(message.senderName), \(chatDateformatterFull.string(from: date))"
        }
        else {
            cell.dateLabel.text = "\(message.senderName), \(chatDateformatter.string(from: date))"
        }
        
        if (isPreviousMessageOfSameUser) {
            if isPreviousMessageAlmostSameTime {
                cell.dateLabelHeightConstraint.constant = 0
            }
            else {
                cell.dateLabelHeightConstraint.constant = 16
            }
        }
        else {
            cell.dateLabelHeightConstraint.constant = 16
        }
        
        cell.containerWidthConstraint.constant = 200
        return cell
    }
}

extension SMChatMessagesView: ScreenMeetChatDelegate {
    
    func onTextMessageReceived(_ message: SMTextMessage) {
        messages.append(message)
        tableView.insertRows(at: [IndexPath(row: messages.count-1, section: 0)], with: .none)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.scrollToBottom()
        }
    }
    
    func onMessageSendFailed(_ error: SMError) {
        NSLog("Could not send message")
    }
    
}


