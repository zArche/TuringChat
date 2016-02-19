//
//  ChatViewController.swift
//  TuringChat
//
//  Created by arche on 16/1/25.
//  Copyright © 2016年 arche. All rights reserved.
//

import UIKit
import Parse
import Alamofire

class ChatViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,UITextViewDelegate {
    
    var user: PFUser?

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    

    @IBOutlet weak var textView: UITextView!
    
    var messages: [[Message]] = [[Message(incoming: true, text: "你好，请叫我灵灵，我是主人的贴身小助手！", sentDate: NSDate())]]
    
    struct Constants{
        static let CellRowHeight = CGFloat(44)
        static let SentTimeCellIdentifier = "ChatViewSentTimeCell"
        static let MessageBubbleCellIdentfier = "ChatViewMessageBubbleCell"
    }

    override func viewWillAppear(animated: Bool) {
        textView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 205/255, alpha:1).CGColor
        textView.layer.borderWidth = 0.5
        textView.layer.cornerRadius = 5

        textView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    override func viewDidLoad() {
        self.initData()
        super.viewDidLoad()
//        self.view.backgroundColor = UIColor.whiteColor()
        

        self.tableView.autoresizingMask = UIViewAutoresizing.FlexibleHeight

        self.tableView.keyboardDismissMode = .Interactive
        self.tableView.estimatedRowHeight = Constants.CellRowHeight
       
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom:Constants.CellRowHeight, right: 0)
        self.tableView.separatorStyle = .None
        
        self.tableView.registerClass(ChatViewSentTimeCell.self, forCellReuseIdentifier: NSStringFromClass(ChatViewSentTimeCell))
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.flashScrollIndicators()
    }

    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func textViewDidChange(textView: UITextView) {
        sendButton.enabled = textView.hasText()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func initData(){
        
        
        var index = 0
        var section = 0
        var currentDate:NSDate?
        
        
        let query:PFQuery = PFQuery(className:"Messages")
        if let user = PFUser.currentUser(){
            query.whereKey("createdBy", equalTo: user)
            messages = [[Message(incoming: true, text: "\(user.username!)你好，请叫我灵灵，我是主人的贴身小助手!", sentDate: NSDate())]]
        }
        
        query.orderByAscending("sentDate")
        query.cachePolicy = PFCachePolicy.CacheElseNetwork
        
        
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                if objects!.count > 0 {
                    for object in objects as! [PFObject] {
                        if index == objects!.count - 1{
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.tableView.reloadData()
                            })
                            
                        }
                        let message = Message(incoming: object["incoming"] as! Bool, text: object["text"] as! String, sentDate: object["sentDate"] as! NSDate)
                        if let url = object["url"] as? String{
                            message.url = url
                        }
                        if index == 0{
                            currentDate = message.sentDate
                        }
                        let timeInterval = message.sentDate.timeIntervalSinceDate(currentDate!)
                        
                        
                        if timeInterval < 120{
                            self.messages[section].append(message)
                          
                        }else{
                            section++
                            self.messages.append([message])
                            
                        }
                        currentDate = message.sentDate
                        index++
                        
                    }
                }
                
            }else{
                print("Error \(error?.userInfo)")
            }
        }

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages[section].count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("\(indexPath.row)")
        if indexPath.row == 0{
            
            let cellIdentifier = NSStringFromClass(ChatViewSentTimeCell)
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier,forIndexPath: indexPath) as! ChatViewSentTimeCell
            let message = messages[indexPath.section][0]

            cell.sentDateLabel.text = formatDate(message.sentDate)
            
            return cell
            
        }else{
            let cellIdentifier = NSStringFromClass(ChatViewMessageBubbleCell)
            var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ChatViewMessageBubbleCell!
            if cell == nil {
                cell = ChatViewMessageBubbleCell(style: .Default, reuseIdentifier: cellIdentifier)
                
            }

            let message = messages[indexPath.section][indexPath.row - 1]
            cell.configureWithMessage(message)
            return cell
        }
    }
    

    func formatDate(date: NSDate) -> String{
        let calendar = NSCalendar.currentCalendar()
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "zh_CN")
        
        let last18hours = (-18*60*60 < date.timeIntervalSinceNow)
        let isToday = calendar.isDateInToday(date)
        let isLast7Days = (calendar.compareDate(NSDate(timeIntervalSinceNow: -7*24*60*60), toDate: date, toUnitGranularity: NSCalendarUnit.NSDayCalendarUnit) == NSComparisonResult.OrderedAscending)
        
        
        if last18hours || isToday {
            dateFormatter.dateFormat = "a HH:mm"
        } else if isLast7Days {
            dateFormatter.dateFormat = "MM月dd日 a HH:mm EEEE"
        } else {
            dateFormatter.dateFormat = "YYYY年MM月dd日 a HH:mm"
            
        }
        return dateFormatter.stringFromDate(date)
    }
    
    func tableViewScrollToBottomAnimated(animated: Bool) {
        
        let numberOfSections = messages.count
        let numberOfRows = messages[numberOfSections - 1].count
        if numberOfRows > 0 {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow:numberOfRows, inSection: numberOfSections - 1), atScrollPosition: .Bottom, animated: animated)
        }
    }

    
    
    func saveMessage(message:Message){
        let saveObject = PFObject(className: "Messages")
        saveObject["incoming"] = message.incoming
        saveObject["text"] = message.text
        saveObject["sentDate"] = message.sentDate
        saveObject["url"] = message.url
        let user = PFUser.currentUser()
        saveObject["createdBy"] = user
        saveObject.saveEventually { (success, error) -> Void in
            
            if success{
                print("消息保存成功!")
            }else{
                
                print("消息保存失败! \(error)")
                
            }
        }
        
    }
    
    var question: String?
    let api_key = "5ec4749cd2fd68762ba1e56321ef1fb2"
    let api_url = "http://www.tuling123.com/openapi/api"
    let userId = "arche"

    @IBAction func sendAction(sender: UIButton) {
        sendAction()
    }
    func sendAction() {
        
        let message = Message(incoming: false, text: textView.text, sentDate: NSDate())
        saveMessage(message)
        messages.append([message])
        
        question = textView.text
        
        
        textView.text = nil
        sendButton.enabled = false
        
        let lastSection = tableView.numberOfSections
        tableView.beginUpdates()
        tableView.insertSections(NSIndexSet(index: lastSection), withRowAnimation:.Automatic)
        tableView.insertRowsAtIndexPaths([
            NSIndexPath(forRow: 0, inSection: lastSection),
            NSIndexPath(forRow: 1, inSection: lastSection)
            ], withRowAnimation: .Automatic)
        tableView.endUpdates()
        tableViewScrollToBottomAnimated(false)
        
        Alamofire.request(.GET, NSURL(string: api_url)!, parameters: ["key":api_key,"info":question!,"userid":userId]).responseJSON(options: NSJSONReadingOptions.MutableContainers) { _,_,data   in
            
            if data.isSuccess {
                if let text = data.value!.objectForKey("text") as? String{
                    
                    if let url = data.value!.objectForKey("url") as? String{
                        let message = Message(incoming: true, text:text+"\n(点击该消息打开查看)", sentDate: NSDate())
                        message.url = url
                        self.saveMessage(message)
                        self.messages[lastSection].append(message)
                    }else{
                        let message = Message(incoming: true, text:text, sentDate: NSDate())
                        self.saveMessage(message)
                        self.messages[lastSection].append(message)
                    }
                    
                    
                    self.tableView.beginUpdates()
                    self.tableView.insertRowsAtIndexPaths([
                        NSIndexPath(forRow: 2, inSection: lastSection)
                        ], withRowAnimation: .Automatic)
                    self.tableView.endUpdates()
                    self.tableViewScrollToBottomAnimated(false)
                    
                }
            }else{
                print("Data read error \(data.error)")
            }
            
        }
        
        
        
    }

    func keyboardWillShow(notification: NSNotification) {
        
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height
        let insetOld = tableView.contentInset
        let insetChange = insetNewBottom - insetOld.bottom
        let overflow = tableView.contentSize.height - (tableView.frame.height-insetOld.top-insetOld.bottom)
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animations: (() -> Void) = {
            if !(self.tableView.tracking || self.tableView.decelerating) {
                // 根据键盘位置调整Inset
                if overflow > 0 {
                    self.tableView.contentOffset.y += insetChange
                    if self.tableView.contentOffset.y < -insetOld.top {
                        self.tableView.contentOffset.y = -insetOld.top
                    }
                } else if insetChange > -overflow {
                    self.tableView.contentOffset.y += insetChange + overflow
                }
            }
        }
        if duration > 0 {
            let options = UIViewAnimationOptions(rawValue: UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height
        
        // Inset `tableView` with keyboard
        let contentOffsetY = tableView.contentOffset.y
        tableView.contentInset.bottom = insetNewBottom
        tableView.scrollIndicatorInsets.bottom = insetNewBottom
        // Prevents jump after keyboard dismissal
        if self.tableView.tracking || self.tableView.decelerating {
            tableView.contentOffset.y = contentOffsetY
        }
    }


}
