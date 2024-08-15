//
//  AnimationQueue.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/7.
//

import Foundation

final class AnimationQueue {
    var animations: [() -> Void] = []
    private var isAnimating: Bool = false
    
    func addAnimation(animation: @escaping () -> Void, delay: TimeInterval = 3) {
        let delayedAnimation = {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                animation()
                self.startNextAnimation()
            }
        }
        
        self.animations.append(delayedAnimation)
        if !self.isAnimating {
            self.startNextAnimation()
        }
    }
    
    private func startNextAnimation() {
        guard !self.isAnimating else {
            return
        }
        
        if let animation = self.animations.first {
            self.isAnimating = true
            animation()
            self.animations.removeFirst()
        } else {
            self.isAnimating = false
        }
    }
}
