//
//  CallPopupView.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/6.
//

import UIKit
import EaseChatUIKit

final class CallPopupView: UIView {
    
    enum ActionType {
        case accept
        case decline
    }
    
    enum CallRole {
        case caller
        case callee
    }
    
    private var acceptButtonCenterXConstraint: NSLayoutConstraint!
    
    private var declineButtonCenterXConstraint: NSLayoutConstraint!
    
    var actionClosure: ((ActionType) -> ())?
    
    @MainActor var role: CallRole = .caller {
        didSet {
            switch self.role {
            case .caller:
                self.callStatusLabel.text = "等待对方接受"
                self.acceptButton.isHidden = true
                self.declineButton.isHidden = false
                self.declineButtonCenterXConstraint.isActive = false
                self.declineButtonCenterXConstraint = self.declineButton.centerXAnchor.constraint(equalTo: self.centerXAnchor)
                self.declineButtonCenterXConstraint.isActive = true
            case .callee:
                self.callStatusLabel.text = "收到连线邀请"
                self.acceptButton.isHidden = false
                self.declineButton.isHidden = false
                self.acceptButtonCenterXConstraint.isActive = false
                self.declineButtonCenterXConstraint.isActive = false
                self.acceptButtonCenterXConstraint = self.acceptButton.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 75)
                self.declineButtonCenterXConstraint = self.declineButton.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: -75)
                self.acceptButtonCenterXConstraint.isActive = true
                self.declineButtonCenterXConstraint.isActive = true
            }
            self.layoutIfNeeded()
        }
    }
    
    lazy var userImageView: ImageView = {
        let imageView = ImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 40
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "dialog_icon") // 这里替换为你的背景图片
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var callStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "收到连线邀请"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "phone.fill.arrow.up.right"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 35
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(acceptAction), for: .touchUpInside)
        return button
    }()
    
    lazy var declineButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "phone.down.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 35
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(declineAction), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        // 设置背景颜色和圆角
        self.backgroundColor = UIColor.white
        self.layer.cornerRadius = 16
        
        // 添加子视图
        self.addSubViews([self.backgroundImageView,self.userImageView,self.usernameLabel,self.callStatusLabel,self.acceptButton,self.declineButton])
        
        // 布局背景图片
        NSLayoutConstraint.activate([
            self.backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            self.backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.backgroundImageView.heightAnchor.constraint(equalToConstant: 100),
            self.backgroundImageView.widthAnchor.constraint(equalToConstant: 106)
        ])
        
        // 布局用户头像
        NSLayoutConstraint.activate([
            self.userImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.userImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: -40),
            self.userImageView.widthAnchor.constraint(equalToConstant: 80),
            self.userImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        // 布局用户名标签
        NSLayoutConstraint.activate([
            self.usernameLabel.topAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 20),
            self.usernameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            self.usernameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            self.usernameLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        // 布局通话状态标签
        NSLayoutConstraint.activate([
            self.callStatusLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 21),
            self.callStatusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            self.callStatusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            self.callStatusLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        self.acceptButtonCenterXConstraint = self.acceptButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 75)
        self.declineButtonCenterXConstraint = self.declineButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        // 布局接受按钮
        NSLayoutConstraint.activate([
            self.acceptButtonCenterXConstraint,
            self.acceptButton.widthAnchor.constraint(equalToConstant: 70),
            self.acceptButton.heightAnchor.constraint(equalToConstant: 70),
            self.acceptButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -41-BottomBarHeight),
        ])
        
        // 布局拒绝按钮
        NSLayoutConstraint.activate([
            self.declineButtonCenterXConstraint,
            self.declineButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -41-BottomBarHeight),
            self.declineButton.widthAnchor.constraint(equalToConstant: 70),
            self.declineButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func refresh(with user: EaseProfileProtocol) {
        var nickname = user.nickname
        if nickname.isEmpty {
            nickname = "匿名用户-\(user.id)"
        }
        self.usernameLabel.text = nickname
        self.userImageView.image(with: user.avatarURL, placeHolder: Appearance.avatarPlaceHolder)
    }
    
    @objc func acceptAction() {
        self.actionClosure?(.accept)
    }
    
    @objc func declineAction() {
        self.actionClosure?(.decline)
    }
}
