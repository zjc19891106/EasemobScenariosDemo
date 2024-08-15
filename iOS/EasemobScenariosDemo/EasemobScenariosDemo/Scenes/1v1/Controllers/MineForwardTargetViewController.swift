//
//  MineForwardTargetViewController.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/14.
//

import UIKit
import EaseChatUIKit

class MineForwardTargetViewController: UIViewController {

    public private(set) var messages = [ChatMessage]()
    
    private var combineForward = true
    
    private var searchKeyWord = ""
    
    private var searchMode = false
        
    private var datas = [EaseProfileProtocol]() {
        didSet {
            DispatchQueue.main.async {
                if self.datas.count <= 0 {
                    self.targetsList.backgroundView = self.empty
                } else {
                    self.targetsList.backgroundView = nil
                }
            }
        }
    }
    
    private var forwarded = false
    
    private var searchResults = [EaseProfileProtocol]()
    
    public private(set) lazy var indicator: UIView = {
        UIView(frame: CGRect(x: self.view.frame.width/2.0-18, y: 6, width: 36, height: 5)).cornerRadius(2.5).backgroundColor(UIColor.theme.neutralColor8)
    }()
    
    public private(set)  lazy var toolBar: PageContainerTitleBar = {
        PageContainerTitleBar(frame: CGRect(x: 0, y: self.indicator.frame.maxY + 4, width: self.view.frame.width, height: 44), choices: ["转发给"]) { _ in
            
        }
    }()
    
    public private(set) lazy var targetsList: UITableView = {
        UITableView(frame: CGRect(x: 0, y: self.toolBar.frame.maxY, width: self.view.frame.width, height: self.view.frame.height-self.toolBar.frame.maxY-StatusBarHeight), style: .plain).delegate(self).dataSource(self).tableFooterView(UIView()).rowHeight(60).separatorStyle(.none).showsVerticalScrollIndicator(false).tableFooterView(UIView()).backgroundColor(.clear).tableHeaderView(self.searchController.searchBar)
    }()
    
    public private(set) lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = true
        searchController.showsSearchResultsController = true
        searchController.automaticallyShowsScopeBar = false
        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.delegate = self
        return searchController
    }()
    
    public private(set) lazy var empty: EmptyStateView = {
        EmptyStateView(frame: self.targetsList.bounds,emptyImage: UIImage(named: "empty",in: .chatBundle, with: nil), onRetry: { [weak self] in

        }).backgroundColor(.clear)
    }()
    
    public var dismissClosure: ((Bool) -> Void)?
        
    private var noMoreGroup = false
    
    public required init(messages: [ChatMessage],combine: Bool = true) {
        self.messages = messages
        self.combineForward = combine
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissClosure?(self.forwarded)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.cornerRadius(.medium, [.topLeft,.topRight], .clear, 0)
        self.view.addSubViews([self.indicator,self.toolBar,self.targetsList])
        // Do any additional setup after loading the view.
        self.targetsList.keyboardDismissMode = .onDrag
        self.fillDatas(refresh: true)
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    open func fillDatas(refresh: Bool) {
        if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
            let items = self.mapper(objects: infos)
            self.datas.removeAll()
            self.datas = items
            self.targetsList.reloadData()
        }
    }
   
    @objc open func mapper(objects: [ChatConversation]) -> [ConversationInfo] {
        objects.map {
            let conversation = ComponentsRegister.shared.Conversation.init()
            conversation.id = $0.conversationId
            var nickname = ""
            var profile: EaseProfileProtocol?
            if $0.type == .chat {
                profile = EaseChatUIKitContext.shared?.userCache?[$0.conversationId]
            } else {
                profile = EaseChatUIKitContext.shared?.groupCache?[$0.conversationId]
                if EaseChatUIKitContext.shared?.groupProfileProvider == nil,EaseChatUIKitContext.shared?.groupProfileProviderOC == nil {
                    profile?.nickname = ChatGroup(id: $0.conversationId).groupName ?? ""
                }
            }
            if nickname.isEmpty {
                nickname = profile?.remark ?? ""
            }
            if nickname.isEmpty {
                nickname = profile?.nickname ?? ""
            }
            if nickname.isEmpty {
                nickname = $0.conversationId
            }
            conversation.unreadCount = UInt($0.unreadMessagesCount)
            conversation.lastMessage = $0.latestMessage
            conversation.type = EaseProfileProviderType(rawValue: UInt($0.type.rawValue)) ?? .chat
            conversation.pinned = $0.isPinned
            conversation.nickname = profile?.nickname ?? ""
            conversation.remark = profile?.remark ?? ""
            conversation.avatarURL = profile?.avatarURL ?? ""
            conversation.doNotDisturb = false
            _ = conversation.showContent
            return conversation
        }
    }

}

extension MineForwardTargetViewController: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.searchController.searchBar.backgroundColor(style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98)
        self.searchController.searchBar.barStyle = style == .dark ? .black:.default
        self.searchController.searchBar.searchTextField.textColor = style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1
        self.view.backgroundColor(style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98)
        self.targetsList.reloadData()
    }
    
    
}

extension MineForwardTargetViewController: UITableViewDelegate,UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ForwardTargetCell") as? ForwardTargetCell
        if cell == nil {
            cell = ForwardTargetCell(style: .default, reuseIdentifier: "ForwardTargetCell")
        }
        cell?.selectionStyle = .none
        if self.searchMode {
            if let info = self.searchResults[safe: indexPath.row] {
                cell?.refresh(info: info, keyword: self.searchKeyWord, forward: .normal)
            }
        } else {
            if let info = self.datas[safe: indexPath.row] {
                cell?.refresh(info: info, keyword: "", forward: .normal)
            }
        }
        
        cell?.actionClosure = { [weak self] in
            if let forwardIndexPath = tableView.indexPath(for: $0) {
                self?.forwardMessages(indexPath: forwardIndexPath)
            }
        }
        return cell ?? UITableViewCell()
    }
    
    @objc open func forwardMessages(indexPath: IndexPath) {
        var body = self.messages.first?.body ?? ChatMessageBody()
        if self.combineForward {
            body = ChatCombineMessageBody(title: "Chat History".chat.localize, summary: self.forwardSummary(), compatibleText: "[Chat History]", messageIdList: self.messages.filter({ChatClient.shared().chatManager?.getMessageWithMessageId($0.messageId)?.status == .succeed}).map({ $0.messageId }))
        }
        
        var conversationId = ""
        if self.searchMode {
            conversationId = self.searchResults[indexPath.row].id
        } else {
            conversationId = self.datas[indexPath.row].id
        }
        let message =  ChatMessage(conversationID: conversationId, body: body, ext: EaseChatUIKitContext.shared?.currentUser?.toJsonObject())
        message.chatType = .chat
        ChatClient.shared().chatManager?.send(message, progress: nil, completion: { [weak self] successMessage, error in
            guard let `self` = self else { return }
            if error == nil {
                self.forwarded = true
                if let cell = self.targetsList.cellForRow(at: indexPath) as? ForwardTargetCell {
                    var profile = EaseProfile()
                    if let user = (self.searchMode ? self.searchResults:self.datas)[safe: indexPath.row] as? EaseProfile {
                        profile = user
                    }
                    cell.refresh(info: profile, keyword: self.searchKeyWord, forward: .forwarded)
                }
            } else {
                consoleLogInfo("ForwardTargetViewController forwardMessages error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    @objc open func forwardSummary() -> String {
        var summary = ""
        for (index,message) in self.messages.enumerated() {
            if index <= 3 {
                let nickname = message.user?.nickname ?? message.from
                if index == 0 {
                    summary += (nickname+":"+message.showType+"\n")
                } else {
                    if index <= 3 {
                        summary += (nickname+":"+message.showType+"\n")
                    }
                }
            } else {
                break
            }
        }
        return summary
    }
    
}

extension MineForwardTargetViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    
    public func updateSearchResults(for searchController: UISearchController) {
        searchController.searchResultsController?.view.isHidden = false
        self.searchKeyWord = searchController.searchBar.text?.lowercased() ?? ""
        if let searchText = searchController.searchBar.text?.lowercased() {
            self.searchResults = self.datas.filter({ user in
                let showName = user.nickname.isEmpty ? user.id:user.nickname
                return (showName.lowercased() as NSString).range(of: searchText).location != NSNotFound && (showName.lowercased() as NSString).range(of: searchText).length >= 0
            })
        }
        self.targetsList.reloadData()
    }
    
    public func willPresentSearchController(_ searchController: UISearchController) {
        self.searchController = searchController
    }
    
    public func didPresentSearchController(_ searchController: UISearchController) {
        
    }
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        
    }
    
    public func didDismissSearchController(_ searchController: UISearchController) {
        
    }
    
    public func presentSearchController(_ searchController: UISearchController) {
        self.searchMode = true
        UIView.animate(withDuration: 0.25) {
            self.indicator.alpha = 0
            self.toolBar.alpha = 0
            self.targetsList.frame = CGRect(x: 0, y: 10, width: self.view.frame.width, height: self.view.frame.height-10)
        }
        self.targetsList.reloadData()
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchMode = false
        self.searchResults.removeAll()
        UIView.animate(withDuration: 0.25) {
            self.indicator.alpha = 1
            self.toolBar.alpha = 1
            self.toolBar.frame =  CGRect(x: 0, y: self.indicator.frame.maxY + 4, width: self.view.frame.width, height: 44)
            self.targetsList.frame = CGRect(x: 0, y: self.toolBar.frame.maxY, width: self.view.frame.width, height: self.view.frame.height-self.toolBar.frame.maxY-StatusBarHeight)
        }
        self.targetsList.reloadData()
    }
    
    
}
