//
//  MenuListViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/17/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit

class MenuListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
   
    @IBOutlet weak var menuView: MenuListView!
    var menu = Menu()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        self.menuView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.menuView.nameLbl.text = Session.shared.userName()
        self.menuView.emailLbl.text = Session.shared.userEmail()
        self.menuView.terminalLbl.text = PaymentSettings.shared.selectedTerminalName()
    }
//
//    func addInBlurEffect() {
//        let blurEffect = UIBlurEffect(style: .dark)
//        let visualEffect = UIVisualEffectView(effect: blurEffect)
//        visualEffect.frame = self.view.bounds
//        visualEffect.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        visualEffect.alpha = 0.3
//        self.bgImageView.addSubview(visualEffect)
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension MenuListViewController {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
        cell.textLabel?.text = menu.options[indexPath.row]
        cell.textLabel?.font = UIFont(name: "poppins-regular", size: 15)
        cell.imageView?.image = UIImage(named: menu.imageNames[indexPath.row])
        cell.imageView?.image?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -55, bottom: 0,
                                                             right: 0))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var controllerName: String!
        switch indexPath.row {
        case 0:
            controllerName = "checkoutController"
        case 1:
            controllerName = "settingsController"
        case 2:
            controllerName = "transactionsController"
        default:
            controllerName = "checkoutController"
        }
        let selectedVc = self.storyboard?.instantiateViewController(withIdentifier: controllerName)
        sideMenuController?.setContentViewController(to: selectedVc!)
        sideMenuController?.hideMenu()
    }
}
