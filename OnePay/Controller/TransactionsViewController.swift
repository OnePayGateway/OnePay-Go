//
//  TransactionsViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 5/20/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import SwiftyJSON

class TransactionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, voidDelegate {

    @IBOutlet weak var transactionTableView: UITableView!
    @IBOutlet weak var searchImgView: UIImageView!
    @IBOutlet weak var filterTextField: UITextField!
    @IBOutlet weak var filterBtn: UIButton!
    @IBOutlet weak var filterKeyBtn: UIButton!

    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var filterKeyLbl: UILabel!
    @IBOutlet weak var filterValueLbl: UILabel!
    
    @IBOutlet weak var dateTimeView: DateTimeSelectionView!
    var transactionHistroy: TransactionHistory!
    var filteredHistory: TransactionHistory!
    
    var selectedFilterKey: String?
    var selectedFilterValue: String?
    
    var isDroppedDown: Bool = false
    var selectedDate = Date()
    
    @IBOutlet weak var optionListTable: FilterTableView!
    @IBOutlet weak var optionListTableWidth: NSLayoutConstraint!
    @IBOutlet weak var optionListTableHeight: NSLayoutConstraint!
    @IBOutlet weak var optionListTableOriginY: NSLayoutConstraint!
    
    var filterKeyArr = Array<Any>()
    var filterValueArr = Set<AnyHashable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateTimeView.loadUI()
        self.addDateTimeViewObserver()
        self.dateLbl.text = Date().generateCurrentDateString()
       // transactionTableView.contentInset = UIEdgeInsets(top: 80, left: 0, bottom: 0, right: 0)
        showSpinner(onView: self.view)
        
        filterKeyArr = Array(arrayLiteral: "All","Transaction ID","Customer ID","First Name","Last Name","Email","Phone","Transaction Amount","Card Last 4 Digits","Source Application")
        filterValueArr = ["OnepayGO","WOOCOMMERCE","PLE","Jmeter","PS","VT","EXE","paypage","Snap"]
        
        selectedFilterKey = "Source Application"
        selectedFilterValue = "OnepayGo"
        
      //  if let curdate = Date().generateCurrentDateString().convertToDate(with: "MM/dd/yyyy") {
            self.selectedDate = Date()
            getTransactionsList()
      //  }
       
        // Do any additional setup after loading the view.
    }
    
    
    func addDateTimeViewObserver() {
        dateTimeView.cancelClicked = {
            self.dateTimeView.isHidden = true
            self.dateTimeView.apptDate = nil
        }
        dateTimeView.doneClicked = {
            guard let pickedDate = self.dateTimeView.apptDate else {
                self.displayAlert(title: "", message: "Select Appointment Date")
                return
            }
            self.dateTimeView.isHidden = true
            self.dateLbl.text = pickedDate.generateCurrentDateString()
            self.selectedDate = pickedDate
            self.getTransactionsList()
        }
    }

    func madeVoidPayment() {
        getTransactionsList()
    }
    
    func getTransactionsList() {
        let fromDate = selectedDate.changeDaysBy(days: 0, time: "00:00:00")
        let toDate = selectedDate.changeDaysBy(days: 0, time: "23:59:00")
        TransactionHistoryService().retrieveTransactions(from: fromDate, to: toDate) { (json, err) in
            DispatchQueue.main.async {
            if(err == nil) {
                let msg = json?.dictionaryValue["Message"]
                if msg == "Authorization has been denied for this request." {
                    LoginService().refreshTokenInServer(success: { (status) in
                        if status == true {
                            self.getTransactionsList()
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
                self.transactionHistroy = TransactionHistory(transactionsList: json!.arrayValue)
                if let valueType = self.selectedFilterValue {
                    self.filterTransactions(for: valueType)
                } else {
                    self.showTransactions(for: self.selectedDate)
                }
                self.hideSpinner()
              }
            else {
                self.hideSpinner()
                self.displayAlert(title: err!.localizedDescription, message: "")
            }
          }
        }
    }
    
    @IBAction func calClicked(_ sender: Any) {
        self.optionListTable.isHidden = true
        isDroppedDown = false
        self.dateTimeView.isHidden = false
    }
    
    @IBAction func filterTypeClicked(_ sender: Any) {
        guard isDroppedDown == false else {
            self.optionListTable.isHidden = true
            isDroppedDown = false
            return
        }
        self.optionListTableWidth.constant = self.filterKeyBtn.frame.size.width
        self.optionListTableHeight.constant = 250
        self.optionListTableOriginY.constant = 74
        self.optionListTable.delegate = self
        self.optionListTable.loadFilterKey(list: filterKeyArr)
        self.optionListTable.reloadData()
        self.dateTimeView.isHidden = true
        self.optionListTable.isHidden = false
        isDroppedDown = true
    }
    
    @IBAction func filterValueClicked(_ sender: Any) {
        guard isDroppedDown == false else {
            self.optionListTable.isHidden = true
            isDroppedDown = false
            return
        }
        self.optionListTableWidth.constant = self.view.frame.size.width - 40
        self.optionListTableOriginY.constant = 134
        self.optionListTable.delegate = self
        if filterValueArr.count < 5 {
            self.optionListTableHeight.constant = CGFloat(50 * filterValueArr.count)
        }
        self.optionListTable.loadFilterValue(list: filterValueArr.reversed())
        self.optionListTable.reloadData()
        self.dateTimeView.isHidden = true
        self.optionListTable.isHidden = false
        isDroppedDown = true
    }
    
    func showTransactions(for selectedDay: Date) {
        guard self.transactionHistroy != nil else {
            return
        }
        var transactionsList = [JSON]()
        for (index, transaction) in self.transactionHistroy.transactionsList.enumerated() {
            if let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), selectedDay.days(from: tranDate) == 0 {
                transactionsList.append(transaction)
            }
        }
        self.filteredHistory = TransactionHistory(transactionsList: transactionsList)
        self.transactionTableView.backgroundView = self.messageLabel(message: "")
        if self.filteredHistory.transactionsList.count == 0 {
            self.transactionTableView.backgroundView = self.messageLabel(message: "No data found")
        }
        self.transactionTableView.reloadData()
    }
    
    func filterTransactions(for valueType: String) {
        var transactionsList = [JSON]()
        guard self.transactionHistroy != nil else {
            return
        }
              switch selectedFilterKey {
              case "All":
                  filteredHistory = nil
                  break
              case "Transaction ID":
                  for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
        
                      if transactionHistroy.transactionId(forIndex: index) == valueType, let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), self.selectedDate.days(from: tranDate) == 0  {
                          transactionsList.append(transaction)
                      }
                  }
                  break
              case "Customer ID":
                  for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                      if transactionHistroy.customerId(forIndex: index) == valueType, let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), self.selectedDate.days(from: tranDate) == 0  {
                          transactionsList.append(transaction)
                      }
                  }
                  break
              case "First Name":
                  for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                      if transactionHistroy.firstName(forIndex: index) == valueType, let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), self.selectedDate.days(from: tranDate) == 0   {
                          transactionsList.append(transaction)
                      }
                  }
                  break
              case "Last Name":
                  for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                      if transactionHistroy.lastName(forIndex: index) == valueType, let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), self.selectedDate.days(from: tranDate) == 0   {
                          transactionsList.append(transaction)
                      }
                  }
                  break
              case "Email":
                  for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                      if transactionHistroy.email(forIndex: index) == valueType, let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), self.selectedDate.days(from: tranDate) == 0  {
                          transactionsList.append(transaction)
                      }
                  }
                  break
              case "Phone":
                  for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                      if transactionHistroy.phone(forIndex: index) == valueType, let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), self.selectedDate.days(from: tranDate) == 0  {
                          transactionsList.append(transaction)
                      }
                  }
                  break
              case "Transaction Amount":
                  for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                      if String(format: "$%0.2f", transactionHistroy.amount(forIndex: index)!)  == valueType, let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), self.selectedDate.days(from: tranDate) == 0   {
                          transactionsList.append(transaction)
                      }
                  }
                  break
              case "Card Last 4 Digits":
                  for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                      if transactionHistroy.lastFourDigit(forIndex: index) == valueType, let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), self.selectedDate.days(from: tranDate) == 0  {
                          transactionsList.append(transaction)
                      }
                  }
                  break
              case "Source Application":
                  for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                      if transactionHistroy.sourceApplication(forIndex: index)?.lowercased() == valueType.lowercased(), let tranDate = self.transactionHistroy.transactionDate(forIndex: index)?.convertToDate(with: "MM/dd/yyyy hh:mm:ss a")?.generateCurrentDateString().convertToDate(with: "MM/dd/yyyy"), self.selectedDate.days(from: tranDate) == 0  {
                          transactionsList.append(transaction)
                      }
                  }
                  break
              default:
                  break
              }
            self.filteredHistory = TransactionHistory(transactionsList: transactionsList)
            self.transactionTableView.backgroundView = self.messageLabel(message: "")
            if self.filteredHistory.transactionsList.count == 0 {
                self.transactionTableView.backgroundView = self.messageLabel(message: "No data found")
            }
            self.transactionTableView.reloadData()
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .default
//    }
    
    @IBAction func menuClicked(_ sender: Any) {
        sideMenuController?.revealMenu()
    }
    
    func messageLabel(message:String) -> UILabel {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        messageLabel.textColor = UIColor(named: "lightFontColor")
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "poppins-regular", size: 16)
        messageLabel.sizeToFit()
        messageLabel.text = message
        return messageLabel
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


extension TransactionsViewController {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredHistory != nil {
            return self.filteredHistory.transactionsList.count
        }
        if transactionHistroy != nil {
           return transactionHistroy.transactionsList.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 10 ||  tableView.tag == 11 {
            return 50
        }
        return 90
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath)
        
        var transactions:TransactionHistory!
        if self.filteredHistory != nil {
            transactions = self.filteredHistory
        } else {
            transactions = self.transactionHistroy
        }
        let nameLbl = cell.viewWithTag(10) as? UILabel
        nameLbl?.text = transactions.name(forIndex: indexPath.row)
        
        let statusLbl = cell.viewWithTag(11) as? UILabel
        if let status = transactions.status(forIndex: indexPath.row) {
            statusLbl?.text = status
            if status.lowercased() == "approved" {
                statusLbl?.textColor = UIColor(named: "successColor")
            } else if status.lowercased() == "declined" {
                statusLbl?.textColor = UIColor(named: "failureColor")
            } else {
                statusLbl?.textColor = .orange
            }
        }
        
        let amountLbl = cell.viewWithTag(100) as? UILabel
        amountLbl?.text = String(format: "$%0.2f", transactions.amount(forIndex: indexPath.row)!)
        
        let dateLbl = cell.viewWithTag(101) as? UILabel
        dateLbl?.text = transactions.transactionDate(forIndex: indexPath.row)
        
        if let cardtype = transactions.cardType(forIndex: indexPath.row) {
            let imageView = cell.viewWithTag(1000) as? UIImageView
            imageView?.image = imageFor(cardType: cardtype)
        }
        
        cell.layer.cornerRadius = 10
        cell.clipsToBounds = false
        cell.layer.masksToBounds = false
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.layer.shadowRadius = 5.0
        cell.layer.shadowOpacity = 0.5
        
        return cell
    }
    

    func imageFor(cardType:String) -> UIImage {
        switch cardType {
        case "Visa":
            return #imageLiteral(resourceName: "visa")
        case "Amex":
            return #imageLiteral(resourceName: "amex")
        case "Master Card":
            return #imageLiteral(resourceName: "mastercard-credit-card")
        case "Discover":
            return #imageLiteral(resourceName: "discover")
        case "JCB":
            return #imageLiteral(resourceName: "jcb")
        case "Diners":
            return #imageLiteral(resourceName: "diners-club")
        default:
            return #imageLiteral(resourceName: "only-cash")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.tag == 10 {
            if let keyValue = filterKeyArr[indexPath.row] as? String {
                self.filterKeyLbl.text = keyValue
                self.filterValueLbl.text = ""
                self.optionListTable.isHidden = true
                self.selectedFilterKey = keyValue
                isDroppedDown = false
                self.selectedFilterValue = nil
                self.filterValueArr.removeAll()
                self.filteredHistory  = nil
                
                if selectedFilterKey == "All" || selectedFilterKey == "Source Application" {
                    DispatchQueue.main.async {
                        self.filterBtn.isHidden = false
                        self.searchImgView.image = UIImage(systemName: "arrowtriangle.down.fill")
                    }
                    
                } else {
                    DispatchQueue.main.async {
                      self.searchImgView.image = UIImage(systemName: "text.magnifyingglass")
                      self.filterBtn.isHidden = true
                    }
                }
                
                guard self.transactionHistroy != nil else {
                    return
                }
                
                switch selectedFilterKey {
                case "All":
                    if let selectedDate = self.dateTimeView.apptDate  {
                        self.showTransactions(for: selectedDate)
                    } else if let currentDate = Date().generateCurrentDateString().convertToDate(with: "MM/dd/yyyy") {
                        self.showTransactions(for: currentDate)
                    }
                    break
                case "Transaction ID":
                    for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                        if let transactionID =  transactionHistroy.transactionId(forIndex: index), !transactionID.isEmpty {
                            filterValueArr.update(with: transactionID)
                        }
                    }
                    break
                case "Customer ID":
                    for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                        if let customerId =  transactionHistroy.customerId(forIndex: index), !customerId.isEmpty {
                            filterValueArr.update(with: customerId)
                        }
                    }
                    break
                case "First Name":
                    for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                        if let firstName =  transactionHistroy.firstName(forIndex: index), !firstName.isEmpty {
                            filterValueArr.update(with: firstName)
                        }
                    }
                    break
                case "Last Name":
                    for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                        if let lastName =  transactionHistroy.lastName(forIndex: index), !lastName.isEmpty {
                            filterValueArr.update(with: lastName)
                        }
                    }
                    break
                case "Email":
                    for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                        if let email =  transactionHistroy.email(forIndex: index), !email.isEmpty {
                            filterValueArr.update(with: email)
                        }
                    }
                    break
                case "Phone":
                    for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                        if let phone =  transactionHistroy.phone(forIndex: index), !phone.isEmpty {
                            filterValueArr.update(with: phone)
                        }
                    }
                    break
                case "Transaction Amount":
                    for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                        if let amount =  transactionHistroy.amount(forIndex: index) {
                            filterValueArr.update(with: String(format: "$%0.2f", amount))
                        }
                    }
                    break
                case "Card Last 4 Digits":
                    for (index , transaction) in transactionHistroy.transactionsList.enumerated() {
                        if let lastFourDigit =  transactionHistroy.lastFourDigit(forIndex: index), !lastFourDigit.isEmpty {
                            filterValueArr.update(with: lastFourDigit)
                        }
                    }
                    break
                case "Source Application":
                    filterValueArr = ["OnepayGO","WOOCOMMERCE","PLE","Jmeter","PS","VT","EXE","paypage","Snap"]

                    break
                
                default:
                    break
                }
            }
        } else if tableView.tag == 11 {
            if let valueType = filterValueArr.reversed()[indexPath.row] as? String {
                self.filterValueLbl.text = valueType
                self.optionListTable.isHidden = true
                isDroppedDown = false
                self.selectedFilterValue = valueType
                self.filterTransactions(for: valueType)
            }
        } else {
            
            let detailVc = self.storyboard?.instantiateViewController(withIdentifier: "transactionDetail") as? TransactionInfoViewController
            var transactions:TransactionHistory!
            if self.filteredHistory != nil {
                transactions = self.filteredHistory
            } else {
                transactions = self.transactionHistroy
            }
            
            detailVc?.transactionId = transactions.transactionId(forIndex: indexPath.row)
            detailVc?.transactionStatus = transactions.status(forIndex: indexPath.row)
            detailVc?.vDelegate = self
            if let cardtype = transactions.cardType(forIndex: indexPath.row) {
                detailVc?.cardBrandImage = imageFor(cardType: cardtype)
            }
            self.navigationController?.pushViewController(detailVc!, animated: true)
        }
       
    }
    
}

extension TransactionsViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let oldText = textField.text, let r = Range(range, in: oldText) else {
            return true
        }
        let updatedText = oldText.replacingCharacters(in: r, with: string)
        return true
    }
}

