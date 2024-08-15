//
//  CallAlertViewController.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/14.
//

import UIKit
import EaseChatUIKit
import AudioToolbox
import AVFoundation

final class CallAlertViewController: UIViewController,PresentedViewType {
    
    var presentedViewComponent: EaseChatUIKit.PresentedViewComponent? = PresentedViewComponent(contentSize:  CGSize(width: ScreenWidth, height: 357),destination: .bottomBaseline,canTapBGDismiss: false,canPanDismiss: false)
    
    lazy var callView: CallPopupView = {
        let callView = CallPopupView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 357))
        callView.role = self.role
        callView.refresh(with: self.profile)
        if role == .caller {
            EaseMob1v1CallKit.shared.startCall()
        }
        callView.actionClosure = { [weak self] in
            if $0 == .accept {
                self?.refuse = false
                EaseMob1v1CallKit.shared.acceptCall()
            }  else {
                if callView.role == .caller {
                    EaseMob1v1CallKit.shared.endCall(reason: EaseMob1v1CallKitEndReason.cancelEnd.rawValue)
                } else {
                    EaseMob1v1CallKit.shared.endCall(reason: EaseMob1v1CallKitEndReason.refuseEnd.rawValue)
                }
            }
            self?.dismissSelf()
        }
        return callView
    }()
    
    private var refuse = true
    
    private var role: CallPopupView.CallRole
    
    private var profile: EaseProfileProtocol
    
    private var ringService = RingerService()
    
    required init(role: CallPopupView.CallRole = .caller,profile: EaseProfileProtocol) {
        self.role = role
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.callView)
        // Do any additional setup after loading the view.
        PresenceManager.shared.publishPresence(description: PresenceManager.State.busy.rawValue) { error in
            if error != nil {
                consoleLogInfo("publishPresence error: \(error?.errorDescription ?? "")",type: .error)
            }
        }
        GlobalTimer.shared.addTimer(self.swiftClassName ?? "CallAlertViewController", timerHandler: self)
        self.ringService.startRinging()
    }

}

extension CallAlertViewController: TimerListener {
    func timerDidChanged(key: String, duration: Int) {
        if key == self.swiftClassName {
            self.ringService.playSystemSound()
            if duration > 15 {
                self.dismissSelf(timeout: true)
            }
        }
    }
    
    func dismissSelf(timeout: Bool = false,completion: (() -> Void)? = nil) {
        self.ringService.stopRinging()
        GlobalTimer.shared.removeTimer(self.swiftClassName ?? "CallAlertViewController")
        if timeout {
            EaseMob1v1CallKit.shared.endCall(reason: EaseMob1v1CallKitEndReason.timeoutEnd.rawValue)
        }
        if self.refuse {
            PresenceManager.shared.publishPresence(description: "") { error in
                if error != nil {
                    consoleLogInfo("publishPresence error: \(error?.errorDescription ?? "")",type: .error)
                }
            }
        }
        self.dismiss(animated: true,completion: completion)
    }
}

final class RingerService {
    
    private var soundID: SystemSoundID = 0

    func startRinging() {
        // 设置音频会话
        setupAudioSession()
        
        // 播放系统默认铃声并震动
        playSystemSound()
    }

    func stopRinging() {
        AudioServicesDisposeSystemSoundID(soundID)
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
    }

    func playSystemSound() {
        // 使用系统默认铃声
        AudioServicesPlaySystemSound(SystemSoundID(1005))
        
    }
}
