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

final class EaseMob1v1CallKit: NSObject {
    
    static let shared = EaseMob1v1CallKit()
    
    public private(set) var agoraKit: AgoraRtcEngineKit?
    
    private var handlers: NSMapTable<NSString,EaseMobCallKit.CallListener> = NSMapTable<NSString, EaseMobCallKit.CallListener>.strongToWeakObjects()
    
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
        EasemobBusinessRequest.shared.sendDELETERequest(api: .matchUser(()), params: [:]) { result, error in
            
        }
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
                if EaseChatUIKitContext.shared?.userCache?[message.from] == nil {
                    EaseChatUIKitContext.shared?.userCache?[message.from] = profile
                } else {
                    EaseChatUIKitContext.shared?.userCache?[message.from]?.nickname = profile.nickname
                    EaseChatUIKitContext.shared?.userCache?[message.from]?.avatarURL = profile.avatarURL
                }
            }
            if let body = message.body as? ChatCMDMessageBody,message.to == ChatClient.shared().currentUsername ?? "" {
                if message.from == "admin",body.action == EaseMob1v1SomeUserMatchedYou {
                    if let json = message.ext as? [String:Any] {
                        let matchedUser = model(from: json, MatchUserInfo.self)
                        self.localUid = UInt(matchedUser.agoraUid) ?? 0
                        self.currentUser = matchedUser
                        self.currentUser.id = EaseChatUIKitContext.shared?.currentUserId ?? ""
                    }
                    self.prepareEngine()
                    for key in self.handlers.keyEnumerator().allObjects {
                        if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                            listener.onCallStatusChanged(status: .preparing, reason: "Call You")
                        }
                    }
                } else {
                    if body.action == EaseMob1v1CallKit1v1End {
                        if let reason = message.ext?["endCallReason"] as? String {
                            self.insertEndMessage(conversationId: message.conversationId)
                            for key in self.handlers.keyEnumerator().allObjects {
                                if let key = key as? NSString, let listener = self.handlers.object(forKey: key) {
                                    listener.onCallStatusChanged(status: .ended, reason: reason)
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
                if EaseChatUIKitContext.shared?.userCache?[message.from] == nil {
                    EaseChatUIKitContext.shared?.userCache?[message.from] = profile
                } else {
                    EaseChatUIKitContext.shared?.userCache?[message.from]?.nickname = profile.nickname
                    EaseChatUIKitContext.shared?.userCache?[message.from]?.avatarURL = profile.avatarURL
                }
            }
            if message.to == ChatClient.shared().currentUsername ?? ""  {
                if let inviteCallId = message.ext?["EaseMob1v1CallKitCallId"] as? String,let inviteKey = message.ext?[EaseMob1v1CallKit1v1Invite] as? String,inviteKey == EaseMob1v1CallKit1v1Invite {
                    let callerId = UInt(inviteCallId) ?? 0
                    let calleeId = UInt(self.callId) ?? 0
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
