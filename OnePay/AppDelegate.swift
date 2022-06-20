//
//  AppDelegate.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/16/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import Reachability
import ApplicationInsights
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var notReachableView: UIView!
   // var animationLogoView = LogoAnimationView()
    var miura: MiuraManager!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 30.0
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
      //  IQKeyboardManager.shared.previousNextDisplayMode = .alwaysHide
      //  IQKeyboardManager.shared.shouldShowToolbarPlaceholder = false
        IQKeyboardManager.shared.enableAutoToolbar = false
        
//        MSAIApplicationInsights.setup(withInstrumentationKey: "349b4bcf-54cd-4618-8266-c074f29abb96")
//        MSAIApplicationInsights.start()
        
        if Session.shared.isLoggedIn() {
           // application.statusBarUIView?.backgroundColor = UIColor.black
            let sideMenuVc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "sideMenuVc")
            self.window?.rootViewController = sideMenuVc
        }
        
//        else {
//            showLogoAnimation()
//        }
        
        startNetworkNotifier()
        self.setupAppCenter()
        
        miura = MiuraManager.sharedInstance()
        if miura == nil {
            print("ERROR: MiuraManager cannot be nil!")
        }
    
        return true
    }
    
    func setupAppCenter() {
        AppCenter.configure(withAppSecret: "fb7c1240-43f6-46ca-9437-13759b160638")
        if AppCenter.isConfigured {
            AppCenter.startService(Analytics.self)
            AppCenter.startService(Crashes.self)
        }
       }
    
    func startNetworkNotifier() {
        
        let reachability = try! Reachability()
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
            if(self.notReachableView != nil) {
                self.notReachableView.removeFromSuperview()
            }
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
            self.pullDownNotReachableView()
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    
    
    func pullDownNotReachableView() {
        let screenSize = UIScreen.main.bounds.size
        notReachableView = UIView(frame: CGRect(x: 0, y: -80, width: screenSize.width, height: 80))
        notReachableView.backgroundColor = .yellow
        notReachableView.alpha = 0.0
        let mesLbl = UILabel(frame: CGRect(x: 10, y: 40, width: screenSize.width-20, height: 20))
        mesLbl.text = "No Internet Connection"
        mesLbl.textAlignment = .center
        notReachableView.addSubview(mesLbl)
        self.window?.rootViewController?.view.addSubview(notReachableView)
        
        UIView.transition(with: notReachableView, duration: 0.4, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.notReachableView.alpha = 1.0
            self.notReachableView.frame.origin.y = 0
        }, completion: nil)
    }
    
    
    func checkIfTokenAlive() {
        LoginService().refreshTokenInServer(success: { (status) in
            if status != true {
                Session.shared.logOut()
                let loginVc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController()
                self.window?.rootViewController = loginVc
            }
        })
    }
    
//    func showLogoAnimation() {
//        self.window?.rootViewController?.view.addSubview(animationLogoView)
//        animationLogoView.pinEdgesToSuperView()
//        delay(2.00) {
//            self.animationLogoView.removeFromSuperview()
//        }
//    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let rootViewController = self.topViewControllerWithRootViewController(rootViewController: window?.rootViewController) {
            if (rootViewController.responds(to: Selector(("canRotate")))) {
                // Unlock landscape view orientations for this view controller
                return .landscapeLeft;
            }
        }
        // Only allow portrait (standard behaviour)
        return .portrait;
    }
    
    private func topViewControllerWithRootViewController(rootViewController: UIViewController!) -> UIViewController? {
        if (rootViewController == nil) {
            return nil
        }
        if (rootViewController.isKind(of: UITabBarController.self)) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UITabBarController).selectedViewController)
        } else if (rootViewController.isKind(of: UINavigationController.self)) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UINavigationController).visibleViewController)
        } else if (rootViewController.presentedViewController != nil) {
            return topViewControllerWithRootViewController(rootViewController: rootViewController.presentedViewController)
        }
        return rootViewController
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
         checkIfTokenAlive()
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}



