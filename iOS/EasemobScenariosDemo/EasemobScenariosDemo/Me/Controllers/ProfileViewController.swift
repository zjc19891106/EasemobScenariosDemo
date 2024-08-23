//
//  ProfileViewController.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/5.
//

import UIKit
import EaseChatUIKit
import MobileCoreServices
import AVFoundation
import SwiftFFDBHotFix

let userAvatarUpdated = "userAvatarUpdated"

final class ProfileViewController: UIViewController {
    
    private var menus: [Dictionary<String,String>] = [["title":"访问官网","detail":"www.easemob.com","destination":"https://www.easemob.com"],["title":"联系商务","detail":"400-622-1776","destination":"tel://4006221776"],["title":"退出登录","detail":"","destination":""]]
    
    lazy var header: ProfileHeader = {
        ProfileHeader(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 343)).backgroundColor(.clear)
    }()
    
    private lazy var menuList: UITableView = {
        UITableView(frame: CGRect(x: 20, y: 343, width: Int(ScreenWidth)-40, height: 54*self.menus.count), style: .plain).rowHeight(54).delegate(self).dataSource(self).backgroundColor(.clear).separatorStyle(.none).backgroundColor(UIColor.theme.neutralColor100).cornerRadius(16)
    }()
    
    private lazy var background: UIImageView = {
        UIImageView(frame: self.view.bounds).contentMode(.scaleAspectFill).image(UIImage(named: "login_bg"))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "login_bg")!)
        // Do any additional setup after loading the view.
        self.view.addSubViews([self.background,self.header,self.menuList])
        self.menuList.keyboardDismissMode = .onDrag
        self.header.nameLabel.delegate = self
        self.header.avatarChangedClosure = { [weak self] in
            self?.showImagePicker()
        }
    }
    

    private func updateUserInfo(nickname: String) {
        guard let userId = EaseChatUIKitContext.shared?.currentUserId else { return }
        ChatClient.shared().userInfoManager?.updateOwnUserInfo(nickname, with: .nickName, completion: { [weak self] info, error in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                if error == nil {
                    self.header.nameLabel.text = nickname
                    EaseChatUIKitContext.shared?.currentUser?.nickname = nickname
                    EaseChatUIKitContext.shared?.userCache?[userId]?.nickname = nickname
                    EaseChatUIKitContext.shared?.chatCache?[userId]?.nickname = nickname
                    if let userJson = EaseChatUIKitContext.shared?.currentUser?.toJsonObject() {
                        let profile = EaseChatProfile()
                        profile.setValuesForKeys(userJson)
                        profile.updateFFDB()
                    }
                } else {
                    DialogManager.shared.showAlert(title: "error".chat.localize, content: "update nickname failed".chat.localize, showCancel: false, showConfirm: true) { _ in
                        
                    }
                }
            }
        })
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.menus.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        }
        cell?.textLabel?.textColor = UIColor.theme.neutralColor1
        cell?.textLabel?.font = UIFont.theme.bodyMedium
        cell?.detailTextLabel?.font = UIFont.theme.labelMedium
        cell?.detailTextLabel?.textColor = UIColor.theme.primaryColor5
        cell?.detailTextLabel?.textAlignment = .right
        if let title = self.menus[safe: indexPath.row]?["title"],let detail = self.menus[safe: indexPath.row]?["detail"] {
            cell?.textLabel?.text = title
            cell?.detailTextLabel?.text = detail
        }
        cell?.accessoryType = .disclosureIndicator
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let title = self.menus[safe: indexPath.row]?["title"],let destination = self.menus[safe: indexPath.row]?["destination"] {
            if title == "退出登录" {
                self.logout()
            } else {
                if let url = URL(string: destination) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    private func logout() {
        DialogManager.shared.showAlert(title: "Confirm Logout".localized(), content: "", showCancel: true, showConfirm: true) { _ in
            EaseChatUIKitClient.shared.logout(unbindNotificationDeviceToken: true) { error in
                if error == nil {
                    NotificationCenter.default.post(name: Notification.Name(backLoginPage), object: nil, userInfo: nil)
                } else {
                    EaseChatUIKitClient.shared.logout(unbindNotificationDeviceToken: false) { _ in
                        NotificationCenter.default.post(name: Notification.Name(backLoginPage), object: nil, userInfo: nil)
                    }
                    self.showToast(toast: "\(error?.errorDescription ?? "")")
                }
            }
        }
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private func showImagePicker() {
        DialogManager.shared.showActions(actions: [ActionSheetItem(title: "input_extension_menu_photo".chat.localize, type: .normal,tag: "Photo",image: UIImage(named: "photo", in: .chatBundle, with: nil)), ActionSheetItem(title: "input_extension_menu_camera".chat.localize, type: .normal,tag: "Camera",image: UIImage(named: "camera_fill", in: .chatBundle, with: nil))]) { [weak self] item in
            self?.processAction(item: item)
        }
    }
    
    @objc private func processAction(item: ActionSheetItemProtocol) {
        switch item.tag {
        case "Photo": self.selectPhoto()
        case "Camera": self.openCamera()
        default:
            break
        }
    }

    @objc private func selectPhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            DialogManager.shared.showAlert(title: "permissions disable".chat.localize, content: "photo_disable".chat.localize, showCancel: false, showConfirm: true) { _ in
                
            }
            return
        }
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            DialogManager.shared.showAlert(title: "permissions disable".chat.localize, content: "camera_disable".chat.localize, showCancel: false, showConfirm: true) { _ in
                
            }
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.mediaTypes = [kUTTypeImage as String]
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.processImagePickerData(info: info)
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc private func processImagePickerData(info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String
        if mediaType == kUTTypeImage as String {
            if let image = info[.editedImage] as? UIImage {
                self.uploadImage(image: image.fixOrientation())
            }
        }
    }
    
    private func uploadImage(image: UIImage) {
        EasemobRequest.shared.uploadImage(image: image) { [weak self] error, result in
            DispatchQueue.main.async {
                if error == nil,let avatarURL = result?["avatarUrl"] as? String {
                    let userId = EaseChatUIKitContext.shared?.currentUserId ?? ""
                    EaseChatUIKitContext.shared?.currentUser?.avatarURL = avatarURL
                    EaseChatUIKitContext.shared?.chatCache?[userId]?.avatarURL = avatarURL
                    self?.header.profileImageView.image(with: avatarURL, placeHolder: Appearance.avatarPlaceHolder)
                    if let userJson = EaseChatUIKitContext.shared?.currentUser?.toJsonObject() {
                        let profile = EaseChatProfile()
                        profile.setValuesForKeys(userJson)
                        profile.updateFFDB()
                    }
                    self?.setUserAvatar(url: avatarURL)
                    self?.menuList.reloadData()
                    NotificationCenter.default.post(name: NSNotification.Name(userAvatarUpdated), object: nil)
                } else {
                    self?.showToast(toast: error?.localizedDescription ?? "")
                }
            }
        }
    }
    
    private func setUserAvatar(url: String) {
        ChatClient.shared().userInfoManager?.updateOwnUserInfo(url, with: .avatarURL, completion: { info, error in
            DispatchQueue.main.async {
                if error != nil {
                    self.showToast(toast: "\(error?.errorDescription ?? "update avatar failed")" )
                }
            }
        })
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ProfileViewController: UITextFieldDelegate {
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.header.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if let nickname = textField.text {
            self.updateUserInfo(nickname: nickname)
        }
    }
}

extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        var transform: CGAffineTransform = .identity
          
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        case .up, .upMirrored:
            break
        @unknown default:
            fatalError()
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            fatalError()
        }
        
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage!.bitsPerComponent, bytesPerRow: 0, space: cgImage!.colorSpace!, bitmapInfo: cgImage!.bitmapInfo.rawValue)!
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        let cgImage: CGImage = context.makeImage()!
        return UIImage(cgImage: cgImage)
    }
}

extension FFObject {
    @discardableResult
    public func updateFFDB() -> Bool {
        do {
            var values = [Any]()
            for column in subType.columnsOfSelf() {
                let value = valueNotNullFrom(column)
                values.append(value)
            }
            values.append(valueNotNullFrom("id"))
//            values.append(valueNotNullFrom(subType.primaryKeyColumn()))
            return try FFDBManager.update(subType, set: subType.columnsOfSelf(), where: "id = ?",values:values)
        } catch {
            consoleLogInfo("failed: \(error.localizedDescription)", type: .error)
        }
        return false
    }
}
