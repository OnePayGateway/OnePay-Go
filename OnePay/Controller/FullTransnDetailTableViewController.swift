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
    var keysArr = Array<String>()
    var titlesArr = Array<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        keysArr = ["Id", "TerminalId", "TransactionAmount", "ApprovedAmount", "SettlementAmount", "Method", "TransactionType", "AccountNumberLast4", "ExpirationDate", "CardType", "InvoiceNumber", "Nonce", "ReferenceTransactionId", "RelatedTransactionID", "TransactionNotes", "CustomerId", "Email", "FirstName", "LastName", "Street1", "Street2", "City", "State", "Zip", "PhoneNumber", "ResultCode", "ResultSubCode", "ResultText", "TransactionDatetime", "MerchantTransactionDateTime", "BatchId", "SettledStatus", "AVSResultCode", "CVVResultCode", "AuthID", "AuthNtwkName", "ProcessorTranID", "ProcessorACI", "ProcessorCardLevelResultCode", "ClientIP", "SourceApplication", "SourceUser", "SourceIP"]
        
        titlesArr = ["Transaction Id", "Terminal Id", "Transaction Amount", "Approved Amount", "Settlement Amount", "Transaction Method", "Transaction Type", "Account Number Last4", "Expiration Date", "Card Type", "Invoice Number", "Nonce", "Reference Transaction Id", "Related Transaction ID", "Transaction Notes", "Customer Id", "Email", "First Name", "Last Name", "Street1", "Street2", "City", "State", "Zip", "Phone Number", "Result Code", "Result Sub Code", "Result Text", "Transaction Datetime", "Merchant Transaction DateTime", "BatchId", "SettledStatus", "AVS Result Code", "CVV Result Code", "Authorization ID", "AuthNtwkName", "Processor Transaction Id", "Processor ACI", "Processor Card Level Result Code", "Client IP", "Source Application", "Source User", "Source IP"]
        
        
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
        return 1
    }

    @IBAction func backClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print(keysArr)
        print(keysArr.count)
        return keysArr.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "transDetailCell", for: indexPath)
        let keyStr = keysArr[indexPath.row]
        let transaction = transactionInfo["Transaction"].dictionaryValue
        let value = transaction[keyStr]?.stringValue
        cell.textLabel?.text = titlesArr[indexPath.row]
        cell.detailTextLabel?.text = value
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
