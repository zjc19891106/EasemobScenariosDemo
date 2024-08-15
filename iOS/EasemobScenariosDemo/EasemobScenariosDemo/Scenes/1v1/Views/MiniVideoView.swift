//
//  MiniVideoView.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/7.
//

import UIKit
import EaseChatUIKit

final class MiniVideoView: UIView {
    
    lazy var nameLabel: UILabel = {
        UILabel(frame: CGRect(x: 12, y: self.frame.height-40, width: self.frame.width-24, height: 33)).text("Lucas").font(UIFont.theme.labelSmall).textAlignment(.center).textColor(.white)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
