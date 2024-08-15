//
//  GiftAnimationEffectView.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/7.
//

import UIKit
import libpag
import EaseChatUIKit

@objc protocol IGiftAnimationEffectViewDriver: NSObjectProtocol {
    func animation(with gift: GiftEntityProtocol)
}

final class GiftAnimationEffectView:UIView  {
    
    lazy var effectView: PAGView = {
        let pag = PAGView(frame: self.bounds)
        pag.isUserInteractionEnabled = false
        pag.setScaleMode(PAGScaleModeZoom)
        pag.setRepeatCount(1)
        pag.add(self)
        return pag
    }()
    
    private var queue: AnimationQueue = AnimationQueue()
    
    private var animationPaths = [String]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.effectView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event)
    }

}

extension GiftAnimationEffectView: PAGViewListener,IGiftAnimationEffectViewDriver {
    
    func animation(with gift: GiftEntityProtocol) {
        let effectName = gift.giftEffect
        let path = Bundle.main.path(forResource: effectName, ofType: "pag") ?? ""
        if effectName.isEmpty || !FileManager.default.fileExists(atPath: path) {
            consoleLogInfo("effectMD5 is empty!", type: .debug)
            return
        }
        self.isHidden = false
        if !self.animationPaths.contains(path) {
            self.animationPaths.append(path)
        }
        if !self.effectView.isPlaying() {
            self.playAnimation(path: path)
        }
    }
    
    private func playAnimation(path: String) {
        let file = PAGFile.load(path)
        self.effectView.setComposition(file)
        self.effectView.play()
    }
    
    public func onAnimationEnd(_ pagView: PAGView!) {
        self.animationPaths.removeFirst()
        if self.animationPaths.count <= 0 {
            self.isHidden = true
        } else {
            self.playDelayAnimation()
        }
    }
    
    private func playDelayAnimation() {
        if let animationPath = self.animationPaths.first {
            let file = PAGFile.load(animationPath)
            self.effectView.setComposition(file)
            self.effectView.play()
        }
    }
    
    public func onAnimationCancel(_ pagView: PAGView!) {
        self.isHidden = true
    }
    
    public func onAnimationRepeat(_ pagView: PAGView!) {
        self.isHidden = true
    }
}
