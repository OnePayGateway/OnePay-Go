//
//  TransactionInfoViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/4/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol voidDelegate {
    func madeVoidPayment()
}

class TransactionInfoViewController: UITableViewController {
    
    var transactionId: String!
    var transactionStatus: String!
    var cardBrandImage: UIImage!
    var transactionInfo: JSON = [:]

    @IBOutlet weak var cardBrandImageView: UIImageView!
    @IBOutlet weak var amountLbl: UILabel!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!

    @IBOutlet weak var transactionIdLbl: UILabel!
    @IBOutlet weak var cardInfoLbl: UILabel!
    @IBOutlet weak var settleStatusLbl: UILabel!

    @IBOutlet weak var voidBtn: BorderedButton!
    
    var vDelegate: voidDelegate!
    
    var transactionDetail: TransactionDetail? {
        didSet {
            guard let detail = transactionDetail else {
                return
            }
            DispatchQueue.main.async {
                self.statusLbl.text = detail.paymentStatus
                self.amountLbl.text = String(format: "$%0.2f", detail.totalAmount!)
                self.dateLbl.text = detail.date
                self.timeLbl.text = detail.time
                self.transactionIdLbl.text = "ID:\(self.transactionId!)"
                self.cardInfoLbl.text = "\(detail.cardType!)***\(detail.lastFourDigits!)"
                self.settleStatusLbl.text = detail.settlementStatus
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardBrandImageView.image = cardBrandImage
        if(transactionStatus == "Void" || transactionStatus == "Declined") {
            self.voidBtn.alpha = 0.3
            self.voidBtn.isUserInteractionEnabled = false
        }
        retreiveDetails()
        // Do any additional setup after loading the view.
    }
    
    func retreiveDetails() {
        showSpinner(onView: self.view)
        TransactionDetailService().getTransactionDetailFor(Id: self.transactionId) { (json, err) in
            DispatchQueue.main.async {
            if(err == nil) {
                print(json!)
                let msg = json?.dictionaryValue["Message"]
                if msg == "Authorization has been denied for this request." {
                    LoginService().refreshTokenInServer(success: { (status) in
                        if status == true {
                            self.retreiveDetails()
                        } else {
                            self.hideSpinner()
                            Session.shared.logOut()
                            let loginVc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController()
                            self.view.window?.rootViewController = loginVc
                        }
                    })
                    return
                }
                
                let transaction = json?["Transaction"].dictionaryValue
                self.transactionInfo = json!
                let itemName = transaction?["CustomerNotes"]?.stringValue
                let itemAmount = transaction?["ApprovedAmount"]?.floatValue
                let totalAmount = transaction?["ApprovedAmount"]?.floatValue
                let cardType = transaction?["AuthNtwkName"]?.stringValue
                let lastFour = transaction?["AccountNumberLast4"]?.stringValue
                let receiptNum = transaction?["InvoiceNumber"]?.stringValue
                
                let settleStatus = transaction?["SettledStatus"]?.intValue
                let paymentStatus = transaction?["ResultText"]?.stringValue
                let dateTime = json?["DateTime"].stringValue.convertToDate(with: "MM/dd/yy hh:mm a")?.generateCurrentDateTime()
                
                let detail = TransactionDetail(itemname: itemName, itemamount: itemAmount, totalamount: totalAmount, cardtype: cardType, lastfour: lastFour, receiptnum: receiptNum)
                detail.settlementStatus = settleStatus == 1 ? "Settled" : "Unsettled"
                detail.paymentStatus = paymentStatus
                if let dateTimeArr = dateTime?.components(separatedBy: ","), dateTimeArr.count > 1 {
                    detail.date = dateTimeArr[0]
                    detail.time = dateTimeArr[1]
                }
                self.transactionDetail = detail
            
                self.hideSpinner()
                
            } else {
                self.hideSpinner()
                self.displayAlert(title: err!.localizedDescription, message: "")
            }
          }
        }
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .default
//    }
    
    @IBAction func voidBtnClicked(_ sender: Any) {
        if(transactionDetail != nil) {
            showSpinner(onView: self.view)
            createApiKey()
        }
    }
    
    func createApiKey() {
        
        ApiKeyService().getApiKeyFromServer(success: { (key, er) in
            DispatchQueue.main.async {
            guard er == nil else {
                self.hideSpinner()
                self.displayAlert(title: "Something went wrong", message: er!.localizedDescription)
                return
            }
            
            print("api key is\(key!)")
            Session.shared.setApi(Key: key!)
            self.makeVoidTransaction()
            }
        })
    }
    
    func makeVoidTransaction() {
        var cardInfo = Dictionary<String, Any>()
        cardInfo["number"] = self.transactionDetail?.lastFourDigits
        VoidTransactionService().makePayment(amount:String(format: "%0.2f", self.transactionDetail!.totalAmount!), transactionId: "\(self.transactionId!)", cardInfo: cardInfo, marketCode: "R") { (json, err) in
            DispatchQueue.main.async {
                self.hideSpinner()
                guard err == nil else {
                    self.hideSpinner()
                    self.displayAlert(title: err!.localizedDescription, message: "")
                    return
                }
                guard let jsonValue = json else {
                    self.hideSpinner()
                    self.displayAlert(title: "Something went wrong", message: "")
                    return
                }
                print(jsonValue)
                let response = jsonValue["transaction_response"].dictionaryValue
                if let code = response["result_code"]?.intValue, code == 1 {
                    print("payment success")
                    self.hideSpinner()
                    self.showConfirmAlert()
                } else if let status = response["result_text"]?.stringValue {
                    self.hideSpinner()
                    self.displayAlert(title: status, message: "")
                }
            }
        }
    }
    
    func showConfirmAlert() {
        let alertVc = UIAlertController(title: "Void transaction is done", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Done", style: .default) { (done) in
            self.vDelegate.madeVoidPayment()
            self.navigationController?.popViewController(animated: true)
        }
        alertVc.addAction(action)
        self.present(alertVc, animated: true, completion: nil)
    }
    
    @IBAction func backClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    /*
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = 120 - (scrollView.contentOffset.y + 120)
        let height = min(max(y, 100), 400)
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height)
    }
*/
    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if(segue.identifier == "transactionToReceipt") {
            if let receiptVc = segue.destination as? ReceiptViewController {
                receiptVc.reference_transaction_id = transactionId
            }
        } else {
            if let detailView = segue.destination as? FullTransnDetailTableViewController {
                detailView.transactionInfo = transactionInfo
            }
        }
    }
    

}
