//
//  Users1v1ViewModel.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/6.
//

import UIKit
import EaseChatUIKit
import KakaJSON

@objc protocol Users1v1ChatViewModelListener: NSObjectProtocol {
    func receiveOtherMessage(message: [EaseChatUIKit.ChatMessage])
}

final class Users1v1ChatViewModel: NSObject {
    
    public private(set) weak var giftDriver: IGiftMessageListDrive?
    
    public private(set) weak var chatDriver: IMessageListDrive?
    
    public private(set) weak var bottomBarDriver: IBottomAreaToolBarDrive?
    
    public private(set) weak var inputDriver: Message1v1InputBar?
    
    public private(set) weak var giftAnimationDriver: IGiftAnimationEffectViewDriver?
    
    private var listeners: NSHashTable<Users1v1ChatViewModelListener> = NSHashTable<Users1v1ChatViewModelListener>.weakObjects()
    
    public private(set) var chatTo = ""

    
    public required init(with userId: String) {
        self.chatTo = userId
        super.init()
        
        ChatClient.shared().chatManager?.add(self, delegateQueue: nil)
    }
    
    func addListener(_ listener: Users1v1ChatViewModelListener) {
        if self.listeners.contains(listener) {
            return
        }
        self.listeners.add(listener)
    }
    
    func removeListener(_ listener: Users1v1ChatViewModelListener) {
        if self.listeners.contains(listener) {
            self.listeners.remove(listener)
        }
    }
    
    func bind(giftDriver: IGiftMessageListDrive) {
        self.giftDriver = giftDriver
        
    }
    
    func bind(chatDriver: IMessageListDrive) {
        self.chatDriver = chatDriver
    }
    
    func bind(bottomBarDriver: IBottomAreaToolBarDrive) {
        self.bottomBarDriver = bottomBarDriver
    }
    
    func bind(inputDriver: Message1v1InputBar) {
        self.inputDriver = inputDriver
        self.inputDriver?.sendClosure = { [weak self] in
            self?.sendMessage(text: $0)
        }
    }
    
    func bind(giftAnimationDriver: IGiftAnimationEffectViewDriver) {
        self.giftAnimationDriver = giftAnimationDriver
    }

    func refreshRTCToken() {
//        EasemobBusinessRequest.shared.sendGETRequest(api: .fetchRTCToken("", ""), params: [:]) { result, error in
//            if error == nil {
//                if let token = result?["token"] as? String {
//                    EaseMob1v1CallKit.shared.refreshToken(token: token)
//                } else {
//                    consoleLogInfo("Failed to fetch rtc token", type: .error)
//                }
//            }
//        }
    }
    
    func requestUserInfo(profileId: String) async -> EaseProfileProtocol? {
        let profiles = await EaseChatUIKitContext.shared?.userProfileProvider?.fetchProfiles(profileIds: [profileId]) ?? []
        return profiles.first
    }

    
    func sendMessage(text: String) {
        self.sendMessage(text: text) { [weak self] message, error in
            guard let `self` = self else { return }
            if error == nil,let message = message {
                self.chatDriver?.showNewMessage(message: message, gift: nil)
            } else {
                consoleLogInfo("Send message failure!\n\(error?.errorDescription ?? "")", type: .error)
            }
        }
    }
    
    func sendGift(gift: GiftEntityProtocol) {
        if !gift.giftEffect.isEmpty {
            self.giftAnimationDriver?.animation(with: gift)
        }
        self.sendGiftMessage(to: self.chatTo, eventType: EaseMob1v1ChatGift, infoMap: gift.toJsonObject()) { [weak self] message, error in
            if error == nil {
                self?.giftDriver?.receiveGift(gift: gift)
            } else {
                consoleLogInfo("sendGiftMessage error:\(error?.errorDescription ?? "")", type: .debug)
            }
        }
    }
    
}

extension Users1v1ChatViewModel: Chat1v1Service {
    
    func sendMessage(text: String, completion: @escaping (EaseChatUIKit.ChatMessage?, EaseChatUIKit.ChatError?) -> Void) {
        let json = EaseChatUIKitContext.shared?.currentUser?.toJsonObject()
        let message = ChatMessage(conversationID: self.chatTo, body: ChatTextMessageBody(text: text), ext: json)
        message.deliverOnlineOnly = true
        ChatClient.shared().chatManager?.send(message, progress: nil,completion: { message, error in
            completion(message, error)
        })
    }
    
    func sendGiftMessage(to userId: String, eventType: String, infoMap: [String : Any], completion: @escaping (ChatMessage?, EaseChatUIKit.ChatError?) -> Void) {
        var json = EaseChatUIKitContext.shared?.currentUser?.toJsonObject()
        json?.merge(infoMap) { _, new in
            new
        }
        let message = ChatMessage(conversationID: self.chatTo, body: ChatCMDMessageBody(action: EaseMob1v1ChatGift), ext: json)
        message.deliverOnlineOnly = true
        ChatClient.shared().chatManager?.send(message, progress: nil,completion: { message, error in
            completion(message, error)
        })
    }
    
    func translateMessage(message: EaseChatUIKit.ChatMessage, completion: @escaping (EaseChatUIKit.ChatMessage?, EaseChatUIKit.ChatError?) -> Void) {
        
    }
    
    func recall(messageId: String, completion: @escaping (EaseChatUIKit.ChatError?) -> Void) {
        
    }
    
    func report(messageId: String, tag: String, reason: String, completion: @escaping (EaseChatUIKit.ChatError?) -> Void) {
        
    }
    
    
}

extension Users1v1ChatViewModel: EaseChatUIKit.ChatEventsListener {
    
    func cmdMessagesDidReceive(_ aCmdMessages: [EaseChatUIKit.ChatMessage]) {
        for message in aCmdMessages {
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
            if let body = message.body as? ChatCMDMessageBody {
                if body.action == EaseMob1v1ChatGift,message.conversationId == self.chatTo {
                    if let giftJson = message.ext?[EaseMob1v1ChatGift] as? Dictionary<String,Any> {
                        let gift = model(from: giftJson, GiftEntity.self)
                        gift.sendUser = EaseChatUIKitContext.shared?.userCache?[message.from]
                        self.giftDriver?.receiveGift(gift: gift)
                        if !gift.giftEffect.isEmpty {
                            self.giftAnimationDriver?.animation(with: gift)
                        }
                    }
                }
            }
        }
    }
    
    func messagesDidReceive(_ aMessages: [EaseChatUIKit.ChatMessage]) {
        if self.chatTo != aMessages.first?.conversationId ?? "" {
            for message in aMessages {
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
            }
            for listener in self.listeners.allObjects {
                listener.receiveOtherMessage(message: aMessages)
            }
        } else {
            for message in aMessages {
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
                if self.chatTo == message.conversationId {
                    self.chatDriver?.showNewMessage(message: message, gift: nil)
                }
            }
        }
        
    }
}

extension Users1v1ChatViewModel {
    /// Constructor of ``ChatBottomFunctionBar`` data source.
    /// - Returns: Conform ``ChatBottomItemProtocol`` class instance array.
    func bottomBarDatas() -> [ChatBottomItemProtocol] {
        var entities = [ChatBottomItemProtocol]()
        let names = ["gift"]
        for i in 0...names.count-1 {
            let entity = ChatBottomItem()
            entity.showRedDot = false
            entity.selected = false
            entity.selectedImage = UIImage(named: "sendgift")
            entity.normalImage = UIImage(named: "sendgift")
            entity.type = i
            entities.append(entity)
        }
        return entities
    }
    
    /// Simulate fetch json from server .
    /// - Returns: Conform ``GiftEntityProtocol`` class instance.
    func gifts() -> [GiftEntityProtocol] {
        if let path = Bundle.main.url(forResource: "Gifts", withExtension: "json") {
            var data = Dictionary<String,Any>()
            do {
                data = try Data(contentsOf: path).chat.toDictionary() ?? [:]
            } catch {
                assert(false)
            }
            if let jsons = data["gifts"] as? [Dictionary<String,Any>] {
                return modelArray(from: jsons, GiftEntity.self)
            }
        }
        return []
    }
    
    final class ChatBottomItem:NSObject, ChatBottomItemProtocol {
        
        var action: ((ChatBottomItemProtocol) -> Void)?
        
        var showRedDot: Bool = false
        
        var selected: Bool = false
        
        var selectedImage: UIImage?
        
        var normalImage: UIImage?
        
        var type: Int = 0
       
    }
}

@objcMembers public class GiftEntity:NSObject,GiftEntityProtocol,Convertible {
    public var giftCount: Int = 1
    
    
    public func toJsonObject() -> Dictionary<String, Any> {
        [EaseMob1v1ChatGift:["giftId":self.giftId,"giftName":self.giftName,"giftPrice":self.giftPrice,"giftCount":self.giftCount,"giftIcon":self.giftIcon,"giftEffect":self.giftEffect]]
    }
    
    required public override init() {
        
    }
    
    public func kj_modelKey(from property: Property) -> ModelPropertyKey {
        property.name
    }
    
    public var giftId: String = ""
    
    public var giftName: String = ""
    
    public var giftName1: String = ""
    
    public var giftPrice: String = ""
    
    
    public var giftIcon: String = ""
    
    public var giftEffect: String = ""
    
    public var selected: Bool = false
    
    public var sentThenClose: Bool = true
    
    public var sendUser: EaseProfileProtocol?
    
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
}
