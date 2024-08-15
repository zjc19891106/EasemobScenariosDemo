//
//  GiftsView.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/12.
//

import UIKit
import EaseChatUIKit

/// GiftsView event actions delegate
@objc public protocol GiftsViewActionEventsDelegate: NSObjectProtocol {
    
    /// Send button click
    /// - Parameter item: `GiftEntityProtocol`
    func onGiftSendClick(item: GiftEntityProtocol)
    
    /// Select a gift item.
    /// - Parameter item: `GiftEntityProtocol`
    func onGiftSelected(item: GiftEntityProtocol)
}

@objcMembers open class GiftsView: UIView {
        
    lazy private var eventHandlers: NSHashTable<GiftsViewActionEventsDelegate> = NSHashTable<GiftsViewActionEventsDelegate>.weakObjects()
    
    /// Add UI action handler.
    /// - Parameter actionHandler: ``GiftsViewActionEventsDelegate``
    public func addActionHandler(actionHandler: GiftsViewActionEventsDelegate) {
        if self.eventHandlers.contains(actionHandler) {
            return
        }
        self.eventHandlers.add(actionHandler)
    }

    /// Remove UI action handler.
    /// - Parameter actionHandler: ``GiftsViewActionEventsDelegate``
    public func removeEventHandler(actionHandler: GiftsViewActionEventsDelegate) {
        self.eventHandlers.remove(actionHandler)
    }

    var gifts = [GiftEntityProtocol]()

    lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (self.frame.width - 30) / 4.0, height: (110 / 84.0) * (self.frame.width - 30) / 4.0)
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    lazy var giftList: UICollectionView = {
        UICollectionView(frame: CGRect(x: 15, y: 0, width: self.frame.width - 30, height: ScreenHeight/2.0-60-BottomBarHeight), collectionViewLayout: self.flowLayout).registerCell(GiftEntityCell.self, forCellReuseIdentifier: "GiftEntityCell").delegate(self).dataSource(self).showsHorizontalScrollIndicator(false).backgroundColor(.clear).showsVerticalScrollIndicator(false)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// Gifts view init method.
    /// - Parameters:
    ///   - frame: frame
    ///   - gifts: Conform ``GiftEntityProtocol`` class instance array.
    @objc required public convenience init(frame: CGRect, gifts: [GiftEntityProtocol]) {
        self.init(frame: frame)
        self.gifts = gifts
        self.giftList.bounces = false
        self.addSubViews([self.giftList])
        self.backgroundColor = .clear
        self.giftList.isScrollEnabled = true
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        consoleLogInfo("deinit \(self.swiftClassName ?? "")", type: .debug)
    }
}

extension GiftsView: UICollectionViewDelegate,UICollectionViewDataSource,GiftEntityCellActionEvents {
    public func onSendClicked(item: GiftEntityProtocol) {
        for handler in self.eventHandlers.allObjects {
            handler.onGiftSendClick(item: item)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.gifts.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GiftEntityCell", for: indexPath) as? GiftEntityCell
        cell?.refresh(item: self.gifts[safe: indexPath.row])
        cell?.eventsDelegate = self
        return cell ?? GiftEntityCell()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        self.gifts.forEach { $0.selected = false }
        if let gift = self.gifts[safe: indexPath.row] {
            gift.selected = true
            for handler in self.eventHandlers.allObjects {
                handler.onGiftSelected(item: gift)
            }
        }
        self.giftList.reloadData()
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event)
    }

}


@objc public protocol GiftEntityCellActionEvents: NSObjectProtocol {
    func onSendClicked(item:GiftEntityProtocol)
}

/**
 A UICollectionViewCell subclass that displays a gift entity with an icon, name, and price. It also has a "Send" button that triggers a callback when tapped.
 */
@objcMembers open class GiftEntityCell: UICollectionViewCell {
    
    private var gift: GiftEntityProtocol?
    
    var eventsDelegate: GiftEntityCellActionEvents?
    
    public var sendCallback: ((GiftEntityProtocol?)->Void)?
    
    public lazy var cover: UIView = {
        UIView(frame:CGRect(x: 1, y: 5, width: self.contentView.frame.width-2, height: self.contentView.frame.height - 5)).cornerRadius(.small).layerProperties(UIColor.theme.primaryColor5, 1).backgroundColor(UIColor.theme.primaryColor95)
    }()
    
    public lazy var send: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: 0, y: self.cover.frame.height-28, width: self.cover.frame.width, height: 28)).backgroundColor(UIColor.theme.primaryColor5).title("Send".chat.localize, .normal).textColor(UIColor.theme.neutralColor98, .normal).font(UIFont.theme.labelMedium).addTargetFor(self, action: #selector(sendAction), for: .touchUpInside).cornerRadius(.small, [.bottomLeft,.bottomRight], .clear, 0)
    }()

    public lazy var icon: ImageView = {
        ImageView(frame: CGRect(x: self.contentView.frame.width / 2.0 - 24, y: 16.5, width: 48, height: 48)).contentMode(.scaleAspectFit)
    }()

    public lazy var name: UILabel = {
        UILabel(frame: CGRect(x: 0, y: self.icon.frame.maxY + 4, width: self.contentView.frame.width, height: 18)).textAlignment(.center).font(UIFont.theme.labelMedium).textColor(UIColor.theme.neutralColor1).backgroundColor(.clear)
    }()

    public lazy var displayValue: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: 0, y: self.name.frame.maxY + 1, width: self.contentView.frame.width, height: 15)).font(UIFont.theme.labelExtraSmall).textColor(UIColor.theme.neutralColor5, .normal).isUserInteractionEnabled(false).backgroundColor(.clear).image( UIImage(named: "dollar"), .normal)
    }()

    override required public init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = .clear
        self.contentView.addSubViews([self.cover, self.icon, self.name, self.displayValue])
        self.cover.addSubview(self.send)
//        self.displayValue.imageEdgeInsets(UIEdgeInsets(top: self.displayValue.imageEdgeInsets.top, left: -10, bottom: self.displayValue.imageEdgeInsets.bottom, right: self.displayValue.imageEdgeInsets.right))
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.icon.frame = CGRect(x: self.contentView.frame.width / 2.0 - 24, y: 16.5, width: 48, height: 48)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Refresh gift item view.
    /// - Parameter item: ``GiftEntityProtocol``
    @objc open func refresh(item: GiftEntityProtocol?) {
        self.gift = item
        self.contentView.isHidden = (item == nil)

        let url = item?.giftIcon ?? ""
        self.icon.image(with: url, placeHolder: UIImage(named: "gift_placeholder"))
        self.name.text = item?.giftName
        self.displayValue.setTitle(item?.giftPrice ?? "100", for: .normal)
        self.cover.isHidden = !(item?.selected ?? false)
        self.displayValue.frame = CGRect(x: 0, y: item!.selected ? self.icon.frame.maxY + 4:self.name.frame.maxY + 1, width: self.contentView.frame.width, height: 15)
        self.name.isHidden = item?.selected ?? false
    }
    
    @objc private func sendAction() {
        if let item = self.gift {
            self.eventsDelegate?.onSendClicked(item: item)
        }
        
    }
    
}

extension GiftEntityCell: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.cover.backgroundColor(style == .dark ? UIColor.theme.primaryColor2:UIColor.theme.primaryColor95)
        self.cover.layerProperties(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5, 1)
        self.send.backgroundColor(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5)
        self.name.textColor(style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1)
        self.displayValue.textColor(style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5, .normal)
    }
    
    
}

