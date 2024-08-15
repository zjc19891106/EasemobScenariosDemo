//
//  GiftsViewController.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/12.
//

import UIKit
import EaseChatUIKit

@objcMembers open class GiftsViewController: UIViewController {
    
    private var gifts = [GiftEntityProtocol]()
    
    private var giftClosure: ((GiftEntityProtocol) -> Void)?
        
    public private(set) lazy var giftsView: GiftsView = {
        GiftsView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height-BottomBarHeight), gifts: self.gifts)
    }()
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// GiftsViewController init method.
    /// - Parameters:
    ///   - gifts: `Array<GiftEntityProtocol>` data source.
    ///   - sendClosure: Send gift closure.
    @objc(initWithGifts:sendClosure:)
    required public init(gifts: [GiftEntityProtocol],sendClosure: @escaping (GiftEntityProtocol) -> Void) {
        self.gifts = gifts
        self.giftClosure = sendClosure
        super.init(nibName: nil, bundle: .main)
    }
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubview(self.giftsView)
        self.giftsView.addActionHandler(actionHandler: self)
    }
    
    deinit {
        consoleLogInfo("deinit \(self.swiftClassName ?? "")", type: .debug)
    }
}

extension GiftsViewController: GiftsViewActionEventsDelegate {
    /// Send button click
    /// - Parameter item: `GiftEntityProtocol`
    open func onGiftSendClick(item: GiftEntityProtocol) {
        //It can be called after completing the interaction related to the gift sending interface with the server.
        item.sendUser = EaseChatUIKitContext.shared?.currentUser
        self.giftClosure?(item)
        if !item.giftEffect.isEmpty {
            self.dismiss(animated: true)
        }
    }
    
    /// Select a gift item.
    /// - Parameter item: `GiftEntityProtocol`
    open func onGiftSelected(item: GiftEntityProtocol) {
        
    }
}
