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
    
    var sectionTitles = Array<String>()
    
    var payemntKeysArr = Array<String>()
    var settlementKeysArr = Array<String>()
    var authorisationKeysArr = Array<String>()
    var trnsnSourceKeysArr = Array<String>()
    var orderInfoKeysArr = Array<String>()
    var custrBillKeysArr = Array<String>()
    var trnsnResultsKeysArr = Array<String>()
    var cardInfoKeysArr = Array<String>()

    var paymentValuesArr = Array<String>()
    var settlementValuesArr = Array<String>()
    var authorisationValuesArr = Array<String>()
    var trnsnSourceValuesArr = Array<String>()
    var orderInfoValuesArr = Array<String>()
    var custrBillValuesArr = Array<String>()
    var trnsnResultsValuesArr = Array<String>()
    var cardInfoValuesArr = Array<String>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sectionTitles = Array(arrayLiteral: "Payment Information","Settlement Information","Authorization Information","Transaction Source","Order Information","Customer Billing Information","Transaction Result","Card Information")
        
        payemntKeysArr = ["AccountType", "AccountNumberLast4", "ExpirationDate", "ApprovedAmount", "Method", "Token", "POSEntryModeDesc"]
        settlementKeysArr = ["SettlementAmount", "SettlementDate", "SettledStatus"]
        authorisationKeysArr = ["ApprovedAmount", "TransactionDatetime", "AuthID", "ReferenceTransactionId", "RelatedTransactionID", "TransactionNotes", "TransactionType", "Id", "TerminalId", "MerchantTerminalID", "IndustryTransactionCode", "ProductDescription", "AVSResultCode"]
        
        trnsnSourceKeysArr = ["ClientIP", "SourceApplication", "SourceUser", "SourceIP"]
        orderInfoKeysArr = ["InvoiceNumber", "Nonce"]
        custrBillKeysArr = ["FirstName", "Company", "Street1", "City", "State", "Country", "Zip", "PhoneNumber", "Email", "CustomerId", "EmailReceipt"]
        
        trnsnResultsKeysArr = ["ResultCode", "ResultSubCode", "ResultText", "BatchId", "AuthNtwkName", "ProcessorTranID", "ProcessorACI", "ProcessorCardLevelResultCode"]
        
        cardInfoKeysArr = ["CardCaptCap", "card_class", "product_id", "prepaid_indicator", "detailcard_indicator", "debitnetwork_indicator"]
        
        
        
        paymentValuesArr = ["Type", "Account Number", "Expiration Date", "Transaction Amount", "Payment Method", "Token", "Entry Mode"]
        settlementValuesArr = ["Settlement Amount", "Settlement Date Time", "Settled Status"]
        authorisationValuesArr = ["Authorized Amount", "Transaction Date Time", "Authorization Code", "Reference Transaction ID", "Related Transaction ID", "Transaction Notes", "Transaction Type", "Transaction Id", "Terminal Id", "Terminal Name", "Market Type", "Product", "Address Verification"]
        
        trnsnSourceValuesArr = ["Customer IP", "Solution Name", "Source User", "Source IP"]
        orderInfoValuesArr = ["Invoice Number", "Nonce"]
        custrBillValuesArr = ["Name", "Company", "Address", "City", "State", "Country", "Zip", "Phone Number", "Email", "Customer ID", "Email Receipt"]
        trnsnResultsValuesArr = ["Result Code", "Result Subcode", "Result Text", "Batch ID", "AuthNtwkName", "Processor Transaction Id", "Processor ACI", "Processor Card Level"]
        cardInfoValuesArr = ["Card Info", "Card Class", "Product ID", "Prepaid Indicator", "Detail Card Indicator", "Debit Network Indicator"]

        // Uncomment the following line to preserve selection between pressentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sectionTitles.count
    }

    @IBAction func backClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return paymentValuesArr.count
        } else if section == 1 {
            return settlementValuesArr.count
        } else if section == 2 {
            return authorisationValuesArr.count
        } else if section == 3 {
            return trnsnSourceKeysArr.count
        } else if section == 4 {
            return orderInfoKeysArr.count
        } else if section == 5 {
            return custrBillKeysArr.count
        } else if section == 6 {
            return trnsnResultsKeysArr.count
        } else if section == 7 {
            return cardInfoKeysArr.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let titleStr = sectionTitles[section]
        return titleStr
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            let titleStr = sectionTitles[section]
            headerView.textLabel?.text = titleStr
            headerView.textLabel?.font = UIFont(name: "poppins-semibold", size: 16)
            headerView.textLabel?.textColor = UIColor(named: "blueTextColor")
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "transDetailCell", for: indexPath)
        
        let transaction = transactionInfo["Transaction"].dictionaryValue
        
        var titleStr = ""
        var keyStr = ""
        var valueStr = ""

        if indexPath.section == 0 {
            titleStr = paymentValuesArr[indexPath.row]
            keyStr = payemntKeysArr[indexPath.row]
        } else if indexPath.section == 1 {
            titleStr = settlementValuesArr[indexPath.row]
            keyStr = settlementKeysArr[indexPath.row]
        } else if indexPath.section == 2 {
            titleStr = authorisationValuesArr[indexPath.row]
            keyStr = authorisationKeysArr[indexPath.row]
        } else if indexPath.section == 3 {
            titleStr = trnsnSourceValuesArr[indexPath.row]
            keyStr = trnsnSourceKeysArr[indexPath.row]
        } else if indexPath.section == 4 {
            titleStr = orderInfoValuesArr[indexPath.row]
            keyStr = orderInfoKeysArr[indexPath.row]
        } else if indexPath.section == 5 {
            titleStr = custrBillValuesArr[indexPath.row]
            keyStr = custrBillKeysArr[indexPath.row]
        } else if indexPath.section == 6 {
            titleStr = trnsnResultsValuesArr[indexPath.row]
            keyStr = trnsnResultsKeysArr[indexPath.row]
        } else if indexPath.section == 7 {
            titleStr = cardInfoValuesArr[indexPath.row]
            keyStr = cardInfoKeysArr[indexPath.row]
        }
        
        cell.textLabel?.text = titleStr
        
        if (indexPath.section == 0 && indexPath.row == 3) || (indexPath.section == 1 && indexPath.row == 0) || (indexPath.section == 2 && indexPath.row == 0) {
            valueStr = transactionInfo[keyStr].stringValue
        } else {
            valueStr = transaction[keyStr]?.stringValue ?? ""
        }
        
        if indexPath.section == 1, indexPath.row == 2 {
            if valueStr == "1" {
                valueStr = "Settled"
            } else if valueStr == "2" && valueStr == "3" {
                valueStr = "Void"
            } else {
                valueStr = "Unsettled"
            }
        }
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
