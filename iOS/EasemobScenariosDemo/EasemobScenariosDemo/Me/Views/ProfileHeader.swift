//
//  ProfileHeader.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/5.
//

import UIKit
import EaseChatUIKit

final class ProfileHeader: UIView {
    
    var avatarChangedClosure: (() -> ())?
    
    @UserDefault("EaseScenariosDemoPhone", defaultValue: "") private var phone

    // 创建头像图片视图
    lazy var profileImageView: ImageView = {
        let imageView = ImageView(frame: .zero)
        imageView.image = Appearance.avatarPlaceHolder // 这里替换为你的头像图片
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // 创建用户名标签
    lazy var nameLabel: UITextField = {
        let label = UITextField()
        label.text = "Lucas"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.returnKeyType = .done
        return label
    }()
    
    lazy var edit: UIButton = {
        UIButton(type: .custom).image(UIImage(named: "bianji"), .normal).addTargetFor(self, action: #selector(editName(sender:)), for: .touchUpInside)
    }()
    
    lazy var phoneLabel: UILabel = {
        let label = UILabel()
        label.text = self.phone
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubViews([self.profileImageView,self.nameLabel,self.edit,self.phoneLabel])
        self.edit.translatesAutoresizingMaskIntoConstraints = false
        self.profileImageView.isUserInteractionEnabled = true
        self.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateAvatar)))
        // 头像图片视图约束
        NSLayoutConstraint.activate([
            profileImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 50),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // 用户名标签约束
        NSLayoutConstraint.activate([
            nameLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20),
            nameLabel.heightAnchor.constraint(equalToConstant: 26)
        ])
        
        NSLayoutConstraint.activate([
            edit.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 5),
            edit.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            edit.widthAnchor.constraint(equalToConstant: 20),
            edit.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // 用户ID标签约束
        NSLayoutConstraint.activate([
            phoneLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            phoneLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            phoneLabel.heightAnchor.constraint(equalToConstant: 18),
            phoneLabel.widthAnchor.constraint(equalToConstant: ScreenWidth-40-30)
        ])
        guard let profile = EaseChatUIKitContext.shared?.currentUser else {
            return
        }
        
        self.profileImageView.image(with: profile.avatarURL, placeHolder: Appearance.avatarPlaceHolder)
        var nickname = profile.nickname
        if nickname.isEmpty {
            nickname = "匿名用户-\(profile.id)"
        }
        self.nameLabel.text = nickname
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func editName(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.nameLabel.isUserInteractionEnabled = sender.isSelected
        self.nameLabel.perform(#selector(selectAll(_:)), with: nil, afterDelay: 0.1)
        self.nameLabel.becomeFirstResponder()
    }
    
    @objc func updateAvatar() {
        self.avatarChangedClosure?()
    }
}
