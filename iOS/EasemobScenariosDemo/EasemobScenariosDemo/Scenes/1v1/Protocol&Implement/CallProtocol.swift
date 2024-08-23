//
//  CallProtocol.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/6.
//

import Foundation
import EaseChatUIKit



public let EaseMob1v1CallKit1v1Invite = "EaseMob1v1CallKit1v1Invite"

public let EaseMob1v1CallKit1v1End = "EaseMob1v1CallKit1v1End"

public let EaseMob1v1CallKit1v1Accept = "EaseMob1v1CallKit1v1Accept"

public let EaseMob1v1CallKit1v1Signaling = "rtcCallWithAgora"

public let EaseMob1v1SomeUserMatchedYou = "1v1-video-matched"

public let EaseMob1v1SomeUserMatchCanceled = "1v1-video-cancel-matched"//进程终止的取消匹配

enum EaseMob1v1CallKitEndReason: String {
    case normalEnd = "normal"
    case cancelEnd = "cancel"
    case refuseEnd = "refuse"
    case timeoutEnd = "timeout"
    case busyEnd = "busy"
    case rtcError = "rtcError"
}

class EaseMobCallKit {
    
    @objc enum CallStatus: UInt {
        case preparing //匹配到 matching user
        case onCalling //通话中
        case ended//结束通话
        case alert //有通话请求
        case join
        case idle //空闲
    }

    protocol CallProtocol {
        
        /// Start call with a user.
        func startCall()
        
        /// End call with a reason.
        /// - Parameter reason: The reason of ending call.
        func endCall(reason: String)
        
        /// Accept call with a user.
        func acceptCall()
    }

    @objc protocol CallListener: NSObjectProtocol {
        
        /// When call status changed.
        /// - Parameter status: The status of the ``CallStatus``.
        /// - Parameter reason: The reason of the end call .
        func onCallStatusChanged(status: CallStatus, reason: String)
        
        /// When rtc token will expired.Need request from server to refresh token.
        func onCallTokenWillExpire()
    }
}
