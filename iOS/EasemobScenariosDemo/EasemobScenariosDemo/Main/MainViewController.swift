//
//  MainViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/5.
//

import UIKit
import EaseChatUIKit
import SwiftFFDBHotFix
import AVFoundation

final class MainViewController: UITabBarController {
    
    private lazy var chats: ConversationListController = {
        let vc = EaseChatUIKit.ComponentsRegister.shared.ConversationsController.init()
        vc.tabBarItem.tag = 0
        vc.viewModel?.registerEventsListener(listener: self)
        return vc
    }()
    
    private lazy var match: UsersMatchViewController = {
        UsersMatchViewController()
    }()
    
    private lazy var me: ProfileViewController = {
        let vc = ProfileViewController()
        vc.tabBarItem.tag = 2
        return vc
    }()
    
    private var role = CallPopupView.CallRole.caller
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIApplication.shared.chat.keyWindow != nil {
            tabBar.frame = CGRect(x: 0, y: ScreenHeight-BottomBarHeight-49, width: ScreenWidth, height: BottomBarHeight+49)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.insetsLayoutMarginsFromSafeArea = false
        self.tabBarController?.additionalSafeAreaInsets = .zero
        self.callKitSet()
        self.setupDataProvider()
        self.loadViewControllers()
        // Do any additional setup after loading the view.
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    private func setupDataProvider() {
        //userProfileProvider为用户数据的提供者，使用协程实现与userProfileProviderOC不能同时存在userProfileProviderOC使用闭包实现
        EaseChatUIKitContext.shared?.userProfileProvider = self
        EaseChatUIKitContext.shared?.userProfileProviderOC = nil
        //groupProvider原理同上
        EaseChatUIKitContext.shared?.groupProfileProvider = self
        EaseChatUIKitContext.shared?.groupProfileProviderOC = nil
    }
    
    private func callKitSet() {
//        let callConfig = EaseCallConfig()
//        callConfig.agoraAppId = CallKitAppId
//        callConfig.enableRTCTokenValidate = true
//        EaseCallManager.shared().initWith(callConfig, delegate: self)
    }

    private func loadViewControllers() {

        let nav1 = UINavigationController(rootViewController: self.chats)
        nav1.interactivePopGestureRecognizer?.isEnabled = true
        nav1.interactivePopGestureRecognizer?.delegate = self
        let nav2 = UINavigationController(rootViewController: self.match)
        nav2.interactivePopGestureRecognizer?.isEnabled = true
        nav2.interactivePopGestureRecognizer?.delegate = self
        let nav3 = UINavigationController(rootViewController: self.me)
        nav3.interactivePopGestureRecognizer?.isEnabled = true
        nav3.interactivePopGestureRecognizer?.delegate = self
        self.viewControllers = [nav2,nav1,nav3]
        self.view.backgroundColor = UIColor.theme.neutralColor98
        self.tabBar.backgroundColor = UIColor.theme.barrageDarkColor8
        self.tabBar.barTintColor = UIColor.theme.barrageDarkColor8
        self.tabBar.isTranslucent = true
        self.tabBar.barStyle = .default
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()
        
    }

}

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.navigationController?.interactivePopGestureRecognizer {
            return self.navigationController!.viewControllers.count > 1
        }
        if UIViewController.currentController is MineConversationsController || UIViewController.currentController is ProfileViewController {
            return false
        }
        return true
    }
}

extension MainViewController: ThemeSwitchProtocol {
    
    func switchTheme(style: EaseChatUIKit.ThemeStyle) {
        self.tabBar.barTintColor = style == .dark ? UIColor.theme.barrageLightColor8:UIColor.theme.barrageDarkColor8
        self.view.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.tabBar.backgroundColor = style == .dark ? UIColor.theme.barrageLightColor8:UIColor.theme.barrageDarkColor8
        
        let chatsImage = UIImage(named: "tabbar_chats")?.withRenderingMode(.alwaysOriginal)
        let selectedChatsImage = UIImage(named: "tabbar_chats_focused")?.withRenderingMode(.alwaysOriginal)
        self.chats.tabBarItem = UITabBarItem(title: "Chats".localized(), image: chatsImage, selectedImage: selectedChatsImage)
        
        self.chats.tabBarItem.setTitleTextAttributes([.foregroundColor:style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor5], for: .normal)
        self.chats.tabBarItem.setTitleTextAttributes([.foregroundColor:style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5], for: .selected)
        
        let tabbar_match = UIImage(named: "tabbar_match")?.withRenderingMode(.alwaysOriginal)
        let tabbar_match_focused = UIImage(named: "tabbar_match_focused")?.withRenderingMode(.alwaysOriginal)
        self.match.tabBarItem = UITabBarItem(title: "1v1私密房", image: tabbar_match, selectedImage: tabbar_match_focused)
        self.match.tabBarItem.setTitleTextAttributes([.foregroundColor:style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor5], for: .normal)
        self.match.tabBarItem.setTitleTextAttributes([.foregroundColor:style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5], for: .selected)
        
        let meImage = UIImage(named: "tabbar_mine")?.withRenderingMode(.alwaysOriginal)
        let selectedMeImage = UIImage(named: "tabbar_mine_focused")?.withRenderingMode(.alwaysOriginal)
        self.me.tabBarItem = UITabBarItem(title: "Me".localized(), image: meImage, selectedImage: selectedMeImage)
        
        self.me.tabBarItem.setTitleTextAttributes([.foregroundColor:style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor5], for: .normal)
        self.me.tabBarItem.setTitleTextAttributes([.foregroundColor:style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5], for: .selected)
        let value = ConversationViewModel.unreadCount()
        self.chats.tabBarItem.badgeValue = value
        
    }
    
}

//MARK: - EaseProfileProvider for conversations&contacts usage.
//For example using conversations controller,as follows.
extension MainViewController: EaseProfileProvider,EaseGroupProfileProvider {
    //MARK: - EaseProfileProvider
    func fetchProfiles(profileIds: [String]) async -> [any EaseChatUIKit.EaseProfileProtocol] {
        return await withTaskGroup(of: [EaseChatUIKit.EaseProfileProtocol].self, returning: [EaseChatUIKit.EaseProfileProtocol].self) { group in
            var resultProfiles: [EaseChatUIKit.EaseProfileProtocol] = []
            group.addTask {
                var resultProfiles: [EaseChatUIKit.EaseProfileProtocol] = []
                let result = await self.requestUserInfos(profileIds: profileIds)
                if let infos = result {
                    resultProfiles.append(contentsOf: infos)
                }
                return resultProfiles
            }
            //Await all task were executed.Return values.
            for await result in group {
                resultProfiles.append(contentsOf: result)
            }
            return resultProfiles
        }
    }
    //MARK: - EaseGroupProfileProvider
    func fetchGroupProfiles(profileIds: [String]) async -> [any EaseChatUIKit.EaseProfileProtocol] {
        return await withTaskGroup(of: [EaseChatUIKit.EaseProfileProtocol].self, returning: [EaseChatUIKit.EaseProfileProtocol].self) { group in
            var resultProfiles: [EaseChatUIKit.EaseProfileProtocol] = []
            group.addTask {
                var resultProfiles: [EaseChatUIKit.EaseProfileProtocol] = []
                let result = await self.requestGroupsInfo(groupIds: profileIds)
                if let infos = result {
                    resultProfiles.append(contentsOf: infos)
                }
                return resultProfiles
            }
            //Await all task were executed.Return values.
            for await result in group {
                resultProfiles.append(contentsOf: result)
            }
            return resultProfiles
        }
    }
    
    private func requestUserInfos(profileIds: [String]) async -> [EaseProfileProtocol]? {
        var unknownIds = [String]()
        var resultProfiles = [EaseProfileProtocol]()
        for profileId in profileIds {
            if let profile = EaseChatUIKitContext.shared?.userCache?[profileId] {
                if profile.nickname.isEmpty {
                    unknownIds.append(profile.id)
                } else {
                    resultProfiles.append(profile)
                }
            } else {
                unknownIds.append(profileId)
            }
        }
        if unknownIds.isEmpty {
            return resultProfiles
        }
        let result = await ChatClient.shared().userInfoManager?.fetchUserInfo(byId: unknownIds)
        if result?.1 == nil,let infoMap = result?.0 {
            for (userId,info) in infoMap {
                let profile = EaseChatProfile()
                let nickname = info.nickname ?? ""
                profile.id = userId
                profile.nickname = nickname
                if let remark = ChatClient.shared().contactManager?.getContact(userId)?.remark {
                    profile.remark = remark
                }
                profile.avatarURL = info.avatarUrl ?? ""
                resultProfiles.append(profile)
                if (EaseChatUIKitContext.shared?.userCache?[userId]) != nil {
                    profile.updateFFDB()
                } else {
                    profile.insert()
                }
                EaseChatUIKitContext.shared?.userCache?[userId] = profile
            }
            return resultProfiles
        }
        return []
    }
    
    private func requestGroupsInfo(groupIds: [String]) async -> [EaseProfileProtocol]? {
        var resultProfiles = [EaseProfileProtocol]()
        let groups = ChatClient.shared().groupManager?.getJoinedGroups() ?? []
        for groupId in groupIds {
            if let group = groups.first(where: { $0.groupId == groupId }) {
                let profile = EaseChatProfile()
                profile.id = groupId
                profile.nickname = group.groupName
                profile.avatarURL = group.settings.ext
                resultProfiles.append(profile)
                EaseChatUIKitContext.shared?.groupCache?[groupId] = profile
            }

        }
        return resultProfiles
    }
}
//MARK: - ConversationEmergencyListener
extension  MainViewController: ConversationEmergencyListener {
    func onResult(error: EaseChatUIKit.ChatError?, type: EaseChatUIKit.ConversationEmergencyType) {
        //show toast or alert,then process
    }
    
    func onConversationLastMessageUpdate(message: EaseChatUIKit.ChatMessage, info: EaseChatUIKit.ConversationInfo) {
        //Latest message updated on the conversation.
    }
    
    func onConversationsUnreadCountUpdate(unreadCount: UInt) {
        DispatchQueue.main.async {
            self.chats.tabBarItem.badgeValue = unreadCount > 0 ? "\(unreadCount)" : nil
        }
    }

}

extension ConversationViewModel {
    static func unreadCount() -> String? {
        if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
            let items = ConversationViewModel().mapper(objects: infos)
            var count = UInt(0)
            for item in items where item.doNotDisturb == false {
                count += item.unreadCount
            }
            return count > 0 ? "\(count)":nil
        }
        return nil
    }
}

