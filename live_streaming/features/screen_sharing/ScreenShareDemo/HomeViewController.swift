//
//  HomeViewController.swift
//  ScreenShareDemo
//
//  Created by Kael Ding on 2023/5/15.
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var userIDLabel: UILabel!
    
    @IBOutlet weak var liveIDTextField: UITextField!
    
    var userID: String = ""
    var userName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        userIDLabel.text = "User ID: " + userID
        liveIDTextField.text = String(UInt32.random(in: 100..<1000))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let liveVC = segue.destination as? LiveViewController else {
            return
        }
        
        liveVC.isMySelfHost = segue.identifier! == "start_live"
        liveVC.liveID = liveIDTextField.text ?? ""
        liveVC.userID = userID
        liveVC.userName = userName
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        liveIDTextField.endEditing(true)
    }
}
