//
//  DevicesListTableViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/8/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit

protocol bleDevicesDelegate {
    func didSelectDevice(periperal:CBPeripheral)
}

class DevicesListTableViewController: UITableViewController,BBDeviceControllerDelegate, CBCentralManagerDelegate, MTSCRAEventDelegate {
    
    var cbManager: CBCentralManager!
    var deviceList:[Any] = []
    var delegate: bleDevicesDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cbManager = CBCentralManager(delegate: self, queue: nil)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    func startScaning() {
        BBDeviceController.shared()?.delegate = self
        BBDeviceController.shared()?.isDebugLogEnabled = true
        BBDeviceController.shared()?.startBTScan(nil, scanTimeout: 120)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       // UIApplication.shared.statusBarUIView?.backgroundColor = UIColor.black

        let barButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action:#selector(cancelClicked))
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       // UIApplication.shared.statusBarUIView?.backgroundColor = UIColor.black
    }
    
    func onBTReturnScanResults(_ devices: [Any]!) {
        deviceList = devices
        self.tableView.reloadData()
    }
    
    @objc func cancelClicked() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if(central.state == .poweredOn) {
            print("central.state is .poweredOn")
            startScaning()
        } else {
            print("central.state is .poweredOff")
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return deviceList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "devicesCell", for: indexPath)
        cell.textLabel?.text = (deviceList[indexPath.row] as! CBPeripheral).name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let periperal = deviceList[indexPath.row] as! CBPeripheral
        self.delegate.didSelectDevice(periperal: periperal)
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
