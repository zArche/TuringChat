//
//  Message.swift
//  TuringChat
//
//  Created by arche on 16/1/18.
//  Copyright © 2016年 arche. All rights reserved.
//

import Foundation

class Message{
    let incoming: Bool
    let text: String
    let sentDate: NSDate
    var url = ""
    init(incoming: Bool,text: String, sentDate: NSDate){
        self.incoming = incoming
        self.text = text
        self.sentDate = sentDate
        
    }
}