//
//  Chat1v1Service.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/7.
//

import Foundation
import EaseChatUIKit

let EaseMob1v1ChatGift = "EaseMob1v1ChatGift"

@objc public protocol Chat1v1Service: NSObjectProtocol {
    
    /// Send text message to some one.
    /// - Parameters:
    ///   - text: You'll send text.
    ///   - completion: Send callback,what if success or error.
    func sendMessage(text: String, completion: @escaping (ChatMessage?,ChatError?) -> Void)
    
    /// Send targeted gift message to some one.
    /// - Parameters:
    ///   - userIds: userIds description
    ///   - eventType: A constant String value that identifies the type of event.
    ///   - infoMap: Extended Information
    ///   - completion: Send callback,what if success or error.
    func sendGiftMessage(to userId:String, eventType: String, infoMap:[String:Any], completion: @escaping (ChatMessage?,ChatError?) -> Void)
    
    /// Translate the specified message
    /// - Parameters:
    ///   - message: ChatMessage kind of text message.
    ///   - completion: Translate callback,what if success or error.
    func translateMessage(message: ChatMessage, completion: @escaping (ChatMessage?,ChatError?) -> Void)
    
    /// Recall message.
    /// - Parameters:
    ///   - messageId: message id
    ///   - completion: Recall callback,what if success or error.
    func recall(messageId: String, completion: @escaping (ChatError?) -> Void)
    
    /// Report illegal message.
    /// - Parameters:
    ///   - messageId: message id
    ///   - tag: Illegal type defined at console.
    ///   - reason: reason
    ///   - completion: Report callback,what if success or error.
    func report(messageId: String,tag: String,reason: String, completion: @escaping (ChatError?) -> Void)
    
}
