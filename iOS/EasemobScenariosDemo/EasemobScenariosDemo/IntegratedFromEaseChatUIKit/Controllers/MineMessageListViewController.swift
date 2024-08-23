//
//  MineMessageListViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/14.
//

import UIKit
import EaseChatUIKit
//import EaseCallKit
import Photos

let callIdentifier = "msgType"

let callValue = "rtcCallWithAgora"

final class MineMessageListViewController: MessageListController {
    
    @UserDefault("EaseChatUIKit_conversation_mute_map", defaultValue: Dictionary<String,Dictionary<String,Int>>()) public private(set) var muteMap
    
    private var otherPartyStatus = ""
    
    private var role = CallPopupView.CallRole.caller
    
    private var chatUserMatched = true {
        willSet {
            DispatchQueue.main.async {
                self.navigation.updateRightItems(images: self.rightImages(),original: true)
            }
        }
    }
    
    private var imageEntity = MessageEntity()
    
    var mute = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if self.chatType == .chat {
            self.subscribeUserStatus()
        }
        self.navigation.status.isHidden = self.chatType != .chat
        DispatchQueue.main.asyncAfter(wallDeadline: .now()+0.2) {
            self.setTitleAttribute(info: self.profile, doNotDisturb: self.mute)
        }
    }
    
    override func viewContact(body: ChatCustomMessageBody) {
        
    }
    
    override func messageAvatarClick(user: any EaseProfileProtocol) {
        
    }
    
    deinit {
        PresenceManager.shared.unsubscribe(members: [self.profile.id], completion: nil)
        EaseChatUIKitContext.shared?.cleanCache(type: .chat)
        URLPreviewManager.caches.removeAll()
    }
    
    @objc func subscribeUserStatus() {
        PresenceManager.shared.addHandler(handler: self)
        PresenceManager.shared.subscribe(members: [self.profile.id]) { [weak self] presences, error in
            if let presence = presences?.first {
                self?.showUserStatus(state: PresenceManager.status(with: presence))
            }
        }
    }
    
    override func performTypingTask() {
        if self.chatType == .chat {
            DispatchQueue.main.async {
                self.navigation.subtitle = self.otherPartyStatus
                self.navigation.title = self.navigation.title
            }
        }
    }
    
    private func showUserStatus(state: PresenceManager.State) {
        let subtitle = PresenceManager.showStatusMap[state] ?? ""
        switch state {
        case .online:
            self.navigation.userState = .online
            self.chatUserMatched = false
        case .offline:
            self.navigation.userState = .offline
            self.chatUserMatched = true
        case .busy:
            self.navigation.status.image = nil
            self.navigation.status.backgroundColor = Theme.style == .dark ? UIColor.theme.errorColor5:UIColor.theme.errorColor6
            self.chatUserMatched = true
        default: break
        }
        self.otherPartyStatus = subtitle
        self.navigation.subtitle = subtitle
        self.navigation.title = self.navigation.title

    }
    
    /**
     Updates the user state and sets it to the specified state.
     
     - Parameters:
        - state: The new user state.
     */
    @MainActor @objc public func updateUserState(state: UserState) {
        self.navigation.userState = state
    }
    
    override func rightImages() -> [UIImage] {
        if !self.chatUserMatched {
            [UIImage(named: "more_detail", in: .chatBundle, with: nil)!,UIImage(named: "video_enable")!]
        } else {
            [UIImage(named: "more_detail", in: .chatBundle, with: nil)!,UIImage(named: "video_disable")!]
        }
    }
    
    override func viewDetail() {
        
    }
    
    override func rightItemsAction(indexPath: IndexPath?) {
        guard let idx = indexPath else { return }
        switch idx.row {
        case 0: self.showConversationMenu()
        case 1: self.showCallMenu(role: .caller)
        default:
            break
        }
    }
    
    private func showConversationMenu() {
        DialogManager.shared.showActions(actions: self.filterConversationMenu()) { [weak self] item in
            self?.processConversationMenuItem(item: item)
        }
    }
    
    private func showCallMenu(role: CallPopupView.CallRole = .caller) {
        if self.chatUserMatched {
            return
        }
        self.role = role
        self.showCallView(role: role)
    }
    
    private func showCallView(role: CallPopupView.CallRole = .caller) {
        self.role = role
        self.requestCameraAndMicrophonePermissions { permission in
            if permission {
                EaseMob1v1CallKit.shared.currentUser.matchedChatUser = self.profile.id
                
                let call = CallAlertViewController(role: .caller, profile: self.profile)
                if role == .caller {
                    EaseMob1v1CallKit.shared.startCall()
                }
                self.presentViewController(call,animated: true)
            }
        }
        
    }
    
    func requestCameraAndMicrophonePermissions(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                // 如果摄像头权限被授予，则请求麦克风权限
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    private func processConversationMenuItem(item: ActionSheetItemProtocol) {
        switch item.tag {
        case "mute": self.muteConversation()
        case "unmute": self.unmuteConversation()
        case "pin": self.pinConversation()
        case "unpin": self.unpinConversation()
        case "clean": self.cleanConversation()
        case "delete": self.deleteConversation()
        default: break
        }
    }
    
    private func muteConversation() {
        self.setConversationSilentMode(silent: true)
    }
    
    private func unmuteConversation() {
        self.setConversationSilentMode(silent: false)
    }
    
    private func setConversationSilentMode(silent: Bool) {
        let params = SilentModeParam(paramType: .remindType)
        params.remindType = silent ? .none:.all
        ChatClient.shared().pushManager?.setSilentModeForConversation(self.profile.id, conversationType: .chat, params: params,completion: { [weak self] result, error in
            guard let `self` = self else { return }
            if error == nil {
                self.processSilentModeResult(silent: silent)
            } else {
                UIViewController.currentController?.showToast(toast: "Failed to mute conversation.")
            }
        })
    }
    
    private func processSilentModeResult(silent: Bool) {
        let currentUser = EaseChatUIKitContext.shared?.currentUserId ?? ""
        var conversationMap = self.muteMap[self.profile.id]
        if conversationMap != nil {
            conversationMap?[self.profile.id] = silent ? 1:0
        } else {
            conversationMap = [self.profile.id:silent ? 1:0]
        }
        self.mute = silent
        self.muteMap[currentUser] = conversationMap
        self.setTitleAttribute(info: self.profile, doNotDisturb: silent)
        NotificationCenter.default.post(name: Notification.Name(rawValue: disturb_change), object: nil,userInfo: ["id":self.profile.id,"value":silent])
    }
    
    private func pinConversation() {
        self.setConversationPinMode(pin: true)
    }
    
    private func unpinConversation() {
        self.setConversationPinMode(pin: false)
    }
    
    private func setConversationPinMode(pin: Bool) {
        ChatClient.shared().chatManager?.pinConversation(self.profile.id, isPinned: pin,completionBlock: { [weak self] error in
            if error == nil {
                self?.showToast(toast: "置顶会话成功")
            } else {
                self?.showToast(toast: "置顶会话失败，原因：\(error?.errorDescription ?? "")")
            }
        })
    }
    
    private func cleanConversation() {
        DialogManager.shared.showAlert(title: "group_details_button_clearchathistory".chat.localize, content: "", showCancel: true, showConfirm: true) { [weak self] _ in
            guard let `self` = self else { return }
            ChatClient.shared().chatManager?.getConversationWithConvId(self.profile.id)?.deleteAllMessages(nil)
            NotificationCenter.default.post(name: Notification.Name("EaseChatUIKit_clean_history_messages"), object: self.profile.id)
        }
    }
    
    private func deleteConversation() {
        DialogManager.shared.showAlert(title: "删除这个会话", content: "删除会话后无法恢复", showCancel: true, showConfirm: true) { [weak self] _ in
            guard let `self` = self else { return }
            ChatClient.shared().chatManager?.deleteConversation(self.profile.id, isDeleteMessages: true)
            self.pop()
        }
    }
    
    private func setTitleAttribute(info: EaseProfileProtocol,doNotDisturb: Bool) {
        var nickName = info.id
        if !info.nickname.isEmpty {
            nickName = info.nickname
        }
        if !info.remark.isEmpty {
            nickName = info.remark
        }
        let nameAttribute = NSMutableAttributedString {
            AttributedText(nickName).font(UIFont.theme.titleMedium).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1)
            
        }
        let image = UIImage(named: "bell_slash", in: .chatBundle, with: nil)
        if Theme.style == .dark {
            image?.withTintColor(UIColor.theme.neutralColor5)
        }
        if doNotDisturb {
            nameAttribute.append(NSAttributedString {
                ImageAttachment(image, bounds: CGRect(x: 0, y: -4, width: 18, height: 18))
            })
        }
        self.navigation.titleAttribute = nameAttribute
    }
    
    private func filterConversationMenu() -> [ActionSheetItemProtocol] {
        var items = [ActionSheetItemProtocol]()
        if self.muteMap[self.profile.id]?["mute"] == 1 || self.mute {
            items.append(ActionSheetItem(title: "取消静音", type: .normal, tag: "unmute"))
        } else {
            items.append(ActionSheetItem(title: "静音会话", type: .normal, tag: "mute"))
        }
        if let conversation = ChatClient.shared().chatManager?.getConversationWithConvId(self.profile.id),conversation.isPinned {
            items.append(ActionSheetItem(title: "取消置顶", type: .normal, tag: "unpin"))
        } else {
            items.append(ActionSheetItem(title: "置顶会话", type: .normal, tag: "pin"))
        }
        items.append(ActionSheetItem(title: "清空聊天记录".localized(), type: .normal, tag: "clean"))
        items.append(ActionSheetItem(title: "删除会话", type: .destructive, tag: "delete"))
        return items
    }
    
    override func filterMessageActions(message: MessageEntity) -> [ActionSheetItemProtocol] {
        if let ext = message.message.ext,let value = ext[callIdentifier] as? String,value == callValue {
            return [
                ActionSheetItem(title: "barrage_long_press_menu_delete".chat.localize, type: .normal,tag: "Delete",image: UIImage(named: "message_action_delete", in: .chatBundle, with: nil)),
                ActionSheetItem(title: "barrage_long_press_menu_multi_select".chat.localize, type: .normal,tag: "MultiSelect",image: UIImage(named: "message_action_multi_select", in: .chatBundle, with: nil)),
                ActionSheetItem(title: "barrage_long_press_menu_forward".chat.localize, type: .normal,tag: "Forward",image: UIImage(named: "message_action_forward", in: .chatBundle, with: nil))
            ]
        } else {
            return super.filterMessageActions(message: message)
        }
    }
    
    override func messageBubbleClicked(message: MessageEntity) {
        switch message.message.body.type {
        case .image:
            if let body = message.message.body as? ChatImageMessageBody {
                self.filePath = body.localPath
                self.viewImage(entity: message)
            }
        case .file,.video:
            if let body = message.message.body as? ChatFileMessageBody {
                self.filePath = body.localPath ?? ""
            }
            self.openFile()
        case .custom:
            if let body = message.message.body as? ChatCustomMessageBody,body.event == EaseChatUIKit_user_card_message {
                self.viewContact(body: body)
            }
            if let body = message.message.body as? ChatCustomMessageBody,body.event == EaseChatUIKit_alert_message {
                self.viewAlertDetail(message: message.message)
            }
        case .combine:
            self.viewHistoryMessages(entity: message)
        default:
            break
        }
    }
    
    func viewImage(entity: MessageEntity) {
        self.imageEntity = entity
        let preview = ImagePreviewController(with: self)
        preview.selectedIndex = 0
        preview.presentDuration = 0.3
        preview.dissmissDuration = 0.3
        self.present(preview, animated: true)
        
    }
}

extension MineMessageListViewController: ImageBrowserProtocol {
    func numberOfPhotos(with browser: ImagePreviewController) -> Int {
        1
    }
    
    func photo(of index: Int, with browser: ImagePreviewController) -> PreviewImage {
        if let row = self.messageContainer.messages.firstIndex(of: self.imageEntity),let cell = self.messageContainer.messageList.cellForRow(at: IndexPath(item: row, section: 0)) as? ImageMessageCell,let image = cell.content.image {
            return PreviewImage(image: image, originalView: cell.content)
        }
        return PreviewImage(image: UIImage())
    }
    
    func didLongPressPhoto(at index: Int, with browser: ImagePreviewController) {
        DialogManager.shared.showActions(actions: [ActionSheetItem(title: "Save Image".localized(), type: .normal, tag: "SaveImage",image: UIImage(named: "photo", in: .chatBundle, with: nil)),ActionSheetItem(title: "barrage_long_press_menu_forward".chat.localize, type: .normal,tag: "Forward",image: UIImage(named: "message_action_forward", in: .chatBundle, with: nil))]) { [weak self] item in
            guard let `self` = self else {return}
            switch item.tag {
            case "SaveImage": self.saveImageToAlbum()
            case "Forward": self.forwardMessage(message: self.imageEntity.message)
            default:break
            }
        }
    }
    
    func saveImageToAlbum() {
        if let row = self.messageContainer.messages.firstIndex(of: self.imageEntity),let cell = self.messageContainer.messageList.cellForRow(at: IndexPath(item: row, section: 0)) as? ImageMessageCell,let image = cell.content.image {
            // Check authorization status
            let status = PHPhotoLibrary.authorizationStatus()
            
            switch status {
            case .authorized,.limited:
                // Save the image if authorized
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            case .denied, .restricted:
                // Handle denied or restricted status
                DialogManager.shared.showAlert(title: "Access Limited", content: "Access to photo library is denied or restricted.", showCancel: true, showConfirm: true) { _ in
                    
                }
            case .notDetermined:
                // Request authorization
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        // Save the image if authorized
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    } else {
                        DialogManager.shared.showAlert(title: "Access Denied", content: "Access to photo library is denied.", showCancel: false, showConfirm: true) { _ in
                            
                        }
                    }
                }
            @unknown default:
                fatalError("Unknown authorization status")
            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // Handle the error
            UIViewController.currentController?.showToast(toast: "Failed to save image.\(error.localizedDescription)")
        } else {
            // Handle success
            UIViewController.currentController?.showToast(toast: "Failed to save image.")
        }
    }
}

extension MineMessageListViewController: PresenceDidChangedListener {
    func presenceStatusChanged(users: [String]) {
        if users.contains(self.profile.id), let presence = PresenceManager.shared.presences[self.profile.id] {
            self.showUserStatus(state: PresenceManager.status(with: presence))
        }
    }
    
    
}
