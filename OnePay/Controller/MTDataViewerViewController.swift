//
//  MTDataViewerViewController.swift
//  MTSCRADemo-Swift
//
//  Created by Tam Nguyen on 9/16/15.
//  Copyright © 2015 MagTek. All rights reserved.
//

import UIKit
import MediaPlayer

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}
typealias cmdCompBlock = (String?) -> Void


class MTDataViewerViewController: UIViewController,MTSCRAEventDelegate{
    var lib: MTSCRA!;
    var cmdCompletion: cmdCompBlock?
    var devicePaired : Bool?
    let dispatchGroup = DispatchGroup()
    
    var commandResult = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        devicePaired = true
       // setUpUI();
        // Do any additional setup after loading the view.
    }
    
    @objc func turnMSROn() {
        var rs = [UInt8](repeating:0x00 , count: 3)
        //let rsData = HexUtil.getBytesFromHexString(sendCommandSync("5800")!)
        sendCommand(withCallBack: "5800") { (rsDataStr) in
            let rsData = HexUtil.getBytesFromHexString(rsDataStr!)
            rsData?.getBytes(&rs, length: rsData?.count ?? 0)
                   if Int(rs[2]) == 0x00 {
                    self.lib.sendcommand(withLength: "580101")
                    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "MSR Off", style: .plain, target: self, action: #selector(MTDataViewerViewController.turnMSROn))
                   } else if Int(rs[2]) == 0x01 {
                   self.lib.sendcommand(withLength: "580100")
                    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "MSR On", style: .plain, target: self, action: #selector(MTDataViewerViewController.turnMSROn))
                   }
        }
        
    }

    
    @objc func connect()
    {
        if(!self.lib.isDeviceOpened())
        {
            setText(text: "Connecting")
            self.lib.openDevice();
        }
        else
        {
            self.lib.closeDevice();
            
        }
        
        if self.lib.getDeviceType() == MAGTEKAUDIOREADER
        {
            let musicPlayer : MPMusicPlayerController = MPMusicPlayerController.applicationMusicPlayer
            MPVolumeView.setVolume(0.5)
            
        }
        
        
        
    }
    @objc func getSerialNumber()
    {
       // DispatchQueue.main.async {
            self.setText(text: "Device Serial Number: \(self.lib.getDeviceSerial() ?? "")\r")
        //}
    }
    
    private func cardSwipeDidStart(_ instance: AnyObject!) {
        DispatchQueue.main.async
            {
               // self.txtData!.text = ;
                print("Transfer started...")
        }
    }
    
    func cardSwipeDidGetTransError() {
        DispatchQueue.main.async
            {
                print("Transfer error...")
               // self.txtData!.text = ;
        }
        
    }
    override func viewDidAppear(_ animated: Bool) {
        if self.lib != nil
        {
        DispatchQueue.main.async(execute: {
            if self.lib.isDeviceOpened() {
                if self.lib.isDeviceConnected() {
                    
//                    self.btnConnect!.setTitle("Disconnect", for: .normal)
//                    self.btnConnect!.backgroundColor = UIColor(hex:0xcc3333)
                } else {
                    
                    
//                    self.btnConnect!.setTitle("Connect", for: .normal)
//                    self.btnConnect!.backgroundColor = UIColor(hex:0x3465aa)
                }
            } else {
                
                
//                self.btnConnect!.setTitle("Connect", for: .normal)
//
//                self.btnConnect!.backgroundColor = UIColor(hex:0x3465aa)
            }
            
        })
        }
        
    }
    
    public func setText(text:String)
    {
        DispatchQueue.main.async {
            print("\(text)")
            //self.txtData!.text = self.txtData!.text + "\r\(text)"
           // self.scrollTextView(toBottom: self.txtData)
        }
    }
    func onDisplayMessageRequest(_ data: Data!) {
    }
    func onEMVCommandResult(_ data: Data!) {
        
    }
    func onUserSelectionRequest(_ data: Data!) {
        
    }
    func onARQCReceived(_ data: Data!) {
        
    }
    func onTransactionStatus(_ data: Data!) {
        
    }
    func buildCommand(forAudioTLV commandIn: String?) -> String? {
        
        let commandSize = String(format: "%02x", UInt(commandIn?.count ?? 0) / 2)
        let newCommand = "8402\(commandSize)\(commandIn ?? "")"
        
        let fullLength = String(format: "%02x", UInt(newCommand.count) / 2)
        let tlvCommand = "C102\(fullLength)\(newCommand)"
        
        return tlvCommand
        
    }
    
    
    public func onDeviceConnectionDidChange(_ deviceType: UInt, connected: Bool, instance: Any!) {
   
        

        if((instance as! MTSCRA).isDeviceOpened() && self.lib.isDeviceConnected())
        {
            
            if(connected)
            {
                if self.lib.isDeviceConnected() && self.lib.isDeviceOpened()
                {
//                    self.btnConnect?.setTitle("Disconnect", for: .normal)
//                    self.btnConnect?.backgroundColor = UIColor(hex:0xcc3333);
                   
 /*                   self.setText(text: "Getting FW ID...")
                    var fw = ""
                    if self.lib.getDeviceType() == MAGTEKAUDIOREADER {
                        fw = self.sendCommandSync(self.buildCommand(forAudioTLV: "000100"))!

                        DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {

                        }

                        //Thread.sleep(forTimeInterval: 1)
                    } else {
                        fw = self.sendCommandSync("000100")!
                    }
                    self.setText(text:"[Firmware ID]\n\(fw)")

                    self.setText(text:"Getting SN...")
                    var sn = ""
                    if self.lib.getDeviceType() == MAGTEKAUDIOREADER {
                        sn = self.sendCommandSync(self.buildCommand(forAudioTLV: "000103"))!
                        //[NSThread sleepForTimeInterval:1];
                    } else {
                        sn = self.sendCommandSync("000103")!
                    }
                    self.setText(text:"[Device SN]\n\(sn)")
                    
*/
                    let opsQue = OperationQueue()
                    let op1 = Operation()
                    let op2 = Operation()
                    let op3 = Operation()
                    let op4 = Operation()


                    if deviceType == MAGTEKDYNAMAX || deviceType == MAGTEKEDYNAMO || deviceType == MAGTEKTDYNAMO {
                        if let name = (instance as? MTSCRA)?.getConnectedPeripheral().name {
                            self.setText(text:"Connected to \(name)")
                        }


                        if !self.devicePaired! {
                            return
                        }

                        if deviceType == MAGTEKDYNAMAX || deviceType == MAGTEKEDYNAMO || deviceType == MAGTEKTDYNAMO {
                            self.setText(text:"Setting data output to Bluetooth LE...")

                            op1.completionBlock = {
                                //sn = self.sendCommandSync("000103")!
                                self.sendCommand(withCallBack: "480101", completion: { (response) in
                                    self.setText(text: "[Output Result]\r\(response!)")
                                    opsQue.addOperation(op2)

                                })

                                // self.setText(text: "[Device SN]\n\(sn)")
                            }

                            //
                            //                            let bleOutput = self.sendCommandSync("480101")
                            //                           self.setText(text:"[Output Result]\r\(bleOutput)")
                        } else if deviceType == MAGTEKDYNAMAX {
                            op1.completionBlock = {
                                self.sendCommand(withCallBack: "000101", completion: { (response) in
                                    self.setText(text: "[Output Result]\r\(response!)")
                                    opsQue.addOperation(op2)

                                })

                            }

                            //   self.lib.sendcommand(withLength: "000101")
                        }
                    } else {
                        op1.completionBlock = {

                            self.setText(text:"Device Connected...") // @"Connected...";
                            opsQue.addOperation(op2)

                        }
                    }

                    op2.completionBlock = {
                        self.setText(text: "Getting FW ID...")

                        if self.lib.getDeviceType() == MAGTEKAUDIOREADER {
                            self.sendCommand(withCallBack: self.buildCommand(forAudioTLV: "000100"), completion: { (response) in
                                self.setText(text: "[Firmware ID]\n\(response!)")
                                opsQue.addOperation(op3)
                            })
                        }
                        else
                        {
                            self.sendCommand(withCallBack: "000100", completion: { (response) in
                                self.setText(text: "[Firmware ID]\n\(response!)")
                                opsQue.addOperation(op3)

                            })
                        }

                    }

                    op3.completionBlock = {
                        //sn = self.sendCommandSync("000103")!
                        self.setText(text: "Getting SN...")
                        if self.lib.getDeviceType() == MAGTEKAUDIOREADER {
                            self.sendCommand(withCallBack: self.buildCommand(forAudioTLV: "000103"), completion: { (response) in
                                self.setText(text: "[Device SN]\n\(response!)")
                                opsQue.addOperation(op4)

                            })
                        }
                        else
                        {

                            self.sendCommand(withCallBack: "000103", completion: { (response) in

                                self.setText(text: "[Device SN]\n\(response!)")
                                opsQue.addOperation(op4)

                            })
                        }

                        // self.setText(text: "[Device SN]\n\(sn)")
                    }



                    op4.completionBlock = {
                        self.setText(text: "Getting Security Level...")

                        if self.lib.getDeviceType() == MAGTEKAUDIOREADER {
                            self.sendCommand(withCallBack: self.buildCommand(forAudioTLV: "1500"), completion: { (response) in
                                self.setText(text: "[Security Level]\n\(response!)")
                            })
                        }
                        else
                        {
                            self.sendCommand(withCallBack: "1500", completion: { (response) in
                                self.setText(text: "[Security Level]\n\(response!)")
                            })
                        }

                    }


                    opsQue.addOperation(op1)//*/
                    
                    if deviceType == MAGTEKTDYNAMO || deviceType == MAGTEKKDYNAMO
                    {
                        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "MSR On", style: .plain, target: self, action: #selector(self.turnMSROn))
                        self.setText(text: "Setting Date Time...")
                        self.setDateTime()
                    }
                    
                    if deviceType == MAGTEKTDYNAMO
                    {
                        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "MSR On", style: .plain, target: self, action: #selector(self.turnMSROn))
                    }
                    
                    
                }
            }
            else
            {
                self.devicePaired = true
                self.setText(text: "Disconnected")
//                self.btnConnect?.setTitle("Connect", for:UIControl.State())
//                self.btnConnect?.backgroundColor = UIColor(hex:0x3465AA);
            }
        }
        else
        {
            self.devicePaired = true
            self.setText(text: "Disconnected")
//            self.btnConnect?.setTitle("Connect", for:UIControl.State())
//            self.btnConnect?.backgroundColor = UIColor(hex:0x3465AA);
            
            if deviceType == MAGTEKTDYNAMO
            {
                self.navigationItem.leftBarButtonItem = nil
            }
        }
    }

    @objc func clearData()
    {
        if self.lib != nil
        {
        self.lib.clearBuffers();
        }
        print("cleared buffer")
       // self.txtData?.text = "";
        
    }
    
    //Working One
    
    func sendCommand(withCallBack command: String?, completion: @escaping (String?) -> Void)  {
        
        if completion != nil {
            
            cmdCompletion = completion
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lib.sendcommand(withLength: command)
        }

        //}
    }
    
    
    func sendCommandSync(_ command: String?) -> String? {
        var deviceRs = ""
        var counter = 0

       // DispatchQueue.main.async {
            self.sendCommand(withCallBack: command) { data in
                deviceRs = data!
            }
       // }
        
        var loopUntil = Date(timeIntervalSinceNow: 0.2)
        while deviceRs.count == 0 && RunLoop.current.run(mode: .default, before: loopUntil) && counter <= 50 {
            
            counter += 1
            loopUntil = Date(timeIntervalSinceNow: 0.2)
        }
            
        
        return deviceRs
    }
    
    
//    func sendCommand(withCallBack command: String?, completion: @escaping (String?) -> Void) {
//
//        // if completion != nil {
//        cmdCompletion = completion
//        // }
//        self.lib.sendcommand(withLength: command)
//    }
//
//
//    func sendCommandSync(_ command: String?) -> String? {
//        var deviceRs = ""
//        var counter = 0
//        self.sendCommand(withCallBack: command) { (data) in
//            deviceRs = data!
//        }
//
//        var loopUntil = Date(timeIntervalSinceNow: 0.2)
//        while deviceRs.count == 0 && RunLoop.current.run(mode: .default, before: loopUntil) && counter <= 20 {
//
//            counter += 1
//            loopUntil = Date(timeIntervalSinceNow: 0.2)
//        }
//        return deviceRs
//    }
    func onDataReceived(_ cardDataObj: MTCardData!, instance: Any!) {
      
        DispatchQueue.main.async
            {
                let responseStr = String(format:  "Track.Status: %@\n\nTrack1.Status: %@\n\nTrack2.Status: %@\n\nTrack3.Status: %@\n\nEncryption.Status: %@\n\nBattery.Level: %ld\n\nSwipe.Count: %ld\n\nTrack.Masked: %@\n\nTrack1.Masked: %@\n\nTrack2.Masked: %@\n\nTrack3.Masked: %@\n\nTrack1.Encrypted: %@\n\nTrack2.Encrypted: %@\n\nTrack3.Encrypted: %@\n\nCard.PAN: %@\n\nMagnePrint.Encrypted: %@\n\nMagnePrint.Length: %i\n\nMagnePrint.Status: %@\n\nSessionID: %@\n\nCard.IIN: %@\n\nCard.Name: %@\n\nCard.Last4: %@\n\nCard.ExpDate: %@\n\nCard.ExpDateMonth: %@\n\nCard.ExpDateYear: %@\n\nCard.SvcCode: %@\n\nCard.PANLength: %ld\n\nKSN: %@\n\nDevice.SerialNumber: %@\n\nMagTek SN: %@\n\nFirmware Part Number: %@\n\nDevice Model Name: %@\n\nTLV Payload: %@\n\nDeviceCapMSR: %@\n\nOperation.Status: %@\n\nCard.Status: %@\n\nRaw Data: \n\n%@",
                   cardDataObj.trackDecodeStatus,
                                        cardDataObj.track1DecodeStatus,
                                        cardDataObj.track2DecodeStatus,
                                        cardDataObj.track3DecodeStatus,
                                        cardDataObj.encryptionStatus,
                                        cardDataObj.batteryLevel,
                                        cardDataObj.swipeCount,
                                        cardDataObj.maskedTracks,
                                        cardDataObj.maskedTrack1,
                                        cardDataObj.maskedTrack2,
                                        cardDataObj.maskedTrack3,
                                        cardDataObj.encryptedTrack1,
                                        cardDataObj.encryptedTrack2,
                                        cardDataObj.encryptedTrack3,
                                        cardDataObj.cardPAN,
                                        cardDataObj.encryptedMagneprint,
                                        cardDataObj.magnePrintLength,
                                        cardDataObj.magneprintStatus,
                                        cardDataObj.encrypedSessionID,
                                        cardDataObj.cardIIN,
                                        cardDataObj.cardName,
                                        cardDataObj.cardLast4,
                                        cardDataObj.cardExpDate,
                                        cardDataObj.cardExpDateMonth,
                                        cardDataObj.cardExpDateYear,
                                        cardDataObj.cardServiceCode,
                                        cardDataObj.cardPANLength,
                                        cardDataObj.deviceKSN,
                                        cardDataObj.deviceSerialNumber,
                                        cardDataObj.deviceSerialNumberMagTek,
                                        cardDataObj.firmware,
                                        cardDataObj.deviceName,
                                        (instance as! MTSCRA ).getTLVPayload(),
                                        cardDataObj.deviceCaps,
                                        (instance as! MTSCRA ).getOperationStatus(),
                                        cardDataObj.cardStatus,
                                        (instance as! MTSCRA ).getResponseData());
                self.setText(text: responseStr)
                //[(MTSCRA*)instance getTLVPayload]
        }
        
    }
    
    func onDeviceResponse(_ data: Data!) {
        if(cmdCompletion != nil)
        {
            let dataStr = HexUtil.toHex(data)
           // DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            DispatchQueue.main.async {
                self.cmdCompletion!(dataStr)
                self.cmdCompletion = nil
            }
                
           // }

           return;
        }
        
//        NSString* dataString = [self getHexString:data];
//        NSLog(@"%@", dataString);
//
//        commandResult = dataString;
//        [self setText:[NSString stringWithFormat:@"\n[Device Response]\n%@", dataString]];
        
        
        
        let dataString = data.hexadecimalString
        commandResult = dataString
        
        self.setText(text: "\n[Command Result]\n\(dataString)")
        
//        DispatchQueue.main.async
//            {
//                self.txtData?.text = self.txtData!.text + "\n[Transaction Result]\n\(data.hexadecimalString as String)";
//        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        // Dispose of any resources that can be recreated.
    }
    
    func isX() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            if #available(iOS 8, *) {
                print(String(format: "%i", Int(UIScreen.main.nativeBounds.size.height)))
                switch Int(UIScreen.main.nativeBounds.size.height) {
                case 1136:
                    print("iPhone 5 or 5S or 5C")
                case 1334:
                    print("iPhone 6/6S/7/8")
                case 2208:
                    print("iPhone 6+/6S+/7+/8+")
                case 2436, 2688, 1792:
                    return true
                default:
                    print("unknown")
                }
            } else {
                return false
            }
        } else {
            
            print(String(format: "%i", Int(UIScreen.main.nativeBounds.size.height)))
            switch Int(UIScreen.main.nativeBounds.size.height) {
            case 2388, 2732:
                //iPad Pro 11
                return true
            default:
                return false
            }
        }
        return false
        
    }
    func onDeviceError(_ error: Error!) {
        //UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show();

    }
    func deviceNotPaired() {
        self.devicePaired = false
        self.setText(text: "Device is not paired")
        lib.closeDevice()
        displayAlert(title: "Device is not paired/connected", message: "Please press push button for 2 seconds to pair")
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    func setDateTime() {
        
        let date = Date()
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from:date)-2008
        let month = calendar.component(.month, from:date)
        let day = calendar.component(.day, from:date)
        let hour = calendar.component(.hour, from:date)
        let minute = calendar.component(.minute, from:date)
        let second = calendar.component(.second, from:date)
        
        
        let cmd = "030C"
        let  size = "0018"
        let  deviceSn = "00000000000000000000000000000000"
        let strMonth = String(format: "%02lX", month)
        let strDay = String(format: "%02lX", day)
        let strHour = String(format: "%02lX", hour)
        let strMinute = String(format: "%02lX", minute)
        let strSecond = String(format: "%02lX", second)
        // NSString* placeHol = [NSString stringWithFormat:@"%02lX", (long)second];
        let strYear = String(format: "%02lX", year)
        let commandToSend = "\(cmd)\(size)00\(deviceSn)\(strMonth)\(strDay)\(strHour)\(strMinute)\(strSecond)00\(strYear)"
        lib.sendExtendedCommand(commandToSend)
    }
    
    func onDeviceExtendedResponse(_ data: String!) {
        self.setText(text:"\n[Device Extended Response]\n\(data!)" )
    }
    func scrollTextView(toBottom textView: UITextView?) {
        let range = NSRange(location: textView?.text.count ?? 0, length: 0)
        textView?.scrollRangeToVisible(range)
        
        textView?.isScrollEnabled = false
        textView?.isScrollEnabled = true
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}

