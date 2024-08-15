//
//  MessageList.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/7.
//

import UIKit
import EaseChatUIKit


var chatViewWidth: CGFloat = 0

/// MessageList's Drive.
@objc public protocol IMessageListDrive: NSObjectProtocol {
    
    /// When you receive or will send a message.
    /// - Parameter message: ``ChatMessage``
    ///   - gift: ``GiftEntityProtocol``
    @objc(showWithNewMessage:gift:)
    func showNewMessage(message: ChatMessage,gift: GiftEntityProtocol?)
    
    /// When you want modify or translate a message.
    /// - Parameter message: ``ChatMessage``
    @objc(refreshWithMessage:)
    func refreshMessage(message: ChatMessage)
    
    /// When you want delete message.
    /// - Parameter message: ``ChatMessage``
    @objc(removeWithMessage:)
    func removeMessage(message: ChatMessage)
    
    /// Clean data source.
    func cleanMessages()
}

/// MessageList action events handler.
@objc public protocol MessageListActionEventsHandler: NSObjectProtocol {
    
    /// The method called on message  long pressed.
    /// - Parameter message: ``ChatMessage``
    func onMessageLongPressed(message: ChatMessage)
    
    /// The method called on message  clicked.
    /// - Parameter message: ``ChatMessage``
    func onMessageClicked(message: ChatMessage)
}

@objcMembers open class MessageList: UIView {
    
    lazy private var eventHandlers: NSHashTable<MessageListActionEventsHandler> = NSHashTable<MessageListActionEventsHandler>.weakObjects()
    
    /// Add UI actions handler.
    /// - Parameter actionHandler: ``MessageListActionEventsHandler``
    public func addActionHandler(actionHandler: MessageListActionEventsHandler) {
        if self.eventHandlers.contains(actionHandler) {
            return
        }
        self.eventHandlers.add(actionHandler)
    }
    
    /// Remove UI action handler.
    /// - Parameter actionHandler: ``MessageListActionEventsHandler``
    public func removeEventHandler(actionHandler: MessageListActionEventsHandler) {
        self.eventHandlers.remove(actionHandler)
    }

    private var lastOffsetY = CGFloat(0)

    private var cellOffset = CGFloat(0)
    
    private var hover = false
    
    private var moreMessagesCount = 0  {
        willSet {
            self.moreMessages.isHidden = newValue <= 0
        }
    }

    public var messages: [ChatEntity]? = [ChatEntity]()

    public lazy var chatView: UITableView = {
        UITableView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), style: .plain).delegate(self).dataSource(self).separatorStyle(.none).tableFooterView(UIView()).backgroundColor(.clear).showsVerticalScrollIndicator(false).isUserInteractionEnabled(true)
    }()

    private lazy var gradientLayer: CAGradientLayer = {
        CAGradientLayer().startPoint(CGPoint(x: 0, y: 0)).endPoint(CGPoint(x: 0, y: 0.1)).colors([UIColor.clear.withAlphaComponent(0).cgColor, UIColor.clear.withAlphaComponent(1).cgColor]).locations([NSNumber(0), NSNumber(1)]).rasterizationScale(UIScreen.main.scale).frame(self.blurView.frame)
    }()

    private lazy var blurView: UIView = {
        UIView(frame: CGRect(x: 0, y: 0, width: chatViewWidth, height: self.frame.height)).backgroundColor(.clear).isUserInteractionEnabled(true)
    }()
    
    lazy var moreMessages: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: 20, y: self.chatView.frame.maxY-28, width: 180, height: 26)).cornerRadius(.large).font(UIFont.theme.labelMedium).title("    \(self.moreMessagesCount) "+"new messages".localized(), .normal).addTargetFor(self, action: #selector(scrollTableViewToBottom), for: .touchUpInside)
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        chatViewWidth = frame.width
        self.addSubViews([self.blurView])
        self.blurView.layer.mask = self.gradientLayer
        self.blurView.addSubview(self.chatView)
        self.chatView.addSubview(self.moreMessages)
        self.moreMessages.isHidden = true
        self.chatView.bounces = false
        self.chatView.allowsSelection = false
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longGesture(gesture:)))
        longGesture.minimumPressDuration = 0.5
        self.chatView.addGestureRecognizer(longGesture)
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        consoleLogInfo("deinit \(self.swiftClassName ?? "")", type: .debug)
    }

}

extension MessageList:UITableViewDelegate, UITableViewDataSource {
    
    @objc public func scrollTableViewToBottom() {
        if self.messages?.count ?? 0 > 1 {
            self.chatView.reloadData()
            let lastIndexPath = IndexPath(row: self.chatView.numberOfRows(inSection: 0) - 1, section: 0)
            if lastIndexPath.row >= 0 {
                self.chatView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
            }
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.messages?.count ?? 0
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = self.messages?[safe: indexPath.row]?.height ?? 60
        return height
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell") as? ChatMessageCell
        if cell == nil {
            cell = ChatMessageCell(displayStyle: message1v1Style, reuseIdentifier: "ChatMessageCell")
        }
        guard let entity = self.messages?[safe: indexPath.row] else { return ChatMessageCell() }
        cell?.refresh(chat: entity)
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.contentOffset.y - self.lastOffsetY < 0 {
            self.cellOffset -= cell.frame.height
        } else {
            self.cellOffset += cell.frame.height
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        for handler in self.eventHandlers.allObjects {
            if let message = self.messages?[safe: indexPath.row]?.message {
                handler.onMessageClicked(message: message)
            }
        }
    }
        
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.hover = true
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let indexPath = self.chatView.indexPathForRow(at: scrollView.contentOffset) ?? IndexPath(row: 0, section: 0)
        let cell = self.chatView.cellForRow(at: indexPath)
        let maxAlphaOffset = cell?.frame.height ?? 40
        let offsetY = scrollView.contentOffset.y
        let alpha = (maxAlphaOffset - (offsetY - self.cellOffset)) / maxAlphaOffset
        if offsetY - lastOffsetY > 0 {
            UIView.animate(withDuration: 0.3) {
                cell?.alpha = alpha
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                cell?.alpha = 1
            }
        }
        self.lastOffsetY = offsetY
        if self.lastOffsetY == 0 {
            self.cellOffset = 0
        }
        let contentHeight = scrollView.contentSize.height
        let tableHeight = scrollView.bounds.size.height
        
        if offsetY > contentHeight - tableHeight {
            self.hover = false
        }
        
        if indexPath.row - self.moreMessagesCount == 0 {
            self.moreMessagesCount = 0
        }
    }
    
    @objc func longGesture(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: self.chatView)
            if let indexPath = self.chatView.indexPathForRow(at: touchPoint),let _ = self.chatView.cellForRow(at: indexPath) as? ChatMessageCell {
                for handler in self.eventHandlers.allObjects {
                    if let message = self.messages?[safe: indexPath.row]?.message {
                        handler.onMessageLongPressed(message: message)
                    }
                }
            }
        }
    }

}

extension MessageList: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.moreMessages.backgroundColor(style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98)
        self.moreMessages.textColor(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5, .normal)
        self.moreMessages.image(UIImage(named: "more_messages")?.withTintColor(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5), .normal)
    }
}

extension MessageList: IMessageListDrive {
    public func cleanMessages() {
        self.messages?.removeAll()
        self.chatView.reloadData()
    }
    
    public func removeMessage(message: ChatMessage) {
        self.messages?.removeAll(where: { $0.message.messageId == message.messageId })
        self.chatView.reloadData()
    }
    
    public func refreshMessage(message: ChatMessage) {
        if let index = self.messages?.lastIndex(where: { $0.message.messageId == message.messageId }) {
            let entity = self.messages?[safe: index]
            self.messages?[index] = self.convertMessageToRender(message: message, gift: entity?.gift)
            self.chatView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
    
    public func showNewMessage(message: ChatMessage,gift: GiftEntityProtocol?) {
        self.messages?.append(self.convertMessageToRender(message: message, gift: gift))
        if message.from == ChatClient.shared().currentUsername {
            self.moreMessagesCount = 0
            self.chatView.reloadDataSafe()
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                self.scrollTableViewToBottom()
            }
        } else {
            if !self.hover {
                self.moreMessagesCount = 0
                self.chatView.reloadDataSafe()
                DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                    self.scrollTableViewToBottom()
                }
            } else {
                self.moreMessagesCount += 1
                var count = "\(self.moreMessagesCount)"
                if self.moreMessagesCount > 99 {
                    count = "99+ "
                }
                self.moreMessages.setTitle("  \(count) "+"new messages".localized(), for: .normal)
            }
        }
    }
    
    private func convertMessageToRender(message: ChatMessage,gift: GiftEntityProtocol?) -> ChatEntity {
        let entity = ChatEntity()
        entity.message = message
        entity.gift = gift
        entity.attributeText = entity.attributeText
        entity.width = entity.width
        entity.height = entity.height
        return entity
    }
}

extension UITableView {
    /// Dequeues a UICollectionView Cell with a generic type and indexPath
    /// - Parameters:
    ///   - type: A generic cell type
    ///   - indexPath: The indexPath of the row in the UICollectionView
    /// - Returns: A Cell from the type passed through
    func dequeueReusableCell<Cell: UITableViewCell>(with type: Cell.Type, reuseIdentifier: String) -> Cell? {
        dequeueReusableCell(withIdentifier: reuseIdentifier) as? Cell
    }
    
    @objc public func reloadDataSafe() {
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
}

public let message1v1Style = ChatMessageDisplayContentStyle.hideUserIdentity

@objcMembers open class ChatMessageCell: UITableViewCell {
    
    public private(set) var style: ChatMessageDisplayContentStyle = message1v1Style
    
    public private(set) lazy var container: UIView = {
        self.createContainer()
    }()
    
    @objc open func createContainer() -> UIView {
        UIView(frame: CGRect(x: 15, y: 6, width: self.contentView.frame.width - 30, height: self.frame.height - 6)).backgroundColor( UIColor.theme.barrageLightColor2).cornerRadius(.small)
    }
    
    public private(set) lazy var time: UILabel = {
        UILabel(frame: CGRect(x: 8, y: 10, width: 40, height: 18)).font(UIFont.theme.bodyMedium).textColor(UIColor.theme.secondaryColor8).textAlignment(.center).backgroundColor(.clear)
    }()
    
    public private(set) lazy var identity: ImageView = {
        var originX = 6
        switch self.style {
        case .all,.hideAvatar:
            originX += Int(self.time.frame.maxX)
        default:
            originX = originX
            break
        }
        return ImageView(frame: CGRect(x: originX, y: 10, width: 18, height: 18)).backgroundColor(.clear).cornerRadius(Appearance.avatarRadius)
    }()
    
    public private(set) lazy var avatar: ImageView = {
        var originX = 6
        switch self.style {
        case .all,.hideTime:
            originX += Int(self.identity.frame.maxX)
        case .hideUserIdentity:
            originX += Int(self.time.frame.maxX)
        case .hideTimeAndUserIdentity:
            originX = originX
        default:
            break
        }
        return ImageView(frame: CGRect(x: originX, y: 10, width: 18, height: 18)).backgroundColor(.clear).cornerRadius(Appearance.avatarRadius)
    }()
    
    public private(set) lazy var content: UILabel = {
        return UILabel(frame: CGRect(x: 10, y: 7, width: self.container.frame.width - 20, height: self.container.frame.height - 18)).backgroundColor(.clear).numberOfLines(0)
    }()
    
    public private(set) lazy var giftIcon: ImageView = {
        ImageView(frame: CGRect(x: self.content.frame.width-22, y: self.content.frame.height-10, width: 18, height: 18)).backgroundColor(.clear)
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    /// ChatBarrageCell init method
    /// - Parameters:
    ///   - displayStyle: ``ChatMessageDisplayContentStyle``
    ///   - reuseIdentifier: reuse identifier
    @objc(initWithDisplayStyle:reuseIdentifier:)
    required public init(displayStyle: ChatMessageDisplayContentStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.style = displayStyle
        self.contentView.addSubview(self.container)
        switch displayStyle {
        case .all:
            self.container.addSubViews([self.time,self.identity,self.avatar,self.content])
        case .hideTime:
            self.container.addSubViews([self.identity,self.avatar,self.content])
        case .hideUserIdentity:
            self.container.addSubViews([self.time,self.avatar,self.content])
        case .hideAvatar:
            self.container.addSubViews([self.time,self.identity,self.content])
        case .hideTimeAndUserIdentity:
            self.container.addSubViews([self.avatar,self.content])
        case .hideTimeAndAvatar:
            self.container.addSubViews([self.identity,self.content])
        case .hideUserIdentityAndAvatar:
            self.container.addSubViews([self.time,self.content])
        case .hideTimeAndUserIdentityAndAvatar:
            self.container.addSubview(self.content)
        default:
            break
        }
        self.container.addSubview(self.giftIcon)
        self.giftIcon.isHidden = true
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// Refresh the entity that renders the chat barrage, which contains height, width and rich text cache.
    /// - Parameter chat: ``ChatEntity``
    @objc(refreshWithChatEntity:)
    open func refresh(chat: ChatEntity) {
        self.time.text = chat.showTime
        self.avatar.image(with: chat.message.user?.avatarURL ?? "", placeHolder: Appearance.avatarPlaceHolder)
        self.content.attributedText = chat.attributeText
        self.container.frame = CGRect(x: 15, y: 6, width: chat.width + 24, height: chat.height - 6)
//        self.content.preferredMaxLayoutWidth =  self.container.frame.width - 24
        self.content.frame = CGRect(x: 10, y: self.container.frame.minY, width:  self.container.frame.width - 24, height:  self.container.frame.height - 16)
        self.giftIcon.frame = CGRect(x: self.container.frame.width-26, y: (self.container.frame.height-18)/2.0, width: 18, height: 18)
        self.giftIcon.isHidden = chat.gift == nil
        if let item = chat.gift {
            self.giftIcon.image(with: item.giftIcon, placeHolder: UIImage(named: "gift_placeholder"))
        }
    }
}


extension ChatMessageCell: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.container.backgroundColor(style == .dark ? UIColor.theme.barrageLightColor2:UIColor.theme.barrageDarkColor1)
    }
    
}


fileprivate let gift_tail_indent: CGFloat = 26

/// An enumeration that represents the different styles of a chat  cell.Time,level and avatar can be hidden
@objc public enum ChatMessageDisplayContentStyle: UInt {
    case all = 1
    case hideTime
    case hideAvatar
    case hideUserIdentity
    case hideTimeAndAvatar
    case hideTimeAndUserIdentity
    case hideUserIdentityAndAvatar
    case hideTimeAndUserIdentityAndAvatar
}

/// A class that represents a chat entity, which includes a message, a timestamp, attributed text, height, and width.
@objc open class ChatEntity: NSObject {
    
    /// The message associated with the chat entity.
    lazy public var message: ChatMessage = ChatMessage()
    
    /// The time at which the message was sent, formatted as "HH:mm".
    lazy public var showTime: String = {
        let date = Date(timeIntervalSince1970: Double(self.message.timestamp)/1000)
        return date.chat.dateString("HH:mm")
    }()
    
    /// The attributed text of the message, including the user's nickname, message text, and emojis.
    lazy public var attributeText: NSAttributedString = self.convertAttribute()
        
    /// The height of the chat entity, calculated based on the attributed text and the width of the chat view.
    lazy public var height: CGFloat =  {
        let cellHeight = UILabel().numberOfLines(0).attributedText(self.attributeText).sizeThatFits(CGSize(width: chatViewWidth - 54, height: 9999)).height + 26
        return cellHeight
    }()
    
    /// The width of the chat entity, calculated based on the attributed text and the width of the chat view.
    lazy public var width: CGFloat = {
        let cellWidth = UILabel().numberOfLines(0).attributedText(self.attributeText).sizeThatFits(CGSize(width: chatViewWidth - 54, height: 9999)).width+(self.gift != nil ? gift_tail_indent:0)
        return cellWidth
    }()
    
    /// Chat cell display gift info.Need to set it.``GiftEntityProtocol``
    lazy public var gift: GiftEntityProtocol? = nil
    
    /// Converts the message text into an attributed string, including the user's nickname, message text, and emojis.
    @objc open func convertAttribute() -> NSAttributedString {
        let userId = self.message.from
        var nickname = self.message.user?.nickname ?? ""
        if nickname.isEmpty {
            nickname = "匿名用户-\(userId)"
        }
        var text = NSMutableAttributedString {
            AttributedText(nickname).foregroundColor(Color.theme.primaryColor8).font(UIFont.theme.labelMedium).paragraphStyle(self.paragraphStyle())
        }
        if self.message.body.type == .custom,let body = self.message.body as? ChatCustomMessageBody {
            switch body.event {
            case EaseMob1v1ChatGift:
                if let item = self.gift {
                    let giftText = " "+item.giftName+" "+"× \(item.giftCount)"
                    text.append(NSMutableAttributedString {
                        AttributedText(giftText).foregroundColor(Color.theme.neutralColor98).font(UIFont.theme.labelMedium).paragraphStyle(self.paragraphStyle())
                    })
                }
            default:
                break
            }
            
        } else {
            if self.message.translation != nil,let translation = message.translation {
                text.append(NSAttributedString {
                    AttributedText(" : "+translation).foregroundColor(Color.theme.neutralColor98).font(UIFont.theme.bodyMedium).paragraphStyle(self.paragraphStyle())
                })
            } else {
                text.append(NSAttributedString {
                    AttributedText(" : "+self.message.text).foregroundColor(Color.theme.neutralColor98).font(UIFont.theme.bodyMedium).paragraphStyle(self.paragraphStyle())
                })
            }
            let string = text.string as NSString
            
            for symbol in ChatEmojiConvertor.shared.emojis {
                if string.range(of: symbol).location != NSNotFound {
                    let ranges = text.string.chat.rangesOfString(symbol)
                    text = ChatEmojiConvertor.shared.convertEmoji(input: text, ranges: ranges, symbol: symbol, imageBounds: CGRect(x: 0, y: -3, width: 16, height: 16))
                    text.addAttribute(.paragraphStyle, value: self.paragraphStyle(), range: NSMakeRange(0, text.length))
                    text.addAttribute(.font, value: UIFont.theme.bodyMedium, range: NSMakeRange(0, text.length))
                }
            }
        }
        return text
    }
    
    /// Returns a paragraph style object with the first line head indent set based on the appearance of the chat cell.
    @objc open func paragraphStyle() -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = self.firstLineHeadIndent()
        paragraphStyle.lineHeightMultiple = 1.08
        return paragraphStyle
    }
    
    /// Returns the distance of the first line head indent based on the appearance of the chat cell.
    @objc open func firstLineHeadIndent() -> CGFloat {
        var distance:CGFloat = 0
        switch message1v1Style {
        case .all: distance = 90
        case .hideTime: distance = 50
        case .hideUserIdentityAndAvatar: distance = 46
        case .hideTimeAndUserIdentityAndAvatar: distance = 8
        case .hideAvatar,.hideUserIdentity: distance = 68
        case .hideTimeAndUserIdentity,.hideTimeAndAvatar: distance = 24
        }
        return distance
    }
    
    /// Returns the distance of the last line head indent based on the appearance of the chat cell.
    @objc open func lastLineHeadIndent() -> CGFloat { gift_tail_indent }
    
    required public override init() {
            
    }
}

public extension ChatMessage {
    
    /// ``UserInfoProtocol``
    @objc var user: EaseProfileProtocol? {
        EaseChatUIKitContext.shared?.chatCache?[self.from]
    }
    
    /// Content of the text message.
    @objc var text: String {
        (self.body as? ChatTextMessageBody)?.text ?? ""
    }
    
    /// Translation of the text message.
    @objc var translation: String? {
        (self.body as? ChatTextMessageBody)?.translations?[Appearance.chat.targetLanguage.rawValue]
    }
}
