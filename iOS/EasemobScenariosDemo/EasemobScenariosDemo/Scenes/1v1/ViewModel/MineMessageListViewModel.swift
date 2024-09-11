//
//  MineMessageListViewModel.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/14.
//

import UIKit
import EaseChatUIKit

final class MineMessageListViewModel: MessageListViewModel {
    
    required init(conversationId: String, type: ChatType) {
        super.init(conversationId: conversationId, type: type)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(endCallInsertMessageNeededReload), object: nil, queue: .main) { [weak self] _ in
            self?.refreshLatestMessages()
        }
    }
    
    override func audioMessagePlay(message: MessageEntity) {
        if EaseMob1v1CallKit.shared.onCalling {
            UIViewController.currentController?.showToast(toast: "正在通话中，请稍后再试")
            return
        }
        super.audioMessagePlay(message: message)
    }

    func refreshLatestMessages() {
        self.chatService?.loadMessages(start: self.driver?.dataSource.last?.messageId ?? "", pageSize: 20, searchMessage: true, completion: { [weak self] error, messages in
            self?.driver?.endRefreshing()
            if error == nil,messages.count > 0 {
                for message in messages {
                    self?.driver?.showMessage(message: message)
                }
            } else {
                consoleLogInfo("loadMessages error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
}
