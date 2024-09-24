//
//  EasemobBusinessApi.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/5.
//

import Foundation

public enum EasemobBusinessApi {
    case login(Void)
    case verificationCode(String)
    case matchUser(Void)
    case cancelMatch(String)
    case userCallStatus(String)
    case refreshIMToken(Void)
    case fetchRTCToken(String,String)
}


