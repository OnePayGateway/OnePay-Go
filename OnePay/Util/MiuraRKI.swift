//
//  MiuraRKI.swift
//  MiuraSDK Payment Sample
//
//  Created by Miura Systems on 21/11/2016.
//  Copyright © 2017 Miura Systems Ltd. All rights reserved.


import Foundation
import SwiftyJSON

enum KeyInjectType {
    case pinOnly
    case sredOnly
    case pinAndSred
}

typealias keyInjectCompletionHandler = (_ success: Bool) -> Void

class MiuraRKIManager {
    static let sharedInstance = MiuraRKIManager()
    
    fileprivate var className = String(describing: [MiuraRKIManager.self])
   // fileprivate var print = PrintDebuggingLog()
    fileprivate var miuraPED: MiuraManager!
    
    fileprivate var temporaryCert: String!
    fileprivate var terminalCert: String!
    fileprivate var productionSignCert: String!
    fileprivate var suggestedIKSN: String!
    fileprivate var keyHostIndex: String = "1"
    
    fileprivate var hsmCert: String!
    fileprivate var kbpk: String!
    fileprivate var kbpkSig: String!
    fileprivate var sredTr31: String!
    fileprivate var sredIksn: String!
    fileprivate var pinTr31: String!
    fileprivate var pinIksn: String!
    
    fileprivate var errorResponse: String!
    
    fileprivate var completionBlock: keyInjectCompletionHandler!
    
    fileprivate func p2peReadInitFiles()  {
        
        miuraPED.downloadBinary(withFileName: "prod-sign.crt") { (fileData) in
            
            if let fileData = fileData {
                self.productionSignCert = String(data: fileData, encoding: String.Encoding.ascii)!
                self.miuraPED.downloadBinary(withFileName: "terminal.crt", completion: { (fileData) in
                    
                    if let fileData = fileData {
                        self.terminalCert = String(data: fileData, encoding: String.Encoding.ascii)!
                        self.miuraPED.downloadBinary(withFileName: "temp-keyload.crt", completion: { (fileData) in
                            
                            if let fileData = fileData {
                                self.temporaryCert = String(data: fileData, encoding: String.Encoding.ascii)!
                                self.miuraPED.downloadBinary(withFileName: "suggested-iksn.txt", completion: { (fileData) in
                                    
                                    if let fileData = fileData {
                                        self.suggestedIKSN = String(data: fileData, encoding: String.Encoding.ascii)!
                                        self.requestKeysFromHost()
                                    } else {
                                        print(self.className,("suggested-iksn.txt - failed", fileData) as AnyObject)
                                        self.completionBlock(false)
                                    }
                                })
                            } else {
                                print(self.className,("temp-keyload.crt - failed", fileData) as AnyObject)
                                self.completionBlock(false)
                            }
                        })
                    } else {
                        print(self.className,("terminal.crt - failed", fileData) as AnyObject)
                        self.completionBlock(false)
                    }
                })
            } else {
                print(self.className,( "prod-sign.crt - failed", fileData) as AnyObject)
                self.completionBlock(false)
            }
        }
        
    }
    
    fileprivate func requestKeysFromHost() {
        
        /*We have retrieved the initial certificates from the PED.
         These are now sent to a key injection service.*/
        /**
         print("Key inject")
         print("Prod Sign Cert:")
         print("\(productionSignCert)")
         print()
         print("Terminal Cert")
         print("\(terminalCert)")
         print()
         print("Temp Cert")
         print("\(temporaryCert)")
         print()
         print("Suggested IKSN")
         print("\(suggestedIKSN)")
         */
        
        let rkiDictionary = ["prodSignCert":productionSignCert, "terminalCert":terminalCert, "tempLoadCert":temporaryCert, "suggestedIKSN":suggestedIKSN, "keyHostIndex":keyHostIndex]
        
        let any : Any? = rkiDictionary
        if any != nil {
            
            let rkiJson = JSON(rkiDictionary)
            
            miuraPED.displayText("Connecting\nto key host.".center,  completion: nil)
            
            //print("JSON Object: \(rkiJson.rawString())")
            
            RestRkiManager.sharedInstance.postRkiInitRequest(rkiJson) { (rkiResponse, error) in
                if let jsonData = rkiResponse {
                    /*Recieved a valid response*/
                    self.errorResponse = jsonData["result"].stringValue
                    if self.errorResponse == "Success" {
                        /*Check if there was an error*/
                        /*Data is good, send it over to the PED*/
                        self.hsmCert = jsonData["hsmCert"].stringValue
                        self.kbpk = jsonData["kbpk"].stringValue
                        self.kbpkSig = jsonData["kbpkSig"].stringValue
                        self.sredIksn = jsonData["sredIksn"].stringValue
                        self.sredTr31 = jsonData["sredTr31"].stringValue
                        self.pinIksn = jsonData["pinIksn"].stringValue
                        self.pinTr31 = jsonData["pinTr31"].stringValue
                        
                        print(self.className,"Received result from Host..." as AnyObject)
                        /**
                         print("HSM Cert: \(self.hsmCert)")
                         print("kbpk: \(self.kbpk)")
                         print("kbpkSig: \(self.kbpkSig)")
                         print("SRED IKSN: \(self.sredIksn)")
                         print("SRED TR31: \(self.sredTr31)")
                         print("PIN IKSN: \(self.pinIksn)")
                         print("PIN TR31: \(self.pinTr31)")
                         */
                        
                        self.injectKeysToPED();
                        
                    } else {
                        
                        print(self.className,("Error from RKI Host: \(String(describing: error?.description))" as AnyObject))
                        self.completionBlock(false)
                    }
                    
                } else {
                    
                    print(self.className,("postRkiInitRequest", rkiResponse) as AnyObject)
                }
            }
            
        } else {
            print(self.className,"rkiDictionary empty" as AnyObject)
        }
    }
    
    fileprivate func hexStringToData(_ hexString: String) -> Data {
        
        print(self.className,"Hex String:\(hexString)" as AnyObject)
        
        let chars = Array(hexString)
        
        let numbers = stride(from: 0, to: chars.count, by: 2).map {
            UInt8(String(chars[$0 ..< $0+2]), radix: 16) ?? 0
        }
        return Data(bytes: UnsafePointer<UInt8>(numbers), count: numbers.count)
        
    }
    
    fileprivate func injectKeysToPED() {
        
        let hsmData = self.hsmCert.data(using: String.Encoding.utf8)!
        var hsmCertName: String
        hsmCertName = "HSM.crt"
        
        miuraPED.displayText("Keys Recieved\ninjecting into PED.".center,  completion: nil)
        miuraPED.uploadBinary(hsmData, forName: hsmCertName) { (manager, response) in
            if response.isSuccess() {
                self.miuraPED.uploadBinary(self.hexStringToData(self.kbpk), forName: "kbpk-0001.rsa") { (manager, response) in
                    if response.isSuccess() {
                        self.miuraPED.uploadBinary(self.hexStringToData(self.kbpkSig), forName: "kbpk-0001.rsa.sig") { (manager, response) in
                            if response.isSuccess() {
                                self.miuraPED.uploadBinary(self.sredIksn.data(using: String.Encoding.utf8)!, forName: "dukpt-sred-iksn-0001.txt") { (manager, response) in
                                    if response.isSuccess() {
                                        self.miuraPED.uploadBinary(self.sredTr31.data(using: String.Encoding.utf8)!, forName: "dukpt-sred-0001.tr31") { (manager, response) in
                                            if response.isSuccess() {
                                                self.miuraPED.uploadBinary(self.pinIksn.data(using: String.Encoding.utf8)!, forName: "dukpt-pin-iksn-0001.txt") { (manager, response) in
                                                    if response.isSuccess() {
                                                        self.miuraPED.uploadBinary(self.pinTr31.data(using: String.Encoding.utf8)!, forName: "dukpt-pin-0001.tr31") { (manager, response) in
                                                            if response.isSuccess() {
                                                                self.miuraPED.p2peImport(withCompletion: true) { (result) in
                                                                    if (result == RkiImportStatus.noError ) {
                                                                        
                                                                        print(self.className, "P2PE Result: \(result)" as AnyObject)
                                                                        self.miuraPED.displayText("Keys Injected!".center, completion: nil)
                                                                        self.completionBlock(true)
                                                                        
                                                                    } else {
                                                                        
                                                                        print(self.className, ("P2PE failed:", result) as AnyObject)
                                                                        self.completionBlock(false)
                                                                    }
                                                                }
                                                            } else {
                                                                print(self.className,("dukpt-pin-0001.tr31 failed", self.pinTr31) as AnyObject)
                                                                self.completionBlock(false)
                                                            }
                                                        }
                                                    } else {
                                                        print(self.className,("dukpt-pin-iksn-0001.txt failed", self.pinIksn) as AnyObject)
                                                        self.completionBlock(false)
                                                    }
                                                }
                                            } else {
                                                print(self.className,("dukpt-sred-0001.tr31 failed", self.sredTr31) as AnyObject)
                                                self.completionBlock(false)
                                            }
                                        }
                                    } else {
                                        print(self.className,("dukpt-sred-iksn-0001.txt failed", self.sredIksn) as AnyObject)
                                        self.completionBlock(false)
                                    }
                                }
                            } else {
                                print(self.className,("kbpk sig failed", self.kbpkSig) as AnyObject)
                                self.completionBlock(false)
                            }
                        }
                    } else {
                        print(self.className,("kbpk failed", self.kbpk) as AnyObject)
                        self.completionBlock(false)
                    }
                }
            } else {
                print(self.className,("HSM Failed", self.hsmCert) as AnyObject)
                self.completionBlock(false)
            }
        }
    }
    
    func injectKeys(_ miura: MiuraManager, completion: @escaping ((Bool) -> (Void))) {
        miuraPED = miura
        completionBlock = completion
        
        miuraPED.displayText("Preparing for\nKey injection...".center,  completion: nil)
        
        /*Request to do key injection*/
        miuraPED.p2peInitialise(withCompletion: true) { (result) in
            if result == RkiInitStatus.fileMissing {
                print(self.className,(RkiInitStatus.fileMissing) as AnyObject)
                self.completionBlock(false)
                return
            }
            if result == RkiInitStatus.failedToGenerateRSAKey {
                print(self.className,(RkiInitStatus.failedToGenerateRSAKey) as AnyObject)
                self.completionBlock(false)
                return
            }
            if result == RkiInitStatus.failedToLoadRSAKey {
                print(self.className,(RkiInitStatus.failedToLoadRSAKey) as AnyObject)
                self.completionBlock(false)
                return
            }
            if result == RkiInitStatus.failedToCreateRSACert {
                print(self.className,(RkiInitStatus.failedToCreateRSACert) as AnyObject)
                self.completionBlock(false)
                return
            }
            if result == RkiInitStatus.failedToPrepareOutputFiles {
                print(self.className,(RkiInitStatus.failedToPrepareOutputFiles) as AnyObject)
                self.completionBlock(false)
                return
            }
            if result == RkiInitStatus.internalError {
                print(self.className,(RkiInitStatus.internalError) as AnyObject)
                self.completionBlock(false)
                return
            }
            
        }
        /*Read the 4 files off the PED to start the process*/
        self.p2peReadInitFiles()
    }
}



/*
 var prodSignCert: String = "-----BEGIN CERTIFICATE-----" +
 "MIIEMzCCAxugAwIBAgIJAJlJVkQLKhNdMA0GCSqGSIb3DQEBCwUAMIGlMQswCQYD" +
 "VQQGEwJHQjEYMBYGA1UECBMPQnVja2luZ2hhbXNoaXJlMRUwEwYDVQQHEwxTdG9r" +
 "ZW5jaHVyY2gxGjAYBgNVBAoTEU1pdXJhIFN5c3RlbXMgTHRkMRQwEgYDVQQLEwtF" +
 "bmdpbmVlcmluZzEzMDEGA1UEAxQqTWl1cmFDQS9lbWFpbEFkZHJlc3M9aW5mb0Bt" +
 "aXVyYXN5c3RlbXMuY29tMB4XDTEwMDEwMTAwMDAwMFoXDTI5MTIzMTIzNTk1OVow" +
 "gaYxCzAJBgNVBAYTAkdCMRgwFgYDVQQIEw9CdWNraW5naGFtc2hpcmUxFTATBgNV" +
 "BAcTDFN0b2tlbmNodXJjaDEaMBgGA1UEChMRTWl1cmEgU3lzdGVtcyBMdGQxEzAR" +
 "BgNVBAsTClByb2R1Y3Rpb24xNTAzBgNVBAMULHByb2Qtc2lnbi9lbWFpbEFkZHJl" +
 "c3M9aW5mb0BtaXVyYXN5c3RlbXMuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A" +
 "MIIBCgKCAQEAvLPcztO6hD6PVMjIk6y8fGPwE/EeTAwKNusjrGUHVFoH7jiNYojI" +
 "kMRtoSz5UY4n7EjvMGDf9pNV/e+0H5T0YDr4XlwguJAj9HWrDcHJhE4TSclDWmj7" +
 "+diZTkC0pe8HxentuHmv3b7TkJf/YA3AMoMsyH1Gi1S5aD92TwHC93SrvXue7EhS" +
 "D9cTGL4hdWgxXvdTW7UlHT1SBjwkKDKmItOWKDqI2kR1X55N+5s2tcgSRipgPlXt" +
 "ROTx5yBO1J1SeSEgWBKsjffHJyZH9Y6GTGsZVedKWo37Lsuggo7XoSjNc6Z73d+b" +
 "MgPCba1O7il/lTrYlJqVFNxIjqM/VQLbwwIDAQABo2MwYTAPBgNVHRMBAf8EBTAD" +
 "AQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUGls5lMBvhWdhRRz/k6Q+J7Bi" +
 "ctswHwYDVR0jBBgwFoAUQ/3cJA60U/IvirHc7jXnnuw4ViswDQYJKoZIhvcNAQEL" +
 "BQADggEBADYDSixh4SDHe5RZdH1wqRCz4D8DrEGZr6kLLnZzRgEaCr7wdFzrYEr9" +
 "HYhAqv0EJkOXoEZEjYQH0qME78587dzd8xxmmIUSH0eKUNaNToP/VduAbA3kN9Uf" +
 "Nq8kmcVQ95/zAaPwd3uAWUJUhUFU6MWamwVwVrwRYm/+HJXpn9YJ5IeXjesV6z/w" +
 "W3l5llfeO5eJUa0dzmbdn/b4U1CZWRe9JsibcNsjHRjPYh5NEolIz8AMWaX41Q3Q" +
 "XmlovfRK70/CBVfMLqUxGvaG2WRucZ6XcLlgDWP6ndw874/5xyZiC1sTIG1+RdLu" +
 "9d48jFzomDFVOqYZPWtM/XY0BQue3O4=" +
 "-----END CERTIFICATE-----"
 var terminalCert: String = "-----BEGIN CERTIFICATE-----" +
 "MIIEMzCCAxugAwIBAgIJAJlJVkQLKhNdMA0GCSqGSIb3DQEBCwUAMIGlMQswCQYD" +
 "VQQGEwJHQjEYMBYGA1UECBMPQnVja2luZ2hhbXNoaXJlMRUwEwYDVQQHEwxTdG9r" +
 "ZW5jaHVyY2gxGjAYBgNVBAoTEU1pdXJhIFN5c3RlbXMgTHRkMRQwEgYDVQQLEwtF" +
 "bmdpbmVlcmluZzEzMDEGA1UEAxQqTWl1cmFDQS9lbWFpbEFkZHJlc3M9aW5mb0Bt" +
 "aXVyYXN5c3RlbXMuY29tMB4XDTEwMDEwMTAwMDAwMFoXDTI5MTIzMTIzNTk1OVow" +
 "gaYxCzAJBgNVBAYTAkdCMRgwFgYDVQQIEw9CdWNraW5naGFtc2hpcmUxFTATBgNV" +
 "BAcTDFN0b2tlbmNodXJjaDEaMBgGA1UEChMRTWl1cmEgU3lzdGVtcyBMdGQxEzAR" +
 "BgNVBAsTClByb2R1Y3Rpb24xNTAzBgNVBAMULHByb2Qtc2lnbi9lbWFpbEFkZHJl" +
 "c3M9aW5mb0BtaXVyYXN5c3RlbXMuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A" +
 "MIIBCgKCAQEAvLPcztO6hD6PVMjIk6y8fGPwE/EeTAwKNusjrGUHVFoH7jiNYojI" +
 "kMRtoSz5UY4n7EjvMGDf9pNV/e+0H5T0YDr4XlwguJAj9HWrDcHJhE4TSclDWmj7" +
 "+diZTkC0pe8HxentuHmv3b7TkJf/YA3AMoMsyH1Gi1S5aD92TwHC93SrvXue7EhS" +
 "D9cTGL4hdWgxXvdTW7UlHT1SBjwkKDKmItOWKDqI2kR1X55N+5s2tcgSRipgPlXt" +
 "ROTx5yBO1J1SeSEgWBKsjffHJyZH9Y6GTGsZVedKWo37Lsuggo7XoSjNc6Z73d+b" +
 "MgPCba1O7il/lTrYlJqVFNxIjqM/VQLbwwIDAQABo2MwYTAPBgNVHRMBAf8EBTAD" +
 "AQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUGls5lMBvhWdhRRz/k6Q+J7Bi" +
 "ctswHwYDVR0jBBgwFoAUQ/3cJA60U/IvirHc7jXnnuw4ViswDQYJKoZIhvcNAQEL" +
 "BQADggEBADYDSixh4SDHe5RZdH1wqRCz4D8DrEGZr6kLLnZzRgEaCr7wdFzrYEr9" +
 "HYhAqv0EJkOXoEZEjYQH0qME78587dzd8xxmmIUSH0eKUNaNToP/VduAbA3kN9Uf" +
 "Nq8kmcVQ95/zAaPwd3uAWUJUhUFU6MWamwVwVrwRYm/+HJXpn9YJ5IeXjesV6z/w" +
 "W3l5llfeO5eJUa0dzmbdn/b4U1CZWRe9JsibcNsjHRjPYh5NEolIz8AMWaX41Q3Q" +
 "XmlovfRK70/CBVfMLqUxGvaG2WRucZ6XcLlgDWP6ndw874/5xyZiC1sTIG1+RdLu" +
 "9d48jFzomDFVOqYZPWtM/XY0BQue3O4=" +
 "-----END CERTIFICATE-----"
 
 var tempCert: String = "-----BEGIN CERTIFICATE-----" +
 "MIIEMzCCAxugAwIBAgIJAJlJVkQLKhNdMA0GCSqGSIb3DQEBCwUAMIGlMQswCQYD" +
 "VQQGEwJHQjEYMBYGA1UECBMPQnVja2luZ2hhbXNoaXJlMRUwEwYDVQQHEwxTdG9r" +
 "ZW5jaHVyY2gxGjAYBgNVBAoTEU1pdXJhIFN5c3RlbXMgTHRkMRQwEgYDVQQLEwtF" +
 "bmdpbmVlcmluZzEzMDEGA1UEAxQqTWl1cmFDQS9lbWFpbEFkZHJlc3M9aW5mb0Bt" +
 "aXVyYXN5c3RlbXMuY29tMB4XDTEwMDEwMTAwMDAwMFoXDTI5MTIzMTIzNTk1OVow" +
 "gaYxCzAJBgNVBAYTAkdCMRgwFgYDVQQIEw9CdWNraW5naGFtc2hpcmUxFTATBgNV" +
 "BAcTDFN0b2tlbmNodXJjaDEaMBgGA1UEChMRTWl1cmEgU3lzdGVtcyBMdGQxEzAR" +
 "BgNVBAsTClByb2R1Y3Rpb24xNTAzBgNVBAMULHByb2Qtc2lnbi9lbWFpbEFkZHJl" +
 "c3M9aW5mb0BtaXVyYXN5c3RlbXMuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A" +
 "MIIBCgKCAQEAvLPcztO6hD6PVMjIk6y8fGPwE/EeTAwKNusjrGUHVFoH7jiNYojI" +
 "kMRtoSz5UY4n7EjvMGDf9pNV/e+0H5T0YDr4XlwguJAj9HWrDcHJhE4TSclDWmj7" +
 "+diZTkC0pe8HxentuHmv3b7TkJf/YA3AMoMsyH1Gi1S5aD92TwHC93SrvXue7EhS" +
 "D9cTGL4hdWgxXvdTW7UlHT1SBjwkKDKmItOWKDqI2kR1X55N+5s2tcgSRipgPlXt" +
 "ROTx5yBO1J1SeSEgWBKsjffHJyZH9Y6GTGsZVedKWo37Lsuggo7XoSjNc6Z73d+b" +
 "MgPCba1O7il/lTrYlJqVFNxIjqM/VQLbwwIDAQABo2MwYTAPBgNVHRMBAf8EBTAD" +
 "AQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUGls5lMBvhWdhRRz/k6Q+J7Bi" +
 "ctswHwYDVR0jBBgwFoAUQ/3cJA60U/IvirHc7jXnnuw4ViswDQYJKoZIhvcNAQEL" +
 "BQADggEBADYDSixh4SDHe5RZdH1wqRCz4D8DrEGZr6kLLnZzRgEaCr7wdFzrYEr9" +
 "HYhAqv0EJkOXoEZEjYQH0qME78587dzd8xxmmIUSH0eKUNaNToP/VduAbA3kN9Uf" +
 "Nq8kmcVQ95/zAaPwd3uAWUJUhUFU6MWamwVwVrwRYm/+HJXpn9YJ5IeXjesV6z/w" +
 "W3l5llfeO5eJUa0dzmbdn/b4U1CZWRe9JsibcNsjHRjPYh5NEolIz8AMWaX41Q3Q" +
 "XmlovfRK70/CBVfMLqUxGvaG2WRucZ6XcLlgDWP6ndw874/5xyZiC1sTIG1+RdLu" +
 "9d48jFzomDFVOqYZPWtM/XY0BQue3O4=" +
 "-----END CERTIFICATE-----"
 
 
 var suggestedIKSN: String = "FFFFFF12345678000000"
 
 var tempCert: String = "-----TEMP CERTIFICATE-----"
 var terminalCert: String = "-----Term CERTIFICATE-----"
 var prodSignCert: String = "-----ProdSign CERTIFICATE-----"
 
 var hsmCert: String = "-----BEGIN CERTIFICATE-----" +
 "MIID+DCCAuCgAwIBAgIJAIEmYQ4+AqjZMA0GCSqGSIb3DQEBCwUAMIGvMQswCQYD" +
 "VQQGEwJVSzEYMBYGA1UECBMPQnVja2luZ2hhbXNoaXJlMRUwEwYDVQQHEwxTdG9r" +
 "ZW5jaHVyY2gxGjAYBgNVBAoTEU1pdXJhIFN5c3RlbXMgTHRkMRQwEgYDVQQLEwtF" +
 "bmdpbmVlcmluZzE9MDsGA1UEAxQ0a2V5c2lnbi1tYWluLXVzZXIvZW1haWxBZGRy" +
 "ZXNzPWluZm9AbWl1cmFzeXN0ZW1zLmNvbTAeFw0xMDAxMDEwMDAwMDBaFw0yOTEy" +
 "MzEyMzU5NTlaMGUxFDASBgNVBAMMC0hTTS1QQ0ktUElOMQswCQYDVQQGEwJVUzEL" +
 "MAkGA1UECAwCVFgxDzANBgNVBAcMBkF1c3RpbjETMBEGA1UECgwKVmlydHVDcnlw" +
 "dDENMAsGA1UECwwEVGVzdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB" +
 "AOtXcDtnsdrxO5Mju2J4odB3w1IhHxHTWt7jlq8wyjYEg49+ui2RX6PV3tK3lq/x" +
 "5UH2DJT+keGoiygmogE8oGU4yP9LkJNygS04cPmRSEJ2GQBb1V1UyQjWdRi0m8qV" +
 "9mYO9BZcsauUTm13zdTfWdQYamTqLHHwRzqWzrRDN07Lwue4lk++VCmUbldlf3gd" +
 "AkdNdn8eySIg9Q03f/xV21zrCgJ/7SO/SSaOAhNWBCh0pRmkzm8EHhizeKQfa58n" +
 "O03gSPfdBSulEiMOdRxwFWCx46NcfctfCeRGH2Es2hgoZkisTgiz6rXuNY8EqV3+" +
 "rvf5smNnIEy93c8O6ulANicCAwEAAaNgMF4wDAYDVR0TAQH/BAIwADAOBgNVHQ8B" +
 "Af8EBAMCBsAwHQYDVR0OBBYEFLqtAI21lZXRy0mi8iCYVXlwHFknMB8GA1UdIwQY" +
 "MBaAFKcA/zigH702dNsm/WpWDYAUzPqNMA0GCSqGSIb3DQEBCwUAA4IBAQApsgGd" +
 "o9emTaBUcZu+Xjk+FLf6CDBhdQ2VAKAFhHn8ZlC8AoVz7FJ+HQZuVYM9AaZ88F1m" +
 "Qpr5ymIBMsAyPjrAq4sZ+To42etfC/8ieN/yfJvCa2PKklInrXHeIWx+QJ4I8T33" +
 "UvdJdXpDsvKlhPfX4Vme8LU77kkJUOQeairIKATsgdqekP5lju240W+tlrcvBaUA" +
 "6YUxgiKAwye0mvSfalzEC6zfIGKvFSvginMJkQ7H8IUjGXtrozYNoygu5lfCAzSz" +
 "5kJl+qHv2uivPEBaSkxZez4RncO6LwMaKL1mkTLGdeJOq69sRFjoE8pVatfwbvUf" +
 "h7rgMhRqBKS1ZPCJ"
 
 var kbpk: String = "2F01E59E1D712D3DB0C6A393438524BAF75A9F9EC4A4AA5AB835F2B5ABAC32F7932F8ECA0559510768A4AB681BFA2F9182CFE28D93B4C7E52053A1580B5D9838A5E4DEBC4D75F11FB5410AB214BB4E03119EBB210E3F0814C40DDEB28C5175ECFF452932FE016806F5CD762CD3A7A770057DCB2D6BFC747D289E2BA8E16298478E3CBF3C1BDDBA79CA80B86D0772B77C1C61C387ACC87321B03BD8448EEE0EACBB85BB282CB79850BB68E71A47FF01FAB8D5399CFACC63B2482561FEF3BB8277E3E82E9DCD3E670FB9C7D765115911ABC4BC453E1FEB003CD75E965AEC007EEB247BD79151E81DDC431676D88535F7A8B287BB8C1C728CB2BFFBC66AB49BC3"
 var kbpkSig: String = "401E96AF63835E868929E0B0CC4344CB4DB247D3EB4B4DA29009FA4CF08EA1B62F9A31D79698730E1603C0ECF0EDA1753F00F58CA051540B701BA4959AE1B08BB34F58F9EB82FFF313EDB98934A40D4A81DC540CC0C34E0B57A1D21B6374DD3FF5A2043762D6F7CE6CA0127346FE2C18FB6D3AACA73ACCA49DAFCF620E7D50D7B11CAC6E58453CF00D48CE913CB57DCC90BFE3E24C022091594B7C3361AD386E3242BB393007E4E398349C289A1F2E7DB08E946E1C746C5D16DDDA5C0C87B6C900B617D3E41893CFBACDF35F6892A8F5DC9264AFF16D451C7BBB3C911841E212A7A01498DC3455AA2ABF2E3F59BF9AEDD6BF73064D03DBE4FB604B5134052859"
 var sredTr13: String = "A0088B1TX00E0000FCD02F777536128090FB1711D9777AB2646838A934AAAFB639D085C2CE69265153F5B759"
 var sredIksn: String = "0000020000000e800000"
 var pinTr31: String = "A0088B1TX00E0000DAD755E104BC6C1E104606DB6E016392C7598AD692831CE14969E07E41B57C2771BB6107"
 var pinIksn: String = "0000010000000f000000"
 
 */

