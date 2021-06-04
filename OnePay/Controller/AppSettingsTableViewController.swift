//
//  AppSettingsTableViewController.swift
//  OnePay
//
//  Created by Palani Krishnan on 7/4/19.
//  Copyright © 2019 Certify Global. All rights reserved.
//

import UIKit
import CoreLocation

protocol settingDelegate {
    func deviceSelected()
}

class AppSettingsTableViewController: UITableViewController, MTSCRAEventDelegate, BBDeviceControllerDelegate, BLEScanListEvent, UIPopoverPresentationControllerDelegate, bleDevicesDelegate,CBCentralManagerDelegate, CLLocationManagerDelegate {

    var cbManager: CBCentralManager!
    var locationManager: CLLocationManager!
    typealias commandCompletion = (String?) -> Void
        var queueCompletion: commandCompletion?
    var devicePaired = true
    let imageView = UIImageView()
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var menuBtn: UIButton!
    var selectedPaymentDevice = -1
    var selectedZone = 0
    var lib: MTSCRA!
    var cameFromCheckOut = false
    var settDelegate: settingDelegate!
    var batteryStatus: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        cbManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey:true])
        locationManager = CLLocationManager()
        locationManager.delegate = self
       // self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 105)
        imageView.image = UIImage.init(named: "CheckoutBg")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        topView.addSubview(imageView)
        
        if let zone = Session.shared.apiZone() {
            selectedZone = zone
        }
        
        self.lib = MTSCRA();
        self.lib.delegate = self;
        //self.lib.listen(forEvents: UInt32(TRANS_EVENT_ERROR))
       // self.lib.setDeviceType(UInt32(MAGTEKEDYNAMO))
        self.lib.setConnectionType(UInt(UInt32(BLE_EMV)))
        checkIfAnyDeviceConnected()
        
    }

    @objc func resetDevice()
    {
        //self.lib.sendcommand(withLength: "0200");
        //020100
        self.lib.sendcommand(withLength: "020100");
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(self.cameFromCheckOut) {
           self.menuBtn.setImage(UIImage(named: "ArrowDOWN"), for: .normal)
        }
    }
    
    @IBAction func locationToggleBtnClicked(_ sender: Any) {
        
        print("location")
        let switchBtn = sender as! UISwitch
    
           var title = "Enable Location Services"
           let  msg = "This app serves you better when you have enabled location services"
            
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                break
            case .restricted:
                break
            case .denied:
                break
            case .authorizedAlways:
                title = "Disable Location Services"
                break
            case .authorizedWhenInUse:
                title = "Disable Location Services"
                break
            @unknown default:
                break
            }
            
           showAlertToGoToDeviceSettings(title: title, msg: msg, switchBtn: switchBtn)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.tableView.reloadData()
    }
    
    @IBAction func bluetoothToggleBtnClicked(_ sender: Any) {
        print("bluetooth")
        let switchBtn = sender as! UISwitch
        
        var title = "Enable Bluetooth Services"
        let  msg = "This app requires bluetooth services to connect with credit card reader"
        
        if(cbManager.state == .poweredOn) {
              title = "Disable Bluetooth Services"
        }
        showAlertToGoToDeviceSettings(title: title, msg: msg, switchBtn: switchBtn)
    }
    
    
    func showAlertToGoToDeviceSettings(title:String, msg:String, switchBtn:UISwitch?) {
        let alertControler = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            
            if let url = URL(string: UIApplication.openSettingsURLString)
            {
                if(switchBtn != nil) {
                    switchBtn?.isOn = !switchBtn!.isOn
                }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let noAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            if(switchBtn != nil) {
                switchBtn?.isOn = !switchBtn!.isOn
            }
        }
        alertControler.addAction(yesAction)
        alertControler.addAction(noAction)
        alertControler.preferredAction = yesAction
        self.present(alertControler, animated: true, completion: nil)
    }
    
    func checkIfAnyDeviceConnected() {
        if(PaymentSettings.shared.paymentDeviceId() == 3) {
            print(BBDeviceController.shared()?.getState() as Any)
            print(BBDeviceController.shared()?.getConnectionMode() as Any)
            if BBDeviceController.shared()?.getConnectionMode() != BBDeviceConnectionMode.bluetooth {
                PaymentSettings.shared.setPaymentDevice(id: -1)
                self.tableView.reloadData()
            }
        } else {
            if !self.lib.isDeviceOpened() {
                PaymentSettings.shared.setPaymentDevice(id: -1)
                self.tableView.reloadData()
            }
        }
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any])
    {
        print("willrestorestate:\(dict)")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if(central.state == .poweredOn) {
            print("central.state is .poweredOn")
        } else if(central.state == .resetting) {
            print("central.state is .resetting")
        }else {
            print("central.state is .poweredOff")
            PaymentSettings.shared.setPaymentDevice(id: -1)
        }
        self.tableView.reloadData()
    }
    
    func logOutWith(msg:String) {
        
        let alertControler = UIAlertController(title: "Are you sure to logout?", message: msg, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
          //  UIApplication.shared.statusBarUIView?.backgroundColor = UIColor.white
            Session.shared.setApi(Zone: self.selectedZone)
            Session.shared.logOut()
            PaymentSettings.shared.removeAll()
            let loginVc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController()
            self.view.window?.rootViewController = loginVc
        }
        let noAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        alertControler.addAction(yesAction)
        alertControler.addAction(noAction)
        alertControler.preferredAction = noAction
        self.present(alertControler, animated: true, completion: nil)
        
    }
    
    
    func AlertWithConnectionState() {
        
        var title:String!
        if(PaymentSettings.shared.paymentDeviceId() == 3) {
            title = "Connected to BBPOS"
        } else {
            switch PaymentSettings.shared.paymentDeviceId() {
            case 0:
                title = "Connected to EDYNAMO"
            case 1:
                title = "Connected to TDYNAMO"
            case 2:
                title = "Connected to KDYNAMO"
            default:
                title = "Unkown Device"
            }
        }
        
        let alertControler = UIAlertController(title: title, message: "", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Continue", style: .default) { (action) in
            self.settDelegate.deviceSelected()
            self.dismiss(animated: true, completion: nil)
        }
        alertControler.addAction(yesAction)
        self.present(alertControler, animated: true, completion: nil)
    }
    
    
    @IBAction func menuClicked(_ sender: Any) {
        if(self.cameFromCheckOut) {
            self.dismiss(animated: true, completion: nil)
        } else {
            sideMenuController?.revealMenu()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
//        else if section == 1 {
//            return 4
//        }
        else if section == 1 {
            return PaymentSettings.shared.activeTerminalIds()!.count
        } else if(section == 2) {
            return 4
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let imageView = cell.viewWithTag(10) as? UIImageView

        if indexPath.section == 0, indexPath.row == 0 {
            let switchBtn = cell.viewWithTag(10) as? UISwitch
            if CLLocationManager.locationServicesEnabled() {
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    switchBtn?.setOn(false, animated: true)
                case .authorizedAlways, .authorizedWhenInUse:
                    switchBtn?.setOn(true, animated: true)
                @unknown default:
                    switchBtn?.setOn(false, animated: true)
                }
            } else {
                switchBtn?.setOn(false, animated: true)
                print("Location services are not enabled")
            }
            
        } else if indexPath.section == 0, indexPath.row == 1 {
            let switchBtn = cell.viewWithTag(11) as? UISwitch
            if(cbManager.state == .poweredOn) {
                switchBtn?.setOn(true, animated: true)
            } else {
                switchBtn?.setOn(false, animated: true)
            }
        }
//        else if indexPath.section == 1, PaymentSettings.shared.paymentDeviceId() == indexPath.row {
//            imageView?.image = UIImage(named: "check.png")
//            if(indexPath.row == 3) {
//                let batteryLbl = cell.viewWithTag(20) as? UILabel
//                batteryLbl?.text = batteryStatus
//            }
//
//        }
        else if indexPath.section == 1 {
            let terminalIdLbl = cell.viewWithTag(100) as? UILabel
            terminalIdLbl?.text = (PaymentSettings.shared.activeTerminalNames() != nil) ?  PaymentSettings.shared.activeTerminalNames()![indexPath.row] : PaymentSettings.shared.activeTerminalIds()![indexPath.row]
            if(PaymentSettings.shared.selectedTerminalId() == PaymentSettings.shared.activeTerminalIds()![indexPath.row]) {
                imageView?.image = UIImage(named: "check.png")
            } else {
                imageView?.image = nil
            }
        } else if indexPath.section == 2 {
            if(indexPath.row == Session.shared.apiZone()) {
                imageView?.image = UIImage(named: "check.png")
            } else {
                imageView?.image = nil
            }
        }
//        else if indexPath.section == 0, indexPath.row == 2, paymentOptionsSelected == true {
//            let imageView = cell.viewWithTag(10) as? UIImageView
//            imageView?.image = UIImage(named: "uparrow.png")
//        } else if indexPath.section == 0, indexPath.row == 2, paymentOptionsSelected == false {
//            let imageView = cell.viewWithTag(10) as? UIImageView
//            imageView?.image = UIImage(named: "downarrow.png")
//        }
        else {
            imageView?.image = nil
        }
        
        if indexPath.section == 4 {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                cell.textLabel?.text = "OnePay Go Version \(version)"
            }
        }
    }
   
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        if(indexPath.section == 1) {
//                selectedPaymentDevice = indexPath.row
//                triggerPaymentDevice()
//                self.tableView.reloadData()
//        } else
        if indexPath.section == 1 {
            PaymentSettings.shared.setSelectedTerminal(Id: PaymentSettings.shared.activeTerminalIds()![indexPath.row])
            PaymentSettings.shared.setSelectedTerminal(Type: PaymentSettings.shared.activeTerminalTypes()![indexPath.row])
            self.tableView.reloadData()
        } else if indexPath.section == 2 {
            selectedZone = indexPath.row
            logOutWith(msg: "API Zone will get changed")
        }
        else if(indexPath.section == 3 && indexPath.row == 0) {
            logOutWith(msg: "")
        }
    }

    
    func triggerPaymentDevice() {
        
        if(cbManager.state == .poweredOn || selectedPaymentDevice == 2) {
            self.disconnect()
            self.disconnectBbPos()
            self.lib.clearBuffers();
            self.lib.closeDevice();
            if(selectedPaymentDevice == 0) {
                devicePaired = true
                self.lib.setDeviceType(UInt32(MAGTEKEDYNAMO))
                self.scanForMagtekBLE()
            } else if(selectedPaymentDevice == 1) {
                devicePaired = true
                self.lib.setDeviceType(UInt32(MAGTEKTDYNAMO))
                self.scanForMagtekBLE()
            } else if(selectedPaymentDevice == 2) {
                self.lib.setDeviceType(UInt32(MAGTEKKDYNAMO));
                self.lib.setDeviceProtocolString("com.magtek.idynamo")
                self.connect()
            } else {
                self.scanForBbPosBLE()
            }
        } else {
            let title = "Enable Bluetooth Services"
            let  msg = "This app requires bluetooth services to connect with credit card reader"
            showAlertToGoToDeviceSettings(title: title, msg: msg, switchBtn: nil)
        }
    }
    
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let y = 80 - (scrollView.contentOffset.y + 80)
//        let height = min(max(y, 80), 400)
//        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AppSettingsTableViewController {
    
    func didSelectBLEReader(_ per: CBPeripheral) {
        self.lib.delegate = self;
        self.lib.setAddress(per.identifier.uuidString);
        self.lib.openDevice();
        //self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func didSelectDevice(periperal:CBPeripheral) {
        BBDeviceController.shared()?.delegate = self
        BBDeviceController.shared()?.connectBT(periperal)
        BBDeviceController.shared()?.stopBTScan()
        self.batteryStatus = ""
        self.dismiss(animated: true, completion: nil)
    }
    
    func onPowerDown() {
        self.batteryStatus = "power down"
    }
    
    func onBatteryLow(_ batteryStatus: BBDeviceBatteryStatus) {
        if(batteryStatus == .low) {
            self.batteryStatus = "low power"
        } else {
            self.batteryStatus = "very low power"
        }
    }
    
    @objc func scanForMagtekBLE()
    {
        let list = BLEScannerList(style: .plain, lib: lib);
        list.delegate = self;
        
        let nav = UINavigationController(rootViewController: list)
        nav.navigationBar.isTranslucent = false
        nav.modalPresentationStyle = UIModalPresentationStyle.popover
        let popover = nav.popoverPresentationController
        list.preferredContentSize = CGSize(width: 300, height: 300)
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: (UIScreen.main.bounds.width)/2, y: 100, width: 0, height: 0)
        self.present(nav, animated: true, completion: nil)
    }
    
    
    @objc func connect()
    {
        if(!self.lib.isDeviceOpened())
        {
            self.lib.openDevice();
        }
    }
    
    @objc func disconnect()
    {
        self.clearData()
        self.lib.closeDevice();
    }
    
    
    func cardSwipeDidStart(_ instance: AnyObject!) {
        DispatchQueue.main.async
            {
              //  self.txtData!.text = "Transfer started...";
        }
    }
    
    func cardSwipeDidGetTransError() {
        DispatchQueue.main.async
            {
              //  self.txtData!.text = "Transfer error...";
        }
        
    }
    
    func bleReaderStateUpdated(_ state: MTSCRABLEState) {
        if state == 0 {
            lib.openDevice()
        }
    }
    
    func sendCommand(withCallBack command: String?, completion: @escaping (String?) -> Void)  {
        if completion != nil {
            queueCompletion = completion
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lib.sendcommand(withLength: command)
        }
    }
    
    func onDeviceConnectionDidChange(_ deviceType: UInt, connected: Bool, instance: Any?) {
        DispatchQueue.main.async
            {
                if((instance as! MTSCRA).isDeviceOpened() && self.lib.isDeviceConnected())
                {
                    if(connected)
                    {
                       let delay = 1.0;
                     DispatchQueue.main.asyncAfter(deadline: .now() + delay) {

                    if(self.lib.isDeviceConnected() && self.lib .isDeviceOpened())
                    {
                        PaymentSettings.shared.setPaymentDevice(id: self.selectedPaymentDevice)
                        self.tableView.reloadData()
                        if(self.cameFromCheckOut) {
                            self.AlertWithConnectionState()
                        }
                        
                    }
                    else
                    {
                        self.devicePaired = true
                        PaymentSettings.shared.setPaymentDevice(id: 0)
                        self.tableView.reloadData()
                    }
                  }
                        
                }
                else
                {
                    self.devicePaired = true
                    PaymentSettings.shared.setPaymentDevice(id: 0)
                    self.tableView.reloadData()
                }
        }
      }
    }
    
    func clearData()
    {
        self.lib.clearBuffers();
    }
    
    func onDataReceived(_ cardDataObj: MTCardData!, instance: Any?) {
        
    }

    
    func onDeviceResponse(_ data: Data!) {
    }
    
    
    //bbbos methods
    
    
    func scanForBbPosBLE() {
        
        let devicesListVc = self.storyboard?.instantiateViewController(withIdentifier: "devicesListVc") as! DevicesListTableViewController
        devicesListVc.delegate = self
        
        let nav = UINavigationController(rootViewController: devicesListVc)
        nav.navigationBar.isTranslucent = false
        nav.modalPresentationStyle = UIModalPresentationStyle.popover
        let popover = nav.popoverPresentationController
        devicesListVc.preferredContentSize = CGSize(width: 300, height: 300)
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: (UIScreen.main.bounds.width)/2, y: 100, width: 0, height: 0)
        self.present(nav, animated: true, completion: nil)
        
    }
    
    func disconnectBbPos() {
        BBDeviceController.shared()?.disconnectBT()
        BBDeviceController.shared()?.release()
        BBDeviceController.shared()?.delegate = nil
    }
    
    func onBTConnected(_ connectedDevice: NSObject!) {
        print(connectedDevice as Any)
        PaymentSettings.shared.setPaymentDevice(id: selectedPaymentDevice)
        self.tableView.reloadData()
        if(self.cameFromCheckOut) {
            AlertWithConnectionState()
        }
    }

    func onBTDisconnected() {
        PaymentSettings.shared.setPaymentDevice(id: 0)
        self.tableView.reloadData()
    }

    func onWaiting(forCard checkCardMode: BBDeviceCheckCardMode) {
        print(checkCardMode)
    }
    
    func onRequest(_ displayMessage: BBDeviceDisplayText) {
        print(displayMessage)
    }
    
    func onReturn(_ result: BBDeviceCheckCardResult, cardData: [AnyHashable : Any]!) {
        print(cardData)
    }
    
    
    /*
     - (void) cardSwipeDidStart:(id)instance;
     - (void) cardSwipeDidGetTransError;
     - (void) bleReaderConnected:(CBPeripheral*)peripheral;
     - (void) bleReaderDidDiscoverPeripheral;
     - (void) bleReaderStateUpdated:(MTSCRABLEState)state;
     - (void) onDeviceResponse:(NSData*)data;
     - (void) onDeviceError:(NSError*)error;
     //EMV delegate
     - (void) OnTransactionStatus:(NSData*)data;
     - (void) OnDisplayMessageRequest:(NSData*)data;
     - (void) OnUserSelectionRequest:(NSData*)data;
     - (void) OnARQCReceived:(NSData*)data;
     - (void) OnTransactionResult:(NSData*)data;
     - (void) OnEMVCommandResult:(NSData*)data;
     - (void) onDeviceExtendedResponse:(NSString*)data;
     - (void) deviceNotPaired;
     */
    
    //EMV delegate
    
    func deviceNotPaired() {
        print("deviceNotPaired")
        devicePaired = false
        displayAlert(title: "Device is not paired/connected", message: "Please press push button for 2 seconds to pair")
    }
    
    
}


