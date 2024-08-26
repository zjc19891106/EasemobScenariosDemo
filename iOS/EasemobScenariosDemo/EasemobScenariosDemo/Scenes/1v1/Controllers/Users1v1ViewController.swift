//
//  Users1v1ViewController.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/6.
//

import UIKit
import EaseChatUIKit
import libpag

final class Users1v1ViewController: UIViewController {
    
    private lazy var background: UIImageView = {
        UIImageView(frame: self.view.bounds).contentMode(.scaleAspectFill).image(UIImage(named: "login_bg")).isUserInteractionEnabled(false)
    }()
    
    private lazy var effectView: GiftAnimationEffectView = {
        GiftAnimationEffectView(frame:self.view.bounds)
    }()
    
    private lazy var remoteVideoView: MiniVideoView = {
        MiniVideoView(frame: CGRect(x: self.view.frame.width-16-109, y: NavigationHeight+60, width: 109, height: 163)).cornerRadius(20)
    }()
    
    private lazy var localVideoView: UIView = {
        UIView(frame: self.view.bounds).isUserInteractionEnabled(false)
    }()
    
    private lazy var header: Users1v1Header = {
        Users1v1Header(frame: CGRect(x: 16, y: StatusBarHeight, width: 202, height: 40)).backgroundColor(UIColor.theme.barrageLightColor2).cornerRadius(.large)
    }()
    
    lazy var callDuration: CallDurationView = {
        CallDurationView(frame: CGRect(x: 18, y: self.header.frame.maxY+4, width: 82, height: 16)).backgroundColor(UIColor.theme.barrageLightColor2).cornerRadius(.large)
    }()
    
    private lazy var endCall: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: ScreenWidth-52, y: StatusBarHeight, width: 36, height: 36)).image(UIImage(systemName: "phone.down.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal), .normal).addTargetFor(self, action: #selector(endCallAction), for: .touchUpInside).backgroundColor(.systemRed).cornerRadius(18)
    }()
    
    
    /// Gift list on receive gift.
    private lazy var giftArea: GiftMessageList = {
        GiftMessageList(frame: CGRect(x: CGFloat(10), y: self.view.frame.height-CGFloat(164)-CGFloat(54)-BottomBarHeight-CGFloat(5)-CGFloat(44*2), width: self.view.frame.width/2.0+CGFloat(60), height: CGFloat(44*2)),source: self)
    }()
    
    /// Chat area list.
    private lazy var chatList: MessageList = {
        MessageList(frame: CGRect(x: 0, y: self.view.frame.height-164-54-BottomBarHeight-5, width: self.view.frame.width-56, height: 164)).backgroundColor(.clear)
    }()
    
    /// Bottom function bar below chat  list.
    private lazy var bottomBar: BottomAreaToolBar = {
        BottomAreaToolBar(frame: CGRect(x: 0, y: self.view.frame.height-54-BottomBarHeight, width: self.view.frame.width, height: 54), datas: self.viewModel.bottomBarDatas())
    }()
    
    /// Input text menu bar.
    private lazy var inputBar: Message1v1InputBar = {
        Message1v1InputBar(frame: CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 52),text: nil,placeHolder: "说点什么")
    }()
    
    private lazy var giftViewController: GiftsViewController = {
        GiftsViewController(gifts: self.viewModel.gifts()) { [weak self] gift in
            self?.viewModel.sendGift(gift: gift)
        }
    }()
    
    private lazy var viewModel: Users1v1ChatViewModel = {
        Users1v1ChatViewModel(with: self.chatTo)
    }()
    
    private var chatTo = ""
    
    private var popVC: ConversationsPopViewController?
    
    private var showRemoteAsSmall = true
    
    required init(with user: EaseProfileProtocol) {
        self.chatTo = user.id
        super.init(nibName: nil, bundle: nil)
        self.header.refresh(with: user)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        self.view.backgroundColor = .white
        self.view.addSubViews([self.localVideoView,self.remoteVideoView,self.header,self.callDuration,self.giftArea,self.chatList,self.bottomBar,self.inputBar,self.effectView,self.endCall])
        self.effectView.isHidden = true
        // Do any additional setup after loading the view.
        //Bind driver&viewModel
        self.viewModel.bind(giftDriver: self.giftArea)
        self.viewModel.bind(chatDriver: self.chatList)
        self.viewModel.bind(bottomBarDriver: self.bottomBar)
        self.viewModel.bind(inputDriver: self.inputBar)
        self.viewModel.bind(giftAnimationDriver: self.effectView)
        
        //Add call kit listener
        EaseMob1v1CallKit.shared.addListener(listener: self)
        //Add view model transmit event
        self.viewModel.addListener(self)
        //Add bottom bar action handler
        self.bottomBar.addActionHandler(actionHandler: self)
        //Join rtc channel
        EaseMob1v1CallKit.shared.joinChannel { [weak self] in
            guard let `self` = self else { return }
            EaseMob1v1CallKit.shared.onCalling = true
            EaseMob1v1CallKit.shared.renderLocalCanvas(with: self.localVideoView)
        }
        GlobalTimer.shared.addTimer(self.swiftClassName ?? "Users1v1ViewController", timerHandler: self)
        
    }
    
    
    deinit {
        EaseMob1v1CallKit.shared.removeListener(listener: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            let point = touch.location(in: self.view)
            
            if self.remoteVideoView.frame.contains(point) {
                self.showRemoteAsSmall = !self.showRemoteAsSmall
                if self.showRemoteAsSmall {
                    self.remoteVideoView.frame = CGRect(x: self.view.frame.width-16-109, y: NavigationHeight+60, width: 109, height: 163)
                    self.remoteVideoView.cornerRadius(20)
                    self.localVideoView.frame = self.view.bounds
                    self.view.sendSubviewToBack(self.localVideoView)
                    self.view.bringSubviewToFront(self.remoteVideoView)
                } else {
                    self.localVideoView.frame = CGRect(x: self.view.frame.width-16-109, y: NavigationHeight+60, width: 109, height: 163)
                    self.remoteVideoView.frame = self.view.bounds
                    self.view.sendSubviewToBack(self.remoteVideoView)
                    self.view.bringSubviewToFront(self.localVideoView)
                }
            }
        }
    }
    
    @objc private func endCallAction() {
        EaseMob1v1CallKit.shared.endCall(reason: EaseMob1v1CallKitEndReason.normalEnd.rawValue)
        GlobalTimer.shared.removeTimer(self.swiftClassName ?? "Users1v1ViewController")
        self.pop()
    }
    
    @objc func pop() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            if let current = UIViewController.currentController as? ConversationsPopViewController {
                current.dismiss(animated: false) {
                    self.dismiss(animated: true)
                }
            } else {
                self.dismiss(animated: true)
            }
            if let current = UIViewController.currentController as? MessagesPopViewController {
                current.dismiss(animated: false) {
                    self.dismiss(animated: true)
                }
            } else {
                self.dismiss(animated: true)
            }
        }
    }
}

extension Users1v1ViewController: TimerListener {
    func timerDidChanged(key: String, duration: Int) {
        if key == self.swiftClassName ?? "Users1v1ViewController" {
            self.callDuration.updateTimer(seconds: duration)
        }
    }
}

extension Users1v1ViewController: Users1v1ChatViewModelListener {
    
    func receiveOtherMessage(message: [EaseChatUIKit.ChatMessage]) {
        DispatchQueue.main.async {
            self.inputBar.hiddenInput()
            if self.popVC == nil {
                self.popVC = ConversationsPopViewController(messages: message) { [weak self] conversation in
                    if let current = UIViewController.currentController as? ConversationsPopViewController {
                        current.dismiss(animated: true,completion: {
                            self?.popVC = nil
                            if let info = conversation {
                                self?.showPreviewChatMessage(info: info)
                            }
                        })
                    } else {
                        if let info = conversation {
                            self?.showPreviewChatMessage(info: info)
                        }
                    }
                    
                }
            }
            if let vc = self.popVC {
                if UIViewController.currentController is ConversationsPopViewController {
                    self.popVC?.refresh(messages: message)
                    return
                } else {
                    
                    self.presentViewController(vc,animated: true)
                }
            }
        }
        
    }
    
    func showPreviewChatMessage(info: ConversationInfo) {
        if UIViewController.currentController is MessagesPopViewController {
            return
        }
        let message = MessagesPopViewController(conversationId: info.id, chatType: .chat)
        self.presentViewController(message,animated: true)
    }
    
}

extension Users1v1ViewController: EaseMobCallKit.CallListener {
    
    func onCallStatusChanged(status: EaseMobCallKit.CallStatus, reason: String) {
        switch status {
        case .onCalling:
            EaseMob1v1CallKit.shared.renderRemoteCanvas(with: self.remoteVideoView)
            self.view.bringSubviewToFront(self.remoteVideoView)
            self.remoteUserInfoFill()
        case .ended:
            GlobalTimer.shared.removeTimer(self.swiftClassName ?? "Users1v1ViewController")
            EaseMob1v1CallKit.shared.hangup()
            self.pop()
        default:
            break
        }
    }
    
    func remoteUserInfoFill() {
        var nickname = EaseChatUIKitContext.shared?.userCache?[self.chatTo]?.nickname ?? ""
        if nickname.isEmpty {
            nickname = self.chatTo
            Task {
                let profile = await self.viewModel.requestUserInfo(profileId: self.chatTo)
                nickname = profile?.nickname ?? ""
                DispatchQueue.main.async {
                    self.remoteVideoView.nameLabel.text = nickname
                }
            }
        }
    }
    
    func onCallTokenWillExpire() {
        self.viewModel.refreshRTCToken()
    }
    
    
}

extension Users1v1ViewController: BottomAreaToolBarActionEvents {
    func onKeyboardWillWakeup() {
        self.inputBar.show()
    }
    
    func onBottomItemClicked(item: any ChatBottomItemProtocol) {
        if item.type == 0 {
            DialogManager.shared.showGiftsDialog(titles: ["礼物列表"], gifts: [self.giftViewController])
        }
    }
}

extension Users1v1ViewController:GiftMessageListTransformAnimationDataSource {
    func rowHeight() -> CGFloat {
        44
    }
}

extension DialogManager {
    /// Shows the gift list page.
    /// - Parameters:
    ///   - titles: `[String]`
    ///   - gifts: ``GiftsViewController`` array.
    @objc(showGiftsDialogWithTitles:gifts:)
    public func showGiftsDialog(titles: [String],gifts: [GiftsViewController]) {
        let gift = PageContainersDialogController(pageTitles: titles, childControllers: gifts,constraintsSize: CGSize(width: ScreenWidth, height: ScreenHeight/2.0))
        
        UIViewController.currentController?.presentViewController(gift)
    }
}
