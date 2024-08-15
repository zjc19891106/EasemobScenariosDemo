//
//  UserMatchView.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/5.
//

import UIKit
import EaseChatUIKit

final class UserMatchView: UIImageView {
    
    var connectionClosure: (()->())?
    
    lazy var voiceIndicator: UIImageView = {
        UIImageView(frame: CGRect(x: 12, y: 12, width: 36, height: 30)).image(UIImage(named: "voice_indicator"))
    }()
    
    lazy var avatar: ImageView = {
        ImageView(frame: CGRect(x: 30, y: self.frame.height-71, width: 32, height: 32)).cornerRadius(Appearance.avatarRadius).contentMode(.scaleAspectFill)
    }()
    
    lazy var nickname: UILabel = {
        UILabel(frame: CGRect(x: self.avatar.frame.maxX+10, y: self.avatar.frame.minY+5, width: self.frame.width-self.avatar.frame.maxX-10-106, height: 22)).font(UIFont.theme.headlineLarge).textColor(.white).backgroundColor(.clear)
    }()
    
    lazy var connection: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: self.frame.width-92, y: self.frame.height-92, width: 76, height: 76)).image(UIImage(named: "connect"), .normal)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubViews([self.voiceIndicator,self.avatar,self.nickname,self.connection])
        self.connection.isUserInteractionEnabled = false
        self.connection.setBackgroundImage(UIImage(named: "connect_bg"), for: .normal)
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(connectionAction)))
    }
    
    @objc func connectionAction() {
        self.connectionClosure?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh(profile: EaseProfileProtocol) {
        self.isHidden = false
        if let user = profile as? MatchUserInfo {
            let userID = user.matchedChatUser
            var nickname = EaseChatUIKitContext.shared?.userCache?[userID]?.nickname ?? ""
            if nickname.isEmpty {
                nickname = "匿名用户-\(userID)"
            }
            self.nickname.text = nickname
            let url = EaseChatUIKitContext.shared?.userCache?[userID]?.avatarURL ?? ""
            self.avatar.image(with: url, placeHolder: Appearance.avatarPlaceHolder)
        }
        
    }
}
