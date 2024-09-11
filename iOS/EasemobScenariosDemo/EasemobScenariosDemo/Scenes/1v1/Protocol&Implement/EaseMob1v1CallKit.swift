//
//  EaseMob1v1CallKit.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/6.
//

import Foundation
import AgoraRtcKit
import EaseChatUIKit
import KakaJSON

let endCallInsertMessageNeededReload = "endCallInsertMessageNeededReload"

final class EaseMob1v1CallKit: NSObject {
    
    static let shared = EaseMob1v1CallKit()
    
    public private(set) var agoraKit: AgoraRtcEngineKit?
    
    private var handlers: NSMapTable<NSString,EaseMobCallKit.CallListener> = NSMapTable<NSString, EaseMobCallKit.CallListener>.strongToWeakObjects()
    
    @UserDefault("EaseScenariosDemoPhone", defaultValue: "") private var phone
    
    private var callId = ""
    
    private var remoteUid: UInt = 0
    
    private var localUid: UInt = 0
    
    public var currentUser = MatchUserInfo()
    
    public var onCalling = false
    
    override init() {
        super.init()
        
        ChatClient.shared().chatManager?.add(self, delegateQueue: nil)
    }
    
    func prepareEngine() {
        if self.agoraKit != nil {
            return
        }
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: AgoraAppId, delegate: self)
        self.agoraKit?.setChannelProfile(.liveBroadcasting)
        self.agoraKit?.setClientRole(.broadcaster)
        self.agoraKit?.enableAudioVolumeIndication(500, smooth: 5, reportVad: false)
    }
    
    func renderLocalCanvas(with view: UIView) {
        self.onCalling = true
        self.agoraKit?.enableVideo()
        self.agoraKit?.setupLocalVideo(self.createCanvas(with: view, agoraUserId: self.localUid))
        self.agoraKit?.startPreview()
    }
    
    func renderRemoteCanvas(with view: UIView) {
        let code = self.agoraKit?.setupRemoteVideo(self.createCanvas(with: view, agoraUserId: self.remoteUid))
        consoleLogInfo("rtc renderRemoteCanvas error:\(code ?? -1)", type: .debug)
    }
    
    func createCanvas(with view: UIView,agoraUserId: UInt) -> AgoraRtcVideoCanvas {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = agoraUserId
        videoCanvas.view = view
        videoCanvas.renderMode = .hidden
        return videoCanvas
    }
    
    func hangup() {
        self.agoraKit?.stopPreview()
        self.agoraKit?.disableAudio()
        self.agoraKit?.disableVideo()
        self.agoraKit?.leaveChannel()
        AgoraRtcEngineKit.destroy()
        self.agoraKit = nil
        PresenceManager.shared.publishPresence(description: "") { error in
            consoleLogInfo("publishPresence error:\(error?.errorDescription ?? "")", type: .error)
        }
    }
    
    func joinChannel(success: @escaping () -> Void) {
        let code = self.agoraKit?.joinChannel(byToken: self.currentUser.rtcToken, channelId: self.currentUser.channelName, info: "", uid: UInt(self.currentUser.agoraUid) ?? 0,joinSuccess: { channelName, uid, elapsed in
            success()
        } )
        if code != 0 {
            consoleLogInfo("rtc joinChannel error:\(code ?? -1)", type: .debug)
        }
    }
    
    /// Add a listener to the call.``CallListener``
    /// - Parameter listener: The listener object confirm to``CallListener``
    func addListener(listener: EaseMobCallKit.CallListener) {
        self.handlers.setObject(listener, forKey: listener.description as NSString)
    }
    
    /// Remove a listener from the call.``CallListener
    /// - Parameter listener: The listener object confirm to``CallListener``
    func removeListener(listener: EaseMobCallKit.CallListener) {
        self.handlers.removeObject(forKey: listener.description as NSString)
        EaseMob1v1CallKit.shared.hangup()
    }
    
    /// Refresh rtc token.
    /// - Parameter token: rtc token
    func refreshToken(token: String) {
        self.agoraKit?.renewToken(token)
    }
}

extension EaseMob1v1CallKit: EaseMobCallKit.CallProtocol {
    
    func startCall() {
        self.prepareEngine()
        self.callId = (Date().timeIntervalSince1970*1000).description
        var ext: [String:Any] = ["EaseMob1v1CallKit1v1Invite":EaseMob1v1CallKit1v1Invite,"msgType":EaseMob1v1CallKit1v1Signaling,"EaseMob1v1CallKitCallId":self.callId]
        let json = EaseChatUIKitContext.shared?.currentUser?.toJsonObject() ?? [:]
        ext.merge(json) { _, new in
            new
        }
        let body = ChatTextMessageBody(text: "邀请您进行1v1通话")
        let message = ChatMessage(conversationID: self.currentUser.matchedChatUser, body: body, ext: ext)
        message.deliverOnlineOnly = true
        ChatClient.shared().chatManager?.send(message, progress: nil, completion: { (message, error) in
            
        })
    }
    
    func endCall( reason: String) {
        self.onCalling = false
        var ext: [String:Any] = ["EaseMob1v1CallKit1v1Signaling":EaseMob1v1CallKit1v1Signaling,"EaseMob1v1CallKitCallId":self.callId,"endCallReason":reason]
        let json = EaseChatUIKitContext.shared?.currentUser?.toJsonObject() ?? [:]
        ext.merge(json) { _, new in
            new
        }
        let body = ChatCMDMessageBody(action: EaseMob1v1CallKit1v1End)
        let message = ChatMessage(conversationID: self.currentUser.matchedChatUser, body: body, ext: ext)
        message.deliverOnlineOnly = true
        ChatClient.shared().chatManager?.send(message, progress: nil, completion: { [weak self] (message, error) in
            guard let `self` = self else { return }
            self.insertEndMessage(conversationId: self.currentUser.matchedChatUser)
        })
        self.hangup()
        
    }
    
    func cancelMatch() {
        EasemobBusinessRequest.shared.sendDELETERequest(api: .cancelMatch(self.phone), params: [:]) { [weak self] result, error in
            guard let `self` = self else { return }
            if error == nil {
                for key in self.handlers.keyEnumerator().allObjects {
                    if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                        listener.onCallStatusChanged(status: .idle, reason: "Cancel match")
                    }
                }
            }
        }
    }
    
    func cancelMatchNotify() {
        let message = ChatMessage(conversationID: self.currentUser.matchedChatUser, body: ChatCMDMessageBody(action: EaseMob1v1SomeUserMatchCanceled), ext: nil)
        message.deliverOnlineOnly = true
        ChatClient.shared().chatManager?.send(message, progress: nil)
    }
    
    func acceptCall() {
        self.prepareEngine()
        var ext: [String:Any] = ["EaseMob1v1CallKit1v1Signaling":EaseMob1v1CallKit1v1Signaling,"EaseMob1v1CallKitCallId":self.callId]
        let json = EaseChatUIKitContext.shared?.currentUser?.toJsonObject() ?? [:]
        ext.merge(json) { _, new in
            new
        }
        let body = ChatCMDMessageBody(action: EaseMob1v1CallKit1v1Accept)
        let message = ChatMessage(conversationID: self.currentUser.matchedChatUser, body: body, ext: ext)
        message.deliverOnlineOnly = true
        ChatClient.shared().chatManager?.send(message, progress: nil, completion: { [weak self] (message, error) in
            guard let `self` = self else { return }
            for key in self.handlers.keyEnumerator().allObjects {
                if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                    listener.onCallStatusChanged(status: .join, reason: self.currentUser.matchedChatUser)
                }
            }
        })
    }
    
    func insertEndMessage(conversationId: String) {
        if !self.callId.isEmpty {
            self.callId = ""
            let message = ChatMessage(conversationID: conversationId, body: ChatTextMessageBody(text: "1v1通话已结束"), ext: nil)
            ChatClient.shared().chatManager?.getConversationWithConvId(conversationId)?.insert(message, error: nil)
            NotificationCenter.default.post(name: NSNotification.Name(endCallInsertMessageNeededReload), object: self)
        }
    }
    
}

extension EaseMob1v1CallKit: EaseChatUIKit.ChatEventsListener {
    
    func cmdMessagesDidReceive(_ aCmdMessages: [EaseChatUIKit.ChatMessage]) {
        for message in aCmdMessages {
            if let dic = message.ext?["ease_chat_uikit_user_info"] as? Dictionary<String,Any> {
                let profile = EaseProfile()
                profile.setValuesForKeys(dic)
                profile.id = message.from
                profile.modifyTime = message.timestamp
                EaseChatUIKitContext.shared?.chatCache?[message.from] = profile
                EaseChatUIKitContext.shared?.userCache?[message.from] = profile
            }
            if let body = message.body as? ChatCMDMessageBody,message.to == ChatClient.shared().currentUsername ?? "" {
                if message.from == "admin" {
                    if body.action == EaseMob1v1SomeUserMatchedYou {
                        if let json = message.ext as? [String:Any] {
                            let matchedUser = model(from: json, MatchUserInfo.self)
                            self.localUid = UInt(matchedUser.agoraUid) ?? 0
                            self.currentUser = matchedUser
                            self.currentUser.id = EaseChatUIKitContext.shared?.currentUserId ?? ""
                            self.requestUserInfo()
                        }
                        self.prepareEngine()
                        for key in self.handlers.keyEnumerator().allObjects {
                            if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                                listener.onCallStatusChanged(status: .preparing, reason: "Call You")
                            }
                        }
                    }
                    if body.action == EaseMob1v1SomeUserMatchCanceled {
                        guard let userId = message.ext?["matchedChatUser"] as? String else { return }
                        let user = EaseChatUIKitContext.shared?.userCache?[userId]
                        let nickname = user?.nickname ?? "匿名用户-\(userId)"
                        for key in self.handlers.keyEnumerator().allObjects {
                            if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                                if self.currentUser.matchedChatUser.isEmpty {
                                    return
                                }
                                listener.onCallStatusChanged(status: .idle, reason: "\(nickname)取消配对")
                                self.currentUser.matchedChatUser = ""
                            }
                        }
                    }
                } else {
                    if body.action == EaseMob1v1SomeUserMatchCanceled {
                        let user = EaseChatUIKitContext.shared?.userCache?[message.from]
                        let nickname = user?.nickname ?? "匿名用户-\(message.from)"
                        for key in self.handlers.keyEnumerator().allObjects {
                            if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                                if self.currentUser.matchedChatUser.isEmpty {
                                    return
                                }
                                listener.onCallStatusChanged(status: .idle, reason: "\(nickname)取消配对")
                                self.currentUser.matchedChatUser = ""
                            }
                        }
                    }
                    if body.action == EaseMob1v1CallKit1v1End {
                        if let reason = message.ext?["endCallReason"] as? String {
                            self.insertEndMessage(conversationId: message.conversationId)
                            for key in self.handlers.keyEnumerator().allObjects {
                                if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                                    listener.onCallStatusChanged(status: .ended, reason: reason)
                                    self.onCalling = false
                                }
                            }
                        }
                    } else if body.action == EaseMob1v1CallKit1v1Accept {
                        self.prepareEngine()
                        for key in self.handlers.keyEnumerator().allObjects {
                            if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                                listener.onCallStatusChanged(status: .join, reason: message.conversationId)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func messagesDidReceive(_ aMessages: [EaseChatUIKit.ChatMessage]) {
        
        for message in aMessages {
            if let dic = message.ext?["ease_chat_uikit_user_info"] as? Dictionary<String,Any> {
                let profile = EaseProfile()
                profile.setValuesForKeys(dic)
                profile.id = message.from
                profile.modifyTime = message.timestamp
                EaseChatUIKitContext.shared?.chatCache?[message.from] = profile
                EaseChatUIKitContext.shared?.userCache?[message.from] = profile
            }
            if message.to == ChatClient.shared().currentUsername ?? ""  {
                if let inviteCallId = message.ext?["EaseMob1v1CallKitCallId"] as? String,let inviteKey = message.ext?[EaseMob1v1CallKit1v1Invite] as? String,inviteKey == EaseMob1v1CallKit1v1Invite {
                    if let json = message.ext as? [String:Any],let user = EaseChatUIKitContext.shared?.userCache?[message.from] {
                        let matchedUser = MatchUserInfo()
                        matchedUser.id = EaseChatUIKitContext.shared?.currentUserId ?? ""
                        matchedUser.avatarURL = user.avatarURL
                        matchedUser.matchedChatUser = message.from
                        matchedUser.matchedUser = user.nickname
                        self.localUid = UInt(matchedUser.agoraUid) ?? 0
                        self.currentUser.avatarURL = matchedUser.avatarURL
                        self.currentUser.nickname = matchedUser.nickname
                        self.currentUser.matchedChatUser = matchedUser.matchedChatUser
                    }
                    self.prepareEngine()
                    if self.callId.isEmpty {
                        self.callId = inviteCallId
                        for key in self.handlers.keyEnumerator().allObjects {
                            if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                                listener.onCallStatusChanged(status: .alert, reason: message.conversationId)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func requestUserInfo() {
        Task {
            let profiles = await EaseChatUIKitContext.shared?.userProfileProvider?.fetchProfiles(profileIds: [self.currentUser.matchedChatUser]) ?? []
            let userId = self.currentUser.matchedChatUser
            let profile = profiles.first
            if let user = EaseChatUIKitContext.shared?.userCache?[self.currentUser.matchedChatUser] {
                user.nickname = profile?.nickname ?? userId
                user.avatarURL = profile?.avatarURL ?? ""
            } else {
                let user = EaseChatProfile()
                user.id = userId
                user.nickname = profile?.nickname ?? userId
                user.avatarURL = profile?.avatarURL ?? ""
                EaseChatUIKitContext.shared?.userCache?[userId] = user
            }
            for key in self.handlers.keyEnumerator().allObjects {
                if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                    listener.onCallStatusChanged(status: .preparing, reason: "Call You")
                }
            }
        }
    }
}

extension EaseMob1v1CallKit: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        consoleLogInfo("rtcEngine error:\(errorCode.rawValue)", type: .error)
        DispatchQueue.main.asyncAfter(wallDeadline: .now()+1) {
            UIViewController.currentController?.showToast(toast: "rtc error:\(errorCode.rawValue)",duration: 3)
        }
        for key in self.handlers.keyEnumerator().allObjects {
            if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                listener.onCallStatusChanged(status: .ended, reason: EaseMob1v1CallKitEndReason.rtcError.rawValue)
            }
        }
        self.endCall(reason: EaseMob1v1CallKitEndReason.rtcError.rawValue)
    }
    //Self join
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
        for key in self.handlers.keyEnumerator().allObjects {
            if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                listener.onCallTokenWillExpire()
            }
        }
    }
    
    func rtcEngineRequestToken(_ engine: AgoraRtcEngineKit) {
        
    }
    //Remote offline
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        var reasonDescription = ""
        switch reason {
        case .quit:
            reasonDescription = "对方离开"
        case .dropped:
            reasonDescription = "对方掉线"
        default:
            break
        }
        for key in self.handlers.keyEnumerator().allObjects {
            if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                listener.onCallStatusChanged(status: .ended, reason: reasonDescription)
            }
        }
    }
    //Remote join
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        self.remoteUid = uid
        for key in self.handlers.keyEnumerator().allObjects {
            if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                listener.onCallStatusChanged(status: .onCalling, reason: "\(uid)")
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
        self.remoteUid = uid
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteAudioFrameOfUid uid: UInt, elapsed: Int) {
        
    }
}
