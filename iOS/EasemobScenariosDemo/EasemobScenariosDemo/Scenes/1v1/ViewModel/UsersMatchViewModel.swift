//
//  UsersMatchViewModel.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/6.
//

import UIKit
import EaseChatUIKit
import KakaJSON

final class UsersMatchViewModel: NSObject {
    
    @UserDefault("EaseScenariosDemoPhone", defaultValue: "") private var phone
    
    public private(set) weak var userDriver: UserMatchView?
    
    var matchedUser = MatchUserInfo()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: Notification.Name(connectionSuccessful), object: nil, queue: .current) { [weak self] notification in
            DispatchQueue.main.asyncAfter(wallDeadline: .now()+2) {
                self?.matchUser()
            }
        }
        ChatClient.shared().chatManager?.add(self, delegateQueue: nil)
    }
    
    func bind(userDriver: UserMatchView) {
        self.userDriver = userDriver
    }

    func matchUser(completion: ((Error?) -> Void)? = nil) {
        EasemobBusinessRequest.shared.sendPOSTRequest(api: .matchUser(()), params: ["phoneNumber":self.phone]) { [weak self] result, error in
            guard let `self` = self else { return }
            if error == nil {
                if let json = result {
                    self.requestMatchedUserInfo(json: json)
                }
            } else {
                if let error = error as? EasemobError,completion == nil {
                    consoleLogInfo("matchUser Error: \(error.message ?? "")", type: .error)
                }
                
            }
            completion?(error)
        }
    }
    
    private func requestMatchedUserInfo(json: [String:Any],role: CallPopupView.CallRole = .caller) {
        let matchUser = model(from: json, MatchUserInfo.self)
        matchUser.id = EaseChatUIKitContext.shared?.currentUserId ?? ""
        Task {
            let profiles = await EaseChatUIKitContext.shared?.userProfileProvider?.fetchProfiles(profileIds: [matchUser.id]) ?? []
            if let profile = profiles.first {
                matchUser.nickname = profile.nickname
                matchUser.avatarURL = profile.avatarURL
            }
            self.matchedUser = matchUser
            EaseMob1v1CallKit.shared.currentUser = self.matchedUser
            DispatchQueue.main.async {
                self.userDriver?.isHidden = false
                self.userDriver?.refresh(profile: self.matchedUser)
            }
        }
    }
}

extension UsersMatchViewModel: EaseChatUIKit.ChatEventsListener {
    func cmdMessagesDidReceive(_ aCmdMessages: [EaseChatUIKit.ChatMessage]) {
        for message in aCmdMessages {
            if let body = message.body as? ChatCMDMessageBody {
                if message.from == "admin",body.action == EaseMob1v1SomeUserMatchedYou {
                    if let dic = message.ext?["ease_chat_uikit_user_info"] as? Dictionary<String,Any> {
                        let profile = EaseProfile()
                        profile.setValuesForKeys(dic)
                        profile.id = message.from
                        profile.modifyTime = message.timestamp
                        EaseChatUIKitContext.shared?.chatCache?[message.from] = profile
                        if EaseChatUIKitContext.shared?.userCache?[message.from] == nil {
                            EaseChatUIKitContext.shared?.userCache?[message.from] = profile
                        } else {
                            EaseChatUIKitContext.shared?.userCache?[message.from]?.nickname = profile.nickname
                            EaseChatUIKitContext.shared?.userCache?[message.from]?.avatarURL = profile.avatarURL
                        }
                    }
                    if let json = message.ext as? [String:Any] {
                        self.requestMatchedUserInfo(json: json)
                    }
                    
                }
            }
        }
    }
}


class MatchUserInfo:NSObject, EaseProfileProtocol, Convertible {
    
    var id: String = ""
    
    var remark: String = ""
    
    var selected: Bool = false
    
    var nickname: String = ""
    
    var avatarURL: String = ""
    
    var rtcToken: String = ""
    
    var matchedUser: String = ""
    
    var matchedChatUser: String = ""
    
    var agoraUid: String = ""
    
    var channelName: String = ""
    
    func toJsonObject() -> Dictionary<String, Any>? {
        [:]
    }
    
    required override init() {
        
    }
    
    public func kj_modelKey(from property: Property) -> ModelPropertyKey {
        property.name
    }
}
