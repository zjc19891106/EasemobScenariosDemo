//
//  CallDurationView.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/14.
//

import UIKit

final class CallDurationView: UIView {
    
    private let iconImageView = UIImageView()
    private let timerLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        
        // 设置图标
        self.iconImageView.image = UIImage(named: "2_rings") // 需要替换为实际的图标
        self.iconImageView.contentMode = .scaleAspectFit
        self.iconImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.iconImageView)
        
        // 设置时间标签
        self.timerLabel.textColor = .white
        self.timerLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.timerLabel.text = "00:00:00"
        self.timerLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.timerLabel)
        
        // 布局约束
        NSLayoutConstraint.activate([
            self.iconImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            self.iconImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.iconImageView.widthAnchor.constraint(equalToConstant: 12),
            self.iconImageView.heightAnchor.constraint(equalToConstant: 12),
            
            self.timerLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 3),
            self.timerLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
            self.timerLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.timerLabel.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    // 刷新时间方法
    public func updateTimer(seconds: Int) {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        
        self.timerLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
}
