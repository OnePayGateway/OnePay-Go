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

class AppSettingsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, CBCentralManagerDelegate, CLLocationManagerDelegate {

    var cbManager: CBCentralManager!
    var locationManager: CLLocationManager!
    
    let imageView = UIImageView()
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var menuBtn: UIButton!
    var cameFromCheckOut = false
    var settDelegate: settingDelegate!

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
        }
        self.tableView.reloadData()
    }
    
    func logOutWith(msg:String) {
        
        let alertControler = UIAlertController(title: "Are you sure to logout?", message: msg, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
          //  UIApplication.shared.statusBarUIView?.backgroundColor = UIColor.white
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
    
    
    @IBAction func menuClicked(_ sender: Any) {
        if(self.cameFromCheckOut) {
            self.dismiss(animated: true, completion: nil)
        } else {
            sideMenuController?.revealMenu()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0  || section == 1 {
            return 2
        } else if section == 2 {
            return PaymentSettings.shared.activeTerminalIds()!.count
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
        else if indexPath.section == 1, PaymentSettings.shared.paymentDeviceId() == indexPath.row {
            imageView?.image = UIImage(named: "check.png")
        } else if indexPath.section == 2 {
            let terminalIdLbl = cell.viewWithTag(100) as? UILabel
            terminalIdLbl?.text = (PaymentSettings.shared.activeTerminalNames() != nil) ?  PaymentSettings.shared.activeTerminalNames()![indexPath.row] : PaymentSettings.shared.activeTerminalIds()![indexPath.row]
            if(PaymentSettings.shared.selectedTerminalId() == PaymentSettings.shared.activeTerminalIds()![indexPath.row]) {
                imageView?.image = UIImage(named: "check.png")
            } else {
                imageView?.image = nil
            }
        } else {
            imageView?.image = nil
        }
        
        if indexPath.section == 3 {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                cell.textLabel?.text = "OnePay Go Version \(version)"
            }
        }
    }
   
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if(indexPath.section == 1) {
            PaymentSettings.shared.setPaymentDevice(id: indexPath.row)
           // triggerPaymentDevice()
            self.tableView.reloadData()
        } else if indexPath.section == 2 {
            PaymentSettings.shared.setSelectedTerminal(Id: PaymentSettings.shared.activeTerminalIds()![indexPath.row])
            PaymentSettings.shared.setSelectedTerminal(Type: PaymentSettings.shared.activeTerminalTypes()![indexPath.row])
            PaymentSettings.shared.setSelectedTerminal(Name: PaymentSettings.shared.activeTerminalNames()![indexPath.row])
            self.tableView.reloadData()
        } else if(indexPath.section == 3 && indexPath.row == 0) {
            logOutWith(msg: "")
        }
    }

}


