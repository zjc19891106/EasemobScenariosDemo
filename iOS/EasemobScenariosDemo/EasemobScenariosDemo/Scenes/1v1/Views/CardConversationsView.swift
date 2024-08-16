//
//  CardMessagesView.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/8.
//

import UIKit
import EaseChatUIKit



final class CardConversationsView: UIView {
    
    private var conversations: LimitedArray<ConversationInfo> = LimitedArray<ConversationInfo>(maxCount: 3)
    
    private var currentTask: DispatchWorkItem?
    
    private let queue = DispatchQueue(label: "com.example.miniConversationsHandlerQueue")
    
    var tapAction: ((ConversationInfo) -> Void)?
    
    var dismissClosure: ((ConversationInfo?) -> Void)?
    
    lazy var cardConversationsList: UICollectionView = {
        UICollectionView(frame: CGRect(x: 16, y: StatusBarHeight, width: self.frame.width-32, height: self.frame.height-StatusBarHeight), collectionViewLayout: StackCardLayout()).delegate(self).dataSource(self).registerCell(SlidableCollectionViewCell.self, forCellReuseIdentifier: SlidableCollectionViewCell.identifier).backgroundColor(.clear)
    }()
    
    required init(frame: CGRect,infos: [ChatMessage]) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.refresh(messages: infos)
        self.addSubViews([self.cardConversationsList])
    }
    
    func refresh(messages: [ChatMessage]) {
        for message in messages {
            self.newConversation(with: message)
        }
        self.cardConversationsList.reloadData()
        self.delayedTask()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            self.dismissClosure?(nil)
            self.conversations.removeAll()
        }
    }
    
    func newConversation(with message: ChatMessage) {
        let info = self.convertToConversationInfo(with: message)
        if let exist = self.conversations.first(where: { $0.id == message.conversationId }) {
            exist.lastMessage = message
            exist.showContent = exist.contentAttribute()
            self.conversations.bringToFront { $0.id == message.conversationId }
            
        } else {
            self.conversations.append(info)
        }
    }
    
    func convertToConversationInfo(with message: ChatMessage) -> ConversationInfo {
        let info = ConversationInfo()
        info.id = message.from
        info.nickname = message.user?.nickname ?? ""
        info.avatarURL = message.user?.avatarURL ?? ""
        info.lastMessage = message
        _ = info.showContent
        return info
    }
}

extension CardConversationsView: UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("conversations.count:\(self.conversations.count)")
        return self.conversations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SlidableCollectionViewCell.identifier, for: indexPath) as? SlidableCollectionViewCell
        if let info = self.conversations[safe: indexPath.item] {
            cell?.refresh(info: info)
        }
        cell?.swipeRemoveAction = { [weak self] in
            self?.remove(cell: $0)
        }
        return cell ?? SlidableCollectionViewCell()
    }
    
    func remove(cell: SlidableCollectionViewCell) {
        if let indexPath = self.cardConversationsList.indexPath(for: cell) {
            self.conversations.remove(at: indexPath.item)
            self.cardConversationsList.performBatchUpdates {
                self.cardConversationsList.deleteItems(at: [indexPath])
            }
            self.delayedTask()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        self.feedback()
        self.dismissClosure?(self.conversations[safe: indexPath.item])
    }
    
    func feedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
}

//MARK: - SlidableCollectionViewCell
final class SlidableCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "SlidableCollectionViewCell"
    
    var swipeRemoveAction: ((SlidableCollectionViewCell) -> Void)?
    
    public private(set) lazy var avatar: ImageView = {
        self.createAvatar()
    }()
    
    func createAvatar() -> ImageView {
        ImageView(frame: CGRect(x: 16, y: (self.contentView.frame.height-40)/2.0, width: 40, height: 40)).contentMode(.scaleAspectFill).cornerRadius(.large).backgroundColor(.red)
    }
    
    public private(set) lazy var status: UIImageView = {
        self.createAvatarStatus()
    }()
    
    func createAvatarStatus() -> UIImageView {
        let r = self.avatar.frame.width / 2.0
        let length = CGFloat(sqrtf(Float(r)))
        let x = (Appearance.avatarRadius == .large ? (r + length + 3):(self.avatar.frame.width-10))
        let y = (Appearance.avatarRadius == .large ? (r + length + 3):(self.avatar.frame.height-10))
        return UIImageView(frame: CGRect(x: self.avatar.frame.minX+x, y: self.avatar.frame.minY+y, width: 12, height: 12)).backgroundColor(UIColor.theme.secondaryColor5).cornerRadius(.large).layerProperties(UIColor.theme.neutralColor98, 2).contentMode(.scaleAspectFit)
    }
    
    public private(set) lazy var nickName: UILabel = {
        self.createNickName()
    }()
    
    func createNickName() -> UILabel {
        UILabel(frame:CGRect(x: self.avatar.frame.maxX+12, y: self.avatar.frame.minX+4, width: self.contentView.frame.width-self.avatar.frame.maxX-12-16, height: 16)).isUserInteractionEnabled(false).backgroundColor(.clear).font(UIFont.theme.titleMedium).textColor(UIColor.theme.neutralColor1)
    }
    
    public private(set) lazy var content: UILabel = {
        self.createContent()
    }()
    
    func createContent() -> UILabel {
        UILabel(frame: CGRect(x: self.avatar.frame.maxX+12, y: self.nickName.frame.maxY+2, width: self.contentView.frame.width-self.avatar.frame.maxX-12-16-50, height: 20)).backgroundColor(.clear)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 16).cgPath

        self.contentView.addSubViews([self.avatar,self.status,self.nickName,self.content])
        setupGestureRecognizer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        self.contentView.transform = layoutAttributes.transform
        self.updateFrame()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateFrame()
    }
    
    private func updateFrame() {
        self.avatar.frame = CGRect(x: 16, y: (self.contentView.frame.height-40)/2.0, width: 40, height: 40)
        self.nickName.frame = CGRect(x: self.avatar.frame.maxX+12, y: self.avatar.frame.minX, width: self.contentView.frame.width-self.avatar.frame.maxX-12-16, height: 16)
        self.content.frame = CGRect(x: self.avatar.frame.maxX+12, y: self.avatar.frame.maxY-20, width: self.nickName.frame.width, height: 20)
        let r = self.avatar.frame.width / 2.0
        let length = CGFloat(sqrtf(Float(r)))
        let x = r + length + 3
        let y = r + length + 3
        self.status.frame =  CGRect(x: self.avatar.frame.minX+x, y: self.avatar.frame.minY+y, width: 12, height: 12)
    }
    
    private func setupGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let cell = gesture.view as? SlidableCollectionViewCell else { return }
        let translation = gesture.translation(in: cell)
        
        switch gesture.state {
        case .began, .changed:
            UIView.animate(withDuration: 0.382) {
                cell.transform = CGAffineTransform(translationX: translation.x, y: 0)
            }
        case .ended, .cancelled:
            if abs(translation.x) > cell.bounds.width / 3 {
                // Swipe off screen
                let direction: CGFloat = translation.x > 0 ? 1 : -1
                UIView.animate(withDuration: 0.3, animations: {
                    cell.transform = CGAffineTransform(translationX: direction * cell.bounds.width, y: 0)
                    cell.alpha = 0
                }) { _ in
                    cell.transform = .identity
                    cell.alpha = 1
                    // Optionally remove the cell from the collection view
                    self.swipeRemoveAction?(self)
                }
            } else {
                // Snap back to original position
                UIView.animate(withDuration: 0.3) {
                    cell.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    func refresh(info: ConversationInfo) {
        self.updateFrame()
        self.avatar.cornerRadius(Appearance.avatarRadius)
        self.avatar.image(with: info.avatarURL, placeHolder: info.type == .chat ? Appearance.conversation.singlePlaceHolder:Appearance.conversation.groupPlaceHolder)
        var nickName = info.id
        if !info.nickname.isEmpty {
            nickName = info.nickname
        }
        if !info.remark.isEmpty {
            nickName = info.remark
        }
        let nameAttribute = NSMutableAttributedString {
            AttributedText(nickName).font(UIFont.theme.titleMedium).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1)
            
        }
        self.nickName.attributedText = nameAttribute
        self.content.attributedText = info.showContent
    }
}
