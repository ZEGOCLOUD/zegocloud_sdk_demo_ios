//
//  ZegoDefine.swift
//  ZegoCallWithInvitationDemo
//
//  Created by zego on 2023/3/14.
//

import UIKit

let ScreenHeight = UIScreen.main.bounds.size.height
let ScreenWidth = UIScreen.main.bounds.size.width
let BottomSafeAreaHeight = KeyWindow().safeAreaInsets.bottom
let TopSafeAreaHeight = KeyWindow().safeAreaInsets.top

func adaptLandscapeWidth(_ x: CGFloat) -> CGFloat {
    return x * (ScreenHeight / 375.0)
}

func adaptLandscapeHeight(_ x: CGFloat) -> CGFloat {
    return x * (ScreenHeight / 818.0)
}

func KeyWindow() -> UIWindow {
    let window: UIWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).last!
    return window
}

func currentViewController() -> (UIViewController?) {
   var window = KeyWindow()
   if window.windowLevel != UIWindow.Level.normal{
     let windows = UIApplication.shared.windows
     for  windowTemp in windows{
       if windowTemp.windowLevel == UIWindow.Level.normal{
          window = windowTemp
          break
        }
      }
    }
   let vc = window.rootViewController
   return currentViewController(vc)
}

func currentViewController(_ vc :UIViewController?) -> UIViewController? {
   if vc == nil {
      return nil
   }
   if let presentVC = vc?.presentedViewController {
      return currentViewController(presentVC)
   }
   else if let tabVC = vc as? UITabBarController {
      if let selectVC = tabVC.selectedViewController {
          return currentViewController(selectVC)
       }
       return nil
    }
    else if let naiVC = vc as? UINavigationController {
       return currentViewController(naiVC.visibleViewController)
    }
    else {
       return vc
    }
 }
