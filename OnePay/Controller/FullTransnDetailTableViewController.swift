//
//  FullTransnDetailTableViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 9/2/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import SwiftyJSON

class FullTransnDetailTableViewController: UITableViewController {

    var transactionInfo: JSON = [:]
    
    var payemntKeysArr = Array<String>()
    var settlementKeysArr = Array<String>()
    var authorisationKeysArr = Array<String>()

    var paymentSectionArr = Array<String>()
    var settlementSectionArr = Array<String>()
    var authorisationSectionArr = Array<String>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        payemntKeysArr = ["TransactionType", "AccountNumberLast4", "ExpirationDate", "TransactionAmount", "Method", "Token", "POSEntryModeDesc"]
        
        settlementKeysArr = ["SettlementAmount", "SettlementDatetime", "SettledStatus"]

        
        authorisationKeysArr = ["ApprovedAmount", "TransactionDatetime", "AuthID", "ReferenceTransactionId", "RelatedTransactionID", "TransactionNotes", "TransactionType", "Id", "TerminalId", "TerminalName", "IndustryTransactionCode", "Product", "Address Verification"]
        
        
        paymentSectionArr = ["Type", "Account Number", "Expiration Date", "Transaction Amount", "Payment Method", "Token", "Entry Mode"]
        
        settlementSectionArr = ["Settlement Amount", "Settlement Date Time", "Settled Status"]
        
        authorisationSectionArr = ["Authorized Amount", "Transaction Date Time", "Authorization Code", "Reference Transaction ID", "Related Transaction ID", "Transaction Notes", "Transaction Type", "Transaction Id", "Terminal Id", "Terminal Name", "Market Type", "Product", "Address Verification"]

        
        
//        let transaction = transactionInfo["Transaction"].dictionaryValue
//        let keys = Array(requiredDataDic.keys)
//
//        for key in keys {
//            let value = transaction[key]?.stringValue
//           // if(value!.count > 0) {
//                keysArr.append(key)
//          //  }
//        }
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    @IBAction func backClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return paymentSectionArr.count
        } else if section == 1 {
            return settlementSectionArr.count
        }
        return authorisationSectionArr.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Payment Information"
        } else if section == 1 {
            return "Settlement Information"
        }
        return "Authorization Information"
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "transDetailCell", for: indexPath)
        
        let transaction = transactionInfo["Transaction"].dictionaryValue
        
        var titleStr = ""
        var keyStr = ""
        var valueStr = ""

        if indexPath.section == 0 {
            titleStr = paymentSectionArr[indexPath.row]
            keyStr = payemntKeysArr[indexPath.row]
        } else if indexPath.section == 1 {
            titleStr = settlementSectionArr[indexPath.row]
            keyStr = settlementKeysArr[indexPath.row]
        } else {
            titleStr = authorisationSectionArr[indexPath.row]
            keyStr = authorisationKeysArr[indexPath.row]
        }
        cell.textLabel?.text = titleStr
        valueStr = transaction[keyStr]?.stringValue ?? ""
        cell.detailTextLabel?.text = valueStr
        return cell
        
    }
    

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
