//
//  ConversationsPopViewController.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/9.
//

import UIKit
import EaseChatUIKit

final class ConversationsPopViewController: UIViewController, PresentedViewType {
    
    var presentedViewComponent: EaseChatUIKit.PresentedViewComponent? = PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: StatusBarHeight+78),destination: .topBaseline)
    
    lazy var cardConversationView: CardConversationsView = {
        CardConversationsView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: StatusBarHeight+78), infos: self.messages)
    }()
    
    var messages = [EaseChatUIKit.ChatMessage]()
    
    var dismissClosure: ((ConversationInfo?) -> Void)?
    
    required init(messages: [EaseChatUIKit.ChatMessage],dismissClosure: @escaping ((ConversationInfo?) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        self.messages = messages
        self.dismissClosure = dismissClosure
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubview(self.cardConversationView)
        self.cardConversationView.dismissClosure = { [weak self]  in
            self?.dismissClosure?($0)
        }
    }
    
    func refresh(messages: [EaseChatUIKit.ChatMessage]) {
        self.cardConversationView.refresh(messages: messages)
    }
    
    func append(message: EaseChatUIKit.ChatMessage) {
        self.cardConversationView.newConversation(with: message)
    }

}
