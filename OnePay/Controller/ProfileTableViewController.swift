//
//  ProfileTableViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 6/21/22.
//  Copyright © 2022 Certify Global. All rights reserved.
//

import UIKit

class ProfileTableViewController: UITableViewController {

    @IBOutlet weak var unValueLbl: UILabel!
    @IBOutlet weak var rnValueLbl: UILabel!
    @IBOutlet weak var fnValueLbl: UILabel!
    @IBOutlet weak var lnValueLbl: UILabel!
    
    @IBOutlet weak var emailValueLbl: UILabel!
    @IBOutlet weak var phoneValueLbl: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        getProfileDataForUser()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func getProfileDataForUser() {
        
        LoginService().getProfileData(success:  { (json, err)  in
            DispatchQueue.main.async {
            guard err == nil else {
                self.hideSpinner()
                return
            }
            
            let msg = json?.dictionaryValue["Message"]
            if msg == "Authorization has been denied for this request." {
                LoginService().refreshTokenInServer(success: { (status) in
                    if status == true {
                        self.getProfileDataForUser()
                    } else {
                        self.hideSpinner()
                        Session.shared.logOut()
                        let loginVc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController()
                        self.view.window?.rootViewController = loginVc
                    }
                })
                return
            }
             print(json)
                if let un = Session.shared.userName() {
                    self.unValueLbl.text = un
                }
                if let email = Session.shared.userEmail() {
                    self.emailValueLbl.text = email
                }
                guard let profileDdataDic = json?.dictionaryValue else {
                    return
                }
                if let fName = profileDdataDic["first_name"]?.stringValue,
                   let lName = profileDdataDic["last_name"]?.stringValue {
                    self.fnValueLbl.text = fName
                    self.lnValueLbl.text = lName
                }
                if let pNumber = profileDdataDic["phone_number"]?.stringValue {
                    self.phoneValueLbl.text = pNumber
                }
                if let roleArr = profileDdataDic["roles"]?.arrayValue, let roleID = profileDdataDic["roleId"]?.intValue {
                    for role in roleArr {
                        let dic = role.dictionaryValue
                        if dic["Id"]?.intValue == roleID {
                            self.rnValueLbl.text = dic["Name"]?.stringValue
                        }
                    }
                }
          }
        })
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        sideMenuController?.revealMenu()
    }

    // MARK: - Table view data source
/*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
*/
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
