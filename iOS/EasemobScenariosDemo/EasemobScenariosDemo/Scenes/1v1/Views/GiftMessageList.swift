//
//  GiftMessageList.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/7.
//

import UIKit
import EaseChatUIKit

@objc public protocol IGiftMessageListDrive {
    /// Refresh the UI after receiving the gift
    /// - Parameter gift: GiftEntityProtocol
    func receiveGift(gift: GiftEntityProtocol)
}

/// A protocol that defines optional methods for transforming animations in the GiftMessageList.
@objc public protocol GiftMessageListTransformAnimationDataSource: NSObjectProtocol {
    
    /// An optional method that returns the row height for the GiftMessageList.
    @objc optional func rowHeight() -> CGFloat
    
    /// An optional method that returns the zoom scale for the x-axis of the GiftMessageList.
    @objc optional func zoomScaleX() -> CGFloat
    
    /// An optional method that returns the zoom scale for the y-axis of the GiftMessageList.
    @objc optional func zoomScaleY() -> CGFloat
}

@objc public protocol GiftEntityProtocol: NSObjectProtocol {
    var giftId: String {set get}
    var giftName: String {set get}
    var giftPrice: String {set get}
    var giftCount: Int {set get}
    var giftIcon: String {set get}
    /// Developers can upload a special effect to the server that matches the gift ID. The special effect name is the ID of the gift. When entering the room, the SDK will pull the gift resource and download the special effect corresponding to the gift ID. If the value of the gift received is true, the corresponding special effect will be found in full screen. For playback and broadcasting, the gift resource and special effects resource download server can create a web page for users to use. After each app is started, the gift resources are pre-downloaded and cached to disk for UIKit to access before loading the scene.
    var giftEffect: String {set get}
    
    var selected: Bool {set get}
    
    ///  Do you want to close the pop-up window after sending a gift?`true` mens dialog close.
    var sentThenClose: Bool {set get}
    
    var sendUser: EaseProfileProtocol? {set get}
    
    func toJsonObject() -> Dictionary<String,Any>
}

@objc open class GiftMessageList: UIView {
    
    public weak var dataSource: GiftMessageListTransformAnimationDataSource?
    
    public var gifts = [GiftEntityProtocol]() {
        didSet {
            if self.gifts.count > 0 {
                DispatchQueue.main.async {
                    self.cellAnimation()
                }
            }
        }
    }
    
    private var currentTask: DispatchWorkItem?
    
    private let queue = DispatchQueue(label: "com.example.giftListHandlerQueue")

    private var lastOffsetY = CGFloat(0)

    public lazy var giftList: UITableView = {
        UITableView(frame: CGRect(x: 5, y: 0, width: self.frame.width - 20, height: self.frame.height), style: .plain).tableFooterView(UIView()).separatorStyle(.none).showsVerticalScrollIndicator(false).showsHorizontalScrollIndicator(false).delegate(self).dataSource(self).backgroundColor(.clear).isUserInteractionEnabled(false)
    }()
    
    private lazy var gradientLayer: CAGradientLayer = {
        CAGradientLayer().startPoint(CGPoint(x: 0, y: 0)).endPoint(CGPoint(x: 0, y: 0.1)).colors([UIColor.clear.withAlphaComponent(0).cgColor, UIColor.clear.withAlphaComponent(1).cgColor]).locations([NSNumber(0), NSNumber(1)]).rasterizationScale(UIScreen.main.scale).frame(self.blurView.frame)
    }()
    
    private lazy var blurView: UIView = {
        UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)).backgroundColor(.clear)
    }()
    /// Init method.
    /// - Parameters:
    ///   - frame: Layout coordinates
    ///   - source: ``GiftMessageListTransformAnimationDataSource``
    @objc public required init(frame: CGRect, source: GiftMessageListTransformAnimationDataSource? = nil) {
        self.dataSource = source
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.addSubViews([self.blurView,self.giftList])
        self.giftList.isScrollEnabled = false
        self.giftList.isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        consoleLogInfo("deinit \(self.swiftClassName ?? "")", type: .debug)
    }
}


extension GiftMessageList: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.gifts.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        self.dataSource?.rowHeight?() ?? 58
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        cell.alpha = 0
        cell.isUserInteractionEnabled = false
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: 1)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "GiftMessageCell") as? GiftMessageCell
        if cell == nil {
            cell = GiftMessageCell(style: .default, reuseIdentifier: "GiftMessageCell")
        }
        if let entity = self.gifts[safe: indexPath.row] {
            cell?.refresh(item: entity)
        }
        return cell ?? GiftMessageCell()
    }

    internal func cellAnimation() {
        DispatchQueue.main.async {
            self.alpha = 1
            self.isHidden = false
            self.giftList.reloadData()
            var indexPath = IndexPath(row: 0, section: 0)
            if self.gifts.count >= 2 {
                indexPath = IndexPath(row: self.giftList.numberOfRows(inSection: 0) - 2, section: 0)
            }
            if self.gifts.count > 1 {
                let cell = self.giftList.cellForRow(at: indexPath) as? GiftMessageCell
                UIView.animate(withDuration: 0.3) {
                    cell?.alpha = 0.75
                    cell?.contentView.transform = CGAffineTransform(scaleX: self.dataSource?.zoomScaleX?() ?? 0.75, y: self.dataSource?.zoomScaleY?() ?? 0.75)
                    self.giftList.scrollToRow(at: IndexPath(row: self.gifts.count - 1, section: 0), at: .top, animated: false)
                }
            }
            self.delayedTask()
        }
    }
    
    func delayedTask() {
        self.currentTask?.cancel()
        // Create Task
        let task = DispatchWorkItem { [weak self] in
            self?.performDelayTask()
        }
        self.currentTask = task
        self.queue.asyncAfter(deadline: .now() + 3, execute: task)
    }
    
    func performDelayTask() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.alpha = 0
                self.isHidden = true
            } completion: { _ in
                self.gifts.removeAll()
            }
        }
    }
    
    
}

extension GiftMessageList: GiftMessageListTransformAnimationDataSource {
    public func rowHeight() -> CGFloat {
        58
    }
    
    public func zoomScaleX() -> CGFloat {
        0.75
    }
    
    public func zoomScaleY() -> CGFloat {
        0.75
    }
}

extension GiftMessageList: IGiftMessageListDrive {
    public func receiveGift(gift: GiftEntityProtocol) {
        self.gifts.append(gift)
    }
}


@objcMembers open class GiftMessageCell: UITableViewCell {

    public var gift: GiftEntityProtocol?
    
    public lazy var lightEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
    
    public lazy var darkEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
    
    public lazy var container: UIView = {
        UIView(frame: CGRect(x: 0, y: 5, width: self.contentView.frame.width, height: self.contentView.frame.height - 10)).backgroundColor(UIColor.theme.barrageDarkColor1).isUserInteractionEnabled(false)
    }()
    
    public lazy var blur: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: self.lightEffect)
        blurView.frame = CGRect(x: 0, y: 0, width: self.contentView.frame.width, height: self.contentView.frame.height - 10)
        return blurView
    }()
    
    public lazy var avatar: ImageView = ImageView(frame: CGRect(x: 5, y: 5, width: self.frame.width / 5.0, height: self.frame.width / 5.0)).contentMode(.scaleAspectFit)
    
    public lazy var userName: UILabel = {
        UILabel(frame: CGRect(x: self.avatar.frame.maxX + 6, y: 8, width: self.frame.width / 5.0 * 2 - 12, height: 15)).font(UIFont.theme.headlineExtraSmall).textColor(UIColor.theme.neutralColor100)
    }()
    
    public lazy var giftName: UILabel = {
        UILabel(frame: CGRect(x: self.avatar.frame.maxX + 6, y: self.userName.frame.maxY, width: self.frame.width / 5.0 * 2 - 12, height: 15)).font(UIFont.theme.bodySmall).textColor(UIColor.theme.neutralColor100)
    }()
    
    public lazy var giftIcon: ImageView = {
        ImageView(frame: CGRect(x: self.frame.width / 5.0 * 3, y: 0, width: self.frame.width / 5.0, height: self.contentView.frame.height)).contentMode(.scaleAspectFit)
    }()
    
    public lazy var giftNumbers: UILabel = {
        UILabel(frame: CGRect(x: self.frame.width / 5.0 * 4 + 8, y: 10, width: self.frame.width / 5.0 - 16, height: self.frame.height - 20)).font(UIFont.theme.giftNumberFont).textColor(UIColor.theme.neutralColor100)
    }()

    override required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.isUserInteractionEnabled = false
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        self.contentView.addSubview(self.container)
        self.container.addSubViews([self.blur,self.avatar, self.userName, self.giftName, self.giftIcon, self.giftNumbers])
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.container.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        self.container.createGradient([], [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 1)],[0,1])
        self.container.cornerRadius(self.container.frame.height/2.0)
        self.blur.frame = CGRect(x: 0, y: 0, width: self.contentView.frame.width, height: self.contentView.frame.height)
        self.avatar.frame = CGRect(x: 5, y: 5, width: self.container.frame.height - 10, height: self.container.frame.height - 10)
        self.avatar.cornerRadius(Appearance.avatarRadius)
        self.userName.frame = CGRect(x: self.avatar.frame.maxX + 6, y: self.container.frame.height/2.0 - 15, width: frame.width / 5.0 * 2 - 12, height: 15)
        self.giftName.frame = CGRect(x: self.avatar.frame.maxX + 6, y: self.container.frame.height/2.0 , width: frame.width / 5.0 * 2, height: 15)
        self.giftIcon.frame = CGRect(x: frame.width / 5.0 * 3, y: 0, width: self.container.frame.height, height: self.container.frame.height)
        self.giftNumbers.frame = CGRect(x: self.giftIcon.frame.maxX + 5, y: 5, width: self.container.frame.width - self.giftIcon.frame.maxX - 5, height: self.container.frame.height - 5)
    }
    
    /// Refresh view on receive gift.
    /// - Parameter item: ``GiftEntityProtocol``
    @objc(refreshWithItem:)
    open func refresh(item: GiftEntityProtocol) {
        if self.gift == nil {
            self.gift = item
        }
        if let avatarURL = item.sendUser?.avatarURL {
            self.avatar.image(with:avatarURL, placeHolder: Appearance.avatarPlaceHolder)
        }
        var nickname = item.sendUser?.nickname ?? ""
        if nickname.isEmpty {
            nickname = "匿名用户-\(item.sendUser?.id ?? "")"
        }
        self.userName.text = nickname
        self.giftName.text = "Sent ".localized() + (item.giftName)
        self.giftIcon.image(with: item.giftIcon, placeHolder:  UIImage(named: "gift_placeholder"))
        self.giftNumbers.text = "X \(item.giftCount)"
    }


}


extension GiftMessageCell: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.blur.effect = style == .dark ? self.darkEffect:self.lightEffect
        self.container.backgroundColor = style == .dark ? UIColor.theme.barrageLightColor2:UIColor.theme.barrageDarkColor1
    }
    
    
}
