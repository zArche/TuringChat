//
//  WelcomeViewController.swift
//  TuringChat
//
//  Created by arche on 16/1/25.
//  Copyright © 2016年 arche. All rights reserved.
//

import UIKit
import Parse
import ParseUI



class WelcomeViewController: UIViewController,PFLogInViewControllerDelegate,PFSignUpViewControllerDelegate {

    @IBAction func logout(sender: UIBarButtonItem) {
        user = nil
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            PFUser.logOut()
        }
        
    }
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var chatBtn: UIBarButtonItem!
    var user: PFUser? {
        willSet{
            if(newValue != nil){
                self.welcomeText.text = "Welcome \(newValue!.username!)"
                chatBtn.enabled = true
                delay(seconds: 2.0, completion: { () -> () in
                    //enter chat view
                    let ub = UIStoryboard(name: "Main", bundle: nil)
                    let chatVC = ub.instantiateViewControllerWithIdentifier(Identifier.ChatViewControllerStoryBoardIdentifier) as! ChatViewController
//                    let chatVC = ChatViewController()
                    chatVC.user = self.user
                    chatVC.title = "灵灵"
                    self.navigationController?.pushViewController(chatVC, animated: true)
//                    self.presentViewController(chatVC, animated: true, completion: nil)
                    
                })
            }else{
                self.welcomeText.text = "未登录"
                chatBtn.enabled = false
                delay(seconds: 2.0, completion: { () -> () in
                    //enter login view
                    self.loginVC = PFLogInViewController()
                    self.signUpVC = PFSignUpViewController()
                    self.presentViewController(self.loginVC!, animated: true, completion: nil)
                })

            }
        }
    }

    var loginVC: PFLogInViewController?{
        didSet{
            self.loginVC?.delegate = self
            self.loginVC?.logInView?.logo = UIImageView(image: UIImage(named: "logo"))
        }
    }
    var signUpVC: PFSignUpViewController?{
        didSet{
            self.signUpVC?.delegate = self
            self.signUpVC?.signUpView?.logo = UIImageView(image: UIImage(named: "logo"))
            if self.loginVC != nil{
               self.loginVC?.signUpController = self.signUpVC
            }
            
        }
    }
 
    func delay(seconds seconds:Double,completion:()->()){
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,Int64(Double(NSEC_PER_SEC)*seconds))
        dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
            completion()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = PFUser.currentUser()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Identifier
    struct Identifier{
        static let ChatViewControllerSegueIdentifier = "Show Chat View"
        static let ChatViewControllerStoryBoardIdentifier = "Chat View Controller"
    }

   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let id = segue.identifier
        if(id == Identifier.ChatViewControllerSegueIdentifier){
            let chatVC = segue.destinationViewController as! ChatViewController
            chatVC.user = self.user
            chatVC.title = "灵灵"
        }
    }

    
    // MARK: - LoginDelegate
    
    //login begin
    func logInViewController(logInController: PFLogInViewController, shouldBeginLogInWithUsername username: String, password: String) -> Bool {
        if(username.isEmpty || password.isEmpty){
//            UIAlertView(title: "信息不完整", message: "请输入正确的账号和密码", delegate: self, cancelButtonTitle: "确定").show()
            let alert = UIAlertController(title: "信息不完整", message: "请输入正确的账号和密码", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Cancel, handler: nil))

            self.loginVC!.presentViewController(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
    //login successfully
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        self.user = user
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    //login faild
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        UIAlertView(title: "用户名或密码错误", message: "请重试", delegate: self, cancelButtonTitle:"确定").show()
    }
    //login cance
    func logInViewControllerDidCancelLogIn(logInController: PFLogInViewController) {
        self.user = PFUser.currentUser()
    }
    
    
    //MARK: - SignUpDelegate
    
    func signUpViewController(signUpController: PFSignUpViewController, shouldBeginSignUp info: [NSObject : AnyObject]) -> Bool {
        var informationComplete = true
        for value in info.values {
            let field = value as! String
            if(field.isEmpty){
                informationComplete = false
                break
            }
        }
        if(!informationComplete){
            UIAlertView(title: "缺少信息", message: "请补全缺少的信息", delegate: self, cancelButtonTitle:"确定").show()
        }
        return informationComplete
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        self.user = user
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
