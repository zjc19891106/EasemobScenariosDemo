//
//  NoMatchUserView.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/9.
//

import UIKit
import EaseChatUIKit

final class NoMatchUserView: UIView {

    private var retryClosure: (() -> ())?
    
    lazy var imageContainer: UIImageView = {
        UIImageView().contentMode(.scaleAspectFill)
    }()
    
    lazy var retryButton: UIButton = {
        UIButton(type: .custom).font(UIFont.theme.labelMedium).textColor(UIColor.theme.neutralColor7, .normal).addTargetFor(self, action: #selector(retry), for: .touchUpInside)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// Init a empty state view.
    /// - Parameters:
    ///   - frame: CGRect
    ///   - emptyImage: UIImage?
    @objc public required init(frame: CGRect,emptyImage: UIImage?,onRetry: @escaping () -> ()) {
        super.init(frame: frame)
        self.retryClosure = onRetry
        self.setupView()
        self.imageContainer.image = emptyImage
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.addSubview(self.imageContainer)
        self.imageContainer.translatesAutoresizingMaskIntoConstraints = false
        self.imageContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        self.imageContainer.centerYAnchor.constraint(equalTo: centerYAnchor,constant: -NavigationHeight).isActive = true
        self.imageContainer.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 68).isActive = true
        self.imageContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -68).isActive = true
        self.imageContainer.heightAnchor.constraint(equalToConstant: 178).isActive = true
        
        self.addSubview(self.retryButton)
        self.retryButton.translatesAutoresizingMaskIntoConstraints = false
        self.retryButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        self.retryButton.topAnchor.constraint(equalTo: self.imageContainer.bottomAnchor,constant: 15).isActive = true
        self.retryButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20).isActive = true
        self.retryButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        self.retryButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        self.retryButton.cornerRadius(Appearance.avatarRadius)
        self.retryButton.setTitle("等待其他用户入场", for: .normal)
    }
    
    @objc private func retry() {
        self.retryClosure?()
    }

}
