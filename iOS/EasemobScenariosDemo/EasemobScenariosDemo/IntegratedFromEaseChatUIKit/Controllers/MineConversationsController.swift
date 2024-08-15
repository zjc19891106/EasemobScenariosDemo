//
//  MineConversationsController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/13.
//

import UIKit
import EaseChatUIKit

final class MineConversationsController: ConversationListController {
    
    lazy var background: UIImageView = {
        UIImageView(frame: self.view.bounds).contentMode(.scaleAspectFill).image(UIImage(named: "login_bg"))
    }()
    
    private lazy var limitCount: UILabel = {
        UILabel(frame: CGRect(x: 0, y: 13, width: 50, height: 22)).font(UIFont.theme.bodyLarge).text("0/20").textColor(Theme.style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor7)
    }()
    
    override func createSearchBar() -> UIButton {
        super.createSearchBar().cornerRadius(Appearance.avatarRadius)
    }
    
    override func createList() -> ConversationList {
        ConversationList(frame: CGRect(x: 7, y: self.search.frame.maxY+10, width: self.view.frame.width-14, height: self.view.frame.height-self.search.frame.maxY-10-(self.tabBarController?.tabBar.frame.height ?? 0)), style: .plain).cornerRadius(12)
    }
    
    private var limited = false
    
    private var customStatus = ""
    
    override func viewDidLoad() {
        self.view.addSubview(self.background)
        super.viewDidLoad()
        self.listenToUserStatus()
        self.showUserStatus()
        self.subscribeAllChatUsersStatus()
        self.navigation.rightItems.isHidden = true
        self.navigation.separateLine.isHidden = true
    }
    
    func subscribeAllChatUsersStatus() {
        let conversations = ChatClient.shared().chatManager?.getAllConversations() ?? []
        let ids = conversations.map { $0.conversationId ?? "" }
        for limitIds in self.splitIntoGroups(of: 100, array: ids) {
            PresenceManager.shared.subscribe(members: limitIds) { [weak self] presences, error in
                guard let `self` = self else { return }
                guard let visibleIndexPaths = self.conversationList.indexPathsForVisibleRows else { return }
                if RunLoop.current.currentMode != .tracking {
                    self.conversationList.beginUpdates()
                    self.conversationList.reloadRows(at: visibleIndexPaths, with: .automatic)
                    self.conversationList.endUpdates()
                }
            }
        }
    }
    
    func splitIntoGroups(of size: Int, array: [String]) -> [[String]] {
        return stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<min($0 + size, array.count)])
        }
    }
    
    override func switchTheme(style: ThemeStyle) {
        super.switchTheme(style: style)
        self.navigation.backgroundColor = .clear
        self.search.backgroundColor = UIColor.theme.neutralColor98
    }
    
    override func navigationClick(type: EaseChatNavigationBarClickEvent, indexPath: IndexPath?) {
        switch type {
        case .back: self.pop()
        case .rightItems: self.rightActions(indexPath: indexPath ?? IndexPath())
        default:
            break
        }
    }
    
    private func listenToUserStatus() {
        PresenceManager.shared.addHandler(handler: self)
    }
    
    private func showUserStatus() {
        if let presence = PresenceManager.shared.presences[EaseChatUIKitContext.shared?.currentUserId ?? ""] {
            let state = PresenceManager.status(with: presence)
            switch state {
            case .online:
                self.navigation.userState = .online
            case .offline:
                self.navigation.userState = .offline
            case .busy:
                self.navigation.status.image = nil
                self.navigation.status.backgroundColor = Theme.style == .dark ? UIColor.theme.errorColor5:UIColor.theme.errorColor6
            case .away:
                self.navigation.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
                self.navigation.status.image(PresenceManager.presenceImagesMap[.away] as? UIImage)
            case .doNotDisturb:
                self.navigation.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
                self.navigation.status.image(PresenceManager.presenceImagesMap[.doNotDisturb] as? UIImage)
            case .custom:
                self.navigation.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
                self.navigation.status.image(PresenceManager.presenceImagesMap[.custom] as? UIImage)
            }
            
        }
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigation.avatarURL = EaseChatUIKitContext.shared?.currentUser?.avatarURL
    }
    
    override func toChat(indexPath: IndexPath, info: ConversationInfo) {
        let vc = MineMessageListViewController(conversationId: info.id, chatType: info.type == .chat ? .chat:.group)
        vc.mute = info.doNotDisturb
        vc.modalPresentationStyle = .fullScreen
        ControllerStack.toDestination(vc: vc)
    }
    
}

extension MineConversationsController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.customStatus = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        if self.customStatus.count > 0 {
            self.limited = self.customStatus.count > 20
            self.limitCount.text = "\(self.customStatus.count)/20"
            if self.customStatus.count > 20 {
                self.limitCount.textColor = Theme.style == .dark ? UIColor.theme.errorColor5:UIColor.theme.errorColor6
            } else {
                self.limitCount.textColor = Theme.style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor7
            }
        } else {
            self.limitCount.text = "0/20"
        }
        return true
    }
}

extension MineConversationsController: PresenceDidChangedListener {
    func presenceStatusChanged(users: [String]) {
        self.showUserStatus()
        guard let visibleIndexPaths = self.conversationList.indexPathsForVisibleRows else { return }
        if RunLoop.current.currentMode != .tracking {
            self.conversationList.beginUpdates()
            self.conversationList.reloadRows(at: visibleIndexPaths, with: .automatic)
            self.conversationList.endUpdates()
        }
    }
    
    
}
