//
//  UsersMatchViewController.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/5.
//

import UIKit
import EaseChatUIKit
import AVFoundation

final class UsersMatchViewController: UIViewController {
    
    @UserDefault("EaseScenariosDemoPhone", defaultValue: "") private var phone
    
    lazy var background: UIImageView = {
        UIImageView(frame: self.view.bounds).contentMode(.scaleAspectFill).image(UIImage(named: "login_bg"))
    }()
    
    lazy var titleLabel: UILabel = {
        UILabel(frame: CGRect(x: 70, y: StatusBarHeight+10, width: self.view.frame.width-140, height: 28)).font(UIFont.theme.titleLarge).textColor(.black).text("1v1私密房").textAlignment(.center)
    }()
    
    lazy var rotatingImageView: UIImageView = {
        UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)).contentMode(.scaleAspectFit).image(UIImage(named: "refresh"))
    }()
    
    lazy var matchedUser: UserMatchView = {
        UserMatchView(frame: CGRect(x: 16, y: NavigationHeight+10, width: self.view.frame.width-32, height: ScreenHeight-NavigationHeight-10-(self.tabBarController?.tabBar.frame.height ?? 0) - BottomBarHeight)).cornerRadius(16).image(UIImage(named: "match_background\(UInt.random(in: 0...9))")).contentMode(.scaleAspectFill)
    }()
    
    lazy var empty: NoMatchUserView = {
        NoMatchUserView(frame: self.view.bounds, emptyImage: UIImage(named: "no_match")) {
            
        }
    }()
    
    let viewModel = UsersMatchViewModel()
    
    private var role = CallPopupView.CallRole.caller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.rotatingImageView)
        self.rotatingImageView.isUserInteractionEnabled = true
        self.rotatingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(refresh)))
        self.view.addSubViews([self.background,self.empty,self.titleLabel,self.matchedUser])
        self.matchedUser.isHidden = true
        self.viewModel.bind(userDriver: self.matchedUser)
        
        self.matchedUser.connectionClosure = { [weak self] in
            guard let `self` = self else { return }
            self.showCallView()
        }
        EaseMob1v1CallKit.shared.addListener(listener: self)
        
    }
    
    deinit {
        EaseMob1v1CallKit.shared.removeListener(listener: self)
    }
    
    private func showCallView(role: CallPopupView.CallRole = .caller,reason: String = "") {
        self.role = role
        self.requestCameraAndMicrophonePermissions { permission in
            if permission {
                var onCall = false
                if UIViewController.currentController is CallAlertViewController || UIViewController.currentController is Users1v1ViewController {
                    onCall = true
                }
                if !onCall {
                    var profile: EaseProfileProtocol = EaseChatProfile()
                    if reason.isEmpty { profile = self.viewModel.matchedUser } else {
                        if let user = EaseChatUIKitContext.shared?.userCache?[reason] {
                            profile = user
                        }
                    }
                    let call = CallAlertViewController(role: role, profile: profile)
                    UIViewController.currentController?.presentViewController(call,animated: true)
                } else {
                    EaseMob1v1CallKit.shared.endCall(reason: EaseMob1v1CallKitEndReason.busyEnd.rawValue)
                }
            }
        }
        
    }

    @objc func refresh() {
        self.startRotatingAnimation()
        self.viewModel.matchUser { [weak self] (error) in
            if let error = error as? EasemobError {
                consoleLogInfo("匹配失败:\(error.message ?? "")", type: .error)
            }
            self?.stopRotatingAnimation()
            self?.matchedUser.image = UIImage(named: "match_background\(UInt.random(in: 0...9))")
        }
    }
    
    func startRotatingAnimation() {
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 1 // 旋转一周的时间
        rotation.repeatCount = .infinity // 无限循环
        
        self.rotatingImageView.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    @objc func stopRotatingAnimation() {
        self.rotatingImageView.layer.removeAnimation(forKey: "rotationAnimation")
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
}

extension UsersMatchViewController: EaseMobCallKit.CallListener {
    
    func onCallStatusChanged(status: EaseMobCallKit.CallStatus, reason: String) {
        DispatchQueue.main.async {
            switch status {
            case .idle:
                self.matchedUser.isHidden = true
                self.showToast(toast: reason)
            case .alert:
                self.showCallView(role: .callee,reason: reason)
            case .preparing:
                self.matchedUser.isHidden = false
                if let user = EaseChatUIKitContext.shared?.userCache?[reason] {
                    self.matchedUser.refresh(profile: user)
                } else {
                    self.matchedUser.refresh(profile: EaseMob1v1CallKit.shared.currentUser)
                }
            case .onCalling:
                print("join channel:\(Date().timeIntervalSince1970)")
            case .join:
                print("join channel:\(Date().timeIntervalSince1970)")
                if let current = UIViewController.currentController as? CallAlertViewController {
                    current.dismissSelf {
                        DispatchQueue.main.asyncAfter(wallDeadline: .now()+0.2) {
                            self.joined1v1Chat()
                        }
                    }
                }
                if let _ = UIViewController.currentController as? Users1v1ViewController {
                    return
                }
            case .ended:
                if let current = UIViewController.currentController as? CallAlertViewController {
                    current.dismissSelf(timeout: reason == EaseMob1v1CallKitEndReason.timeoutEnd.rawValue) {
                        DispatchQueue.main.asyncAfter(wallDeadline: .now()+0.3) {
                            self.showToast(with: reason)
                        }
                    }
                }
                
            default:
                break
            }
        }
        
    }
    
    func cancelMatch() {
        EasemobBusinessRequest.shared.sendDELETERequest(api: .cancelMatch(self.phone), params: [:]) { result, error in
            
        }
    }
    
    func showToast(with reason: String) {
        let reasonCode = EaseMob1v1CallKitEndReason(rawValue: reason) ?? .normalEnd
        var reasonDescription = ""
        switch reasonCode {
        case .normalEnd: reasonDescription = "通话结束"
        case .cancelEnd: reasonDescription = "对方取消"
        case .refuseEnd: reasonDescription = "对方拒绝"
        case .timeoutEnd: reasonDescription = "接听超时"
        case .busyEnd: reasonDescription = "对方忙碌"
        case .rtcError: reasonDescription = "对方加入频道异常"
        }
        UIViewController.currentController?.showToast(toast: reasonDescription)
    }
    
    func joined1v1Chat() {
        let profile = EaseChatProfile()
        profile.id = self.role == .caller ? self.viewModel.matchedUser.matchedChatUser:EaseMob1v1CallKit.shared.currentUser.matchedChatUser
        profile.avatarURL = EaseChatUIKitContext.shared?.userCache?[profile.id]?.avatarURL ?? ""
        profile.nickname = EaseChatUIKitContext.shared?.userCache?[profile.id]?.nickname ?? ""
        let vc = Users1v1ViewController(with: profile)
        vc.modalPresentationStyle = .fullScreen
        UIViewController.currentController?.present(vc, animated: true)
    }
    
    func onCallTokenWillExpire() {
//        self.viewModel.refreshRTCToken()
        
    }
    
    
}
