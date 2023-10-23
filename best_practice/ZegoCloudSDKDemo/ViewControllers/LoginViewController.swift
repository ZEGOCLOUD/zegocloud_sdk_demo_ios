//
//  LoginViewController.swift
//  ZegoLiveStreamingCohostingDemo
//
//  Created by Kael Ding on 2023/3/30.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    
    var appID: UInt32 = APP_ID
    var appSign: String = APP_SIGN
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let selfUserID = UserDefaults.standard.string(forKey: "userID") ?? String(UInt32.random(in: 100..<10000))
        let selfUserName = UserDefaults.standard.string(forKey: "userName") ?? randomName()
        userIDTextField.text = selfUserID
        userNameTextField.text = selfUserName
        
        initData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // logout
        ZegoSDKManager.shared.disconnectUser()
    }
    
    func initData() {        
        ZegoSDKManager.shared.initWith(appID: appID, appSign: appSign, enableBeauty: true)
        CallService.shared.initService()
    }


    @IBAction func loginAction(_ sender: UIButton) {
        let userID = userIDTextField.text ?? "123"
        let userName = userNameTextField.text ?? "Tina"
        
        // save user id and user name.
        UserDefaults.standard.set(userID, forKey: "userID")
        UserDefaults.standard.set(userName, forKey: "userName")
        
        ZegoSDKManager.shared.connectUser(userID: userID, userName: userName) { code , message in
            if code == 0 {
                self.performSegue(withIdentifier: "login", sender: sender)
            } else {
                self.view.makeToast("zim login failed:\(code)", duration: 2.0, position: .center)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let homeVC = segue.destination as? HomeViewController else {
            return
        }
        homeVC.userID = userIDTextField.text ?? "123"
        homeVC.userName = userNameTextField.text ?? "Tina"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
}

