//
//  MineConversationCell.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/15.
//

import UIKit
import EaseChatUIKit

final class MineConversationCell: ConversationListCell {
    
    lazy var status: UIImageView = {
        let r = self.avatar.frame.width / 2.0
        let length = CGFloat(sqrtf(Float(r)))
        let x = (Appearance.avatarRadius == .large ? (r + length + 3):(self.avatar.frame.width-10))
        let y = (Appearance.avatarRadius == .large ? (r + length + 3):(self.avatar.frame.height-10))
        return UIImageView(frame: CGRect(x: self.avatar.frame.minX+x, y: self.avatar.frame.minY+y, width: 12, height: 12)).backgroundColor(UIColor.theme.secondaryColor5).cornerRadius(.large).layerProperties(UIColor.theme.neutralColor98, 2).contentMode(.scaleAspectFit)
    }()

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.status)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let r = self.avatar.frame.width / 2.0
        let length = CGFloat(sqrtf(Float(r)))
        let x = (Appearance.avatarRadius == .large ? (r + length + 3):(self.avatar.frame.width-10))
        let y = (Appearance.avatarRadius == .large ? (r + length + 3):(self.avatar.frame.height-10))
        self.status.frame = CGRect(x: self.avatar.frame.minX+x+3, y: self.avatar.frame.minY+y+3, width: 12, height: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func refresh(info: ConversationInfo) {
        super.refresh(info: info)
        self.showUserStatus(with: info.id)
    }
    
    private func showUserStatus(with userId: String) {
        if let presence = PresenceManager.shared.presences[userId] {
            let state = PresenceManager.status(with: presence)
            switch state {
            case .online:
                self.status.backgroundColor = Theme.style == .dark ? UIColor.theme.secondaryColor6:UIColor.theme.secondaryColor5
            case .offline:
                self.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5
            case .busy:
                self.status.image = nil
                self.status.backgroundColor = Theme.style == .dark ? UIColor.theme.errorColor5:UIColor.theme.errorColor6
            default:break
            }
            
        }
        
    }
}
