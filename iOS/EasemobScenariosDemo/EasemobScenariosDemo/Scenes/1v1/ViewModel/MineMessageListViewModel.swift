//
//  MineMessageListViewModel.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/14.
//

import UIKit
import EaseChatUIKit

final class MineMessageListViewModel: MessageListViewModel {
    
    override func audioMessagePlay(message: MessageEntity) {
        if EaseMob1v1CallKit.shared.onCalling {
            UIViewController.currentController?.showToast(toast: "正在通话中，请稍后再试")
            return
        }
        super.audioMessagePlay(message: message)
    }

}
