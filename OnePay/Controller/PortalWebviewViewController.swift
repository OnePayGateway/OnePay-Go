//
//  PortalWebviewViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 6/28/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import WebKit

class PortalWebviewViewController: UIViewController,WKNavigationDelegate {
    @IBOutlet weak var webview: WKWebView!
    var urlString : String?
    
    @IBAction func backClicked(_ sender: Any) {
        if Session.shared.isLoggedIn() {
            sideMenuController?.revealMenu()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSpinner(onView: self.view)
        var url:URL!
        guard let urlValue = urlString else {
            return
        }
        
        url = URL(string: urlValue)
    
        webview.load(URLRequest(url: url))
        webview.allowsBackForwardNavigationGestures = true
        webview.navigationDelegate = self
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func menuPressed(_ sender: Any) {
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideSpinner()
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
