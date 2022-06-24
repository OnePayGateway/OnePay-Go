//
//  FacilityTableView.swift
//  CERTIFY Vendor
//
//  Created by Palani Krishnan on 2/8/22.
//

import Foundation
import UIKit

class FilterTableView: UITableView {

    var filterKey:Array<Any>?
    var filterValue:Array<Any>?

    func loadFilterKey(list:Array<Any>) {
        self.filterValue?.removeAll()
        self.filterKey = list
        self.tag = 10
        self.addUI()
    }
    
    func loadFilterValue(list:Array<Any>) {
        self.filterKey?.removeAll()
        self.filterValue = list
        self.tag = 11
        self.addUI()
    }
    
    
    func addUI() {
        self.dataSource = self
        self.isHidden = true
        self.layer.cornerRadius = 10
        self.clipsToBounds = false
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 5.0
        self.layer.shadowOpacity = 0.5
    }
}
    
extension FilterTableView: UITableViewDataSource {
        func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if tableView.tag == 10 {
                return filterKey?.count ?? 0
            } else if tableView.tag == 11 {
                return filterValue?.count ?? 0
            }
            return 0
        }

        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 50
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell", for: indexPath)
            if tableView.tag == 10, let keyName = filterKey?[indexPath.row] as? String {
                cell.textLabel?.text = keyName
            } else if tableView.tag == 11, let valueType = filterValue?[indexPath.row] as? String {
                cell.textLabel?.text = valueType
            }
            cell.textLabel?.font = UIFont(name: "poppins-regular", size: 14)
            return cell
        }
}
