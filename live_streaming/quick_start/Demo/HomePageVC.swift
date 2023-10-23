import Foundation
import UIKit
import ZegoExpressEngine

// Get your AppID and AppSign from ZEGOCLOUD Console
// [My Projects -> AppID] : https://console.zegocloud.com/project
let appID : UInt32 = 
let appSign: String = ""


class HomePageVC: UIViewController {
    
    @IBOutlet weak var roomIDTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createEngine()
    }
    
    @IBAction func joinLiveAsHostClick(_ sender: UIButton) {
        let roomID = roomIDTextField.text ?? ""
        presentLiveVC(isHost:true, roomID:roomID)
    }
    
    @IBAction func joinLiveAsAudienceClick(_ sender: UIButton) {
        let roomID = roomIDTextField.text ?? ""
        presentLiveVC(isHost:false, roomID:roomID)
    }

    
    func presentLiveVC(isHost: Bool, roomID: String){
        let localUserID = "\(Int32(arc4random() % 100000))"
        let liveVC: LiveStreamingVC = LiveStreamingVC(roomID:roomID, localUserID:localUserID, isHost:isHost)
        self.modalPresentationStyle = .fullScreen
        liveVC.modalPresentationStyle = .fullScreen
        self.present(liveVC, animated: true, completion: nil)
    }
    
    private func createEngine() {
        let profile = ZegoEngineProfile()
        // Get your AppID and AppSign from ZEGOCLOUD Console
        //[My Projects -> AppID] : https://console.zegocloud.com/project
        profile.appID = appID
        profile.appSign = appSign
        profile.scenario = .broadcast
        // Create a ZegoExpressEngine instance
        ZegoExpressEngine.createEngine(with: profile, eventHandler: nil)
    }

    private func destroyEngine() {
        ZegoExpressEngine.destroy(nil)
    }
    
}
