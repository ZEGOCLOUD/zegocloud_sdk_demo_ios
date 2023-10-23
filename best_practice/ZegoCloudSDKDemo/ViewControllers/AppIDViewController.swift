//
//  AppIDViewController.swift
//  ZegoCloudSDKDemo
//
//  Created by zego on 2023/7/18.
//

import UIKit

class AppIDViewController: UIViewController {
    
    @IBOutlet weak var appIDTextField: UITextField! {
        didSet {
            appIDTextField.text = "\(APP_ID)"
        }
    }
    @IBOutlet weak var appSignTextField: UITextField! {
        didSet {
            appSignTextField.text = APP_SIGN
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func startExperienceClick(_ sender: Any) {
        guard let appID = appIDTextField.text,
        let appSign = appSignTextField.text
        else { return }
        let loginVC: LoginViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        loginVC.appID = UInt32(appID) ?? 0
        loginVC.appSign = appSign
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

}
