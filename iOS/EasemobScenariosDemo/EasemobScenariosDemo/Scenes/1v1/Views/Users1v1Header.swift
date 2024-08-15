//
//  Users1v1Header.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/9.
//

import UIKit
import EaseChatUIKit

final class Users1v1Header: UIView {
    
    lazy var avatar: ImageView = {
        ImageView(frame: CGRect(x: 2, y: 2, width: self.frame.height-4, height: self.frame.height-4)).cornerRadius(.large)
    }()
    
    lazy var userName: UILabel = {
        UILabel(frame: CGRect(x: self.avatar.frame.maxX+8, y: 2, width: self.frame.width-self.avatar.frame.maxX-8-16, height: 22)).font(UIFont.theme.labelLarge).textColor(UIColor.theme.neutralColor98).text("User's channel~")
    }()
    
    lazy var userId: UILabel = {
        UILabel(frame: CGRect(x: self.avatar.frame.maxX+8, y: self.frame.height-2-14, width: self.frame.width-self.avatar.frame.maxX-8-16, height: 14)).font(UIFont.theme.bodyExtraSmall).textColor(UIColor(white: 1, alpha: 0.8)).text("UserName")
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubViews([self.avatar,self.userName,self.userId])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh(with user: EaseProfileProtocol) {
        self.avatar.image(with: user.avatarURL, placeHolder: Appearance.avatarPlaceHolder)
        self.userName.text = user.nickname.isEmpty ? "匿名用户-\(user.id)" : user.nickname
        self.userId.text = user.id
    }
}
