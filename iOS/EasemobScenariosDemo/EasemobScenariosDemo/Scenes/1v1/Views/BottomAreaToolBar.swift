//
//  BottomAreaToolBar.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/7.
//

import UIKit
import EaseChatUIKit

@objc public protocol IBottomAreaToolBarDrive: NSObjectProtocol {
    
    /// You can call the method update item select state.
    /// - Parameters:
    ///   - index: Index
    ///   - select: `Bool`select value
    func updateItemSelectState(index: UInt, select: Bool)
    
    /// You can call the method update item red dot show or hidden.
    /// - Parameters:
    ///   - index: Index
    ///   - showRedDot: `Bool` showRedDot  value
    func updateItemRedDot(index: UInt, showRedDot: Bool)
    
    /// You can call then method update ChatBottomFunctionBar‘s data source.
    /// - Parameter items: `Array<ChatBottomItemProtocol>`
    func updateDatas(items: [ChatBottomItemProtocol])
}

/// ChatBottomFunctionBar actions delegate.
@objc public protocol BottomAreaToolBarActionEvents: NSObjectProtocol {
    
    /// ChatBottomFunctionBar each item click event.
    /// - Parameter item: ChatBottomItemProtocol
    func onBottomItemClicked(item: ChatBottomItemProtocol)
    
    /// When you tap `button` let's chat callback.
    func onKeyboardWillWakeup()
}

@objcMembers open class BottomAreaToolBar: UIView {

    lazy private var eventHandlers: NSHashTable<BottomAreaToolBarActionEvents> = NSHashTable<BottomAreaToolBarActionEvents>.weakObjects()
    
    
    /// Add UI action handler.
    /// - Parameter actionHandler: ``ChatBottomFunctionBarActionEvents``
    public func addActionHandler(actionHandler: BottomAreaToolBarActionEvents) {
        if self.eventHandlers.contains(actionHandler) {
            return
        }
        self.eventHandlers.add(actionHandler)
    }
    
    /// Remove UI action handler.
    /// - Parameter actionHandler: ``ChatBottomFunctionBarActionEvents``
    public func removeEventHandler(actionHandler: BottomAreaToolBarActionEvents) {
        self.eventHandlers.remove(actionHandler)
    }
    
    private var datas = [ChatBottomItemProtocol]()

    lazy var chatRaiser: UIButton = {
        UIButton(type: .custom).frame(.zero).backgroundColor(UIColor.theme.barrageLightColor2).cornerRadius((self.frame.height - 10) / 2.0).font(.systemFont(ofSize: 12, weight: .regular)).textColor(UIColor(white: 1, alpha: 0.8), .normal).addTargetFor(self, action: #selector(raiseAction), for: .touchUpInside).backgroundColor(UIColor.theme.barrageDarkColor1)
    }()

    lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: self.frame.height - 10, height: self.frame.height - 10)
        layout.minimumInteritemSpacing = 8
        layout.scrollDirection = .horizontal
        return layout
    }()

    lazy var toolBar: UICollectionView = {
        UICollectionView(frame: .zero, collectionViewLayout: self.flowLayout).delegate(self).dataSource(self).backgroundColor(.clear).registerCell(ChatBottomItemCell.self, forCellReuseIdentifier: "ChatBottomItemCell").showsVerticalScrollIndicator(false).showsHorizontalScrollIndicator(false)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// ChatBottomBar init method
    /// - Parameters:
    ///   - frame: CGRect
    ///   - datas: Array<ChatBottomItemProtocol>
    @objc(initWithFrame:datas:)
    required public init(frame: CGRect, datas: [ChatBottomItemProtocol] = []) {
        super.init(frame: frame)
        self.datas = datas
        self.addSubViews([self.chatRaiser, self.toolBar])
        self.chatRaiser.setImage(UIImage(named: "chatraise"), for: .normal)
        self.chatRaiser.setTitle(" " + "StartChat".localized(), for: .normal)
        self.chatRaiser.titleEdgeInsets = UIEdgeInsets(top: self.chatRaiser.titleEdgeInsets.top, left: 10, bottom: self.chatRaiser.titleEdgeInsets.bottom, right: 10)
        self.chatRaiser.imageEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 80)
        self.refreshToolBar(datas: datas)
        self.chatRaiser.contentHorizontalAlignment = .left
        self.backgroundColor = .clear
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    private func refreshToolBar(datas: [ChatBottomItemProtocol]) {
        self.datas.removeAll()
        self.datas = datas
        var toolBarWidth = (40 * CGFloat(datas.count)) + (CGFloat(datas.count) - 1) * 8 + 32
        if datas.count <= 0 {
            toolBarWidth = 0
            self.toolBar.frame = .zero
            self.toolBar.isHidden = true
        } else {
            self.toolBar.isHidden = false
            self.toolBar.frame = CGRect(x: self.frame.width-toolBarWidth+8, y: 0, width: toolBarWidth, height: self.frame.height)
        }
        if !self.chatRaiser.isHidden {
            self.chatRaiser.frame = CGRect(x: 15, y: 5, width: self.frame.width-30-toolBarWidth+8, height: self.frame.height - 10)
        }
        self.toolBar.reloadData()
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event)
    }
}

extension BottomAreaToolBar: UICollectionViewDelegate, UICollectionViewDataSource {
    
    @objc func raiseAction() {
        for handler in self.eventHandlers.allObjects {
            handler.onKeyboardWillWakeup()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.datas.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatBottomItemCell", for: indexPath) as? ChatBottomItemCell
        if let entity = self.datas[safe:indexPath.row] {
            cell?.refresh(item: entity)
        }
        return cell ?? ChatBottomItemCell()
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let entity = self.datas[safe:indexPath.row] else { return }
        for handler in self.eventHandlers.allObjects {
            handler.onBottomItemClicked(item: entity)
        }
        self.toolBar.reloadItems(at: [indexPath])
    }
}

extension BottomAreaToolBar: IBottomAreaToolBarDrive {
    public func updateItemSelectState(index: UInt, select: Bool) {
        self.datas[safe: Int(index)]?.selected = select
    }
    
    public func updateItemRedDot(index: UInt, showRedDot: Bool) {
        self.datas[safe: Int(index)]?.showRedDot = showRedDot
    }
    
    public func updateDatas(items: [ChatBottomItemProtocol]) {
        self.refreshToolBar(datas: items)
    }
    
}

extension BottomAreaToolBar: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.chatRaiser.backgroundColor(style == .dark ? UIColor.theme.barrageLightColor2:UIColor.theme.barrageDarkColor1)
        self.toolBar.reloadData()
    }
    
}


@objcMembers open class ChatBottomItemCell: UICollectionViewCell {

    public lazy var container: UIImageView = {
        UIImageView(frame: CGRect(x: 0, y: 0, width: self.contentView.frame.width, height: self.contentView.frame.height)).contentMode(.scaleAspectFit).backgroundColor(UIColor.theme.barrageLightColor2).cornerRadius(self.contentView.frame.height / 2.0)
    }()

    public lazy var icon: UIImageView = {
        UIImageView(frame: CGRect(x: 0, y: 0, width: self.contentView.frame.width, height: self.contentView.frame.height)).contentMode(.scaleAspectFill).backgroundColor(.clear)
    }()

    public let redDot = UIView().backgroundColor(.red).cornerRadius(3)

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.contentView.addSubViews([self.container,self.redDot,self.icon])
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        let r = contentView.frame.width / 2.0
        self.container.cornerRadius(r)
        let length = CGFloat(ceilf(Float(r) / sqrt(2)))
        self.redDot.frame = CGRect(x: frame.width / 2.0 + length, y: contentView.frame.height / 2.0 - length, width: 6, height: 6)
        self.icon.frame = CGRect(x: 7, y: 7, width: contentView.frame.width - 14, height: contentView.frame.height - 14)
    }
    
    /// Refresh subviews.
    /// - Parameter item: ``ChatBottomItemProtocol``
    @objc(refreshWithItem:)
    public func refresh(item: ChatBottomItemProtocol) {
        self.icon.image = item.selected ? item.selectedImage:item.normalImage
        self.redDot.isHidden = !item.showRedDot
    }

}

extension ChatBottomItemCell: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.container.backgroundColor(style == .dark ? UIColor.theme.barrageLightColor2:UIColor.theme.barrageDarkColor1)
    }
}


/// ChatBottomBar item protocol
@objc public protocol ChatBottomItemProtocol: NSObjectProtocol {
    
    /// Whether show red dot
    @objc var showRedDot: Bool {set get}
    
    /// Whether selected
    @objc var selected: Bool {set get}
    
    /// When `selected` is `true` show image.
    @objc var selectedImage: UIImage? {set get}
    
    /// Normal image
    @objc var normalImage: UIImage? {set get}
    
    /// Tag
    @objc var type: Int {set get}
    
    /// Action
    @objc var action: ((ChatBottomItemProtocol) -> Void)? {set get}

}
