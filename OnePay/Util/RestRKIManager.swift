//
//  RestRKIManager.swift
//  MiuraSDK Payment Sample
//
//  Created by Miura Systems on 06/09/2016.
//  Copyright © 2017 Miura Systems Ltd. All rights reserved.


import Foundation
import SwiftyJSON

typealias ServiceResponse = (JSON?, NSError?) -> ()

class RestRkiManager {
    
    static let sharedInstance = RestRkiManager()
    let baseURL = "https://tms.miurasystems.com/rki-host-0.0.2-SNAPSHOT/keyinject/" /*AWS live instance*/
    let className = String(describing: [RestRkiManager.self])
   // let print = PrintDebuggingLog()
    
    func getRandomUser(_ completion: @escaping (JSON) -> ()) {
        
        let route = baseURL
        makeHTTPGetRequest(route) { json, err in
            completion(json! as JSON)
        }
    }
    
    func postRkiInitRequest(_ initData: JSON, completion: @escaping (ServiceResponse)) {
        
        let route = baseURL
        makeHTTPPostRequest(route, body: initData) { (json, error) in
            completion(json, error)
        }
    }
    
    fileprivate func makeHTTPGetRequest(_ path: String, completion: @escaping (ServiceResponse)) {
        
        let request = NSMutableURLRequest(url: URL(string: path)!)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            
            if let jsonData = data {
                do {
                    let json:JSON = try JSON(data: jsonData)
                    print( self.className,  jsonData as AnyObject)
                    
                    completion(json, error as NSError?)
                } catch {
                    print( self.className,  "Request failed!" as AnyObject)
                }
                
            } else {
                completion(nil, error as NSError?)
            }
        }) 
        task.resume()
    }
    
    fileprivate func makeHTTPPostRequest(_ path: String, body: JSON, onCompletion: @escaping ServiceResponse) {
        
        let request = NSMutableURLRequest(url: URL(string: path)!)
        // Set the method to POST
        request.httpMethod = "POST"
        
        do {
            // Set the POST body for the request
            //let jsonBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let  jsonBody = try body.rawData();
            
            request.httpBody = jsonBody
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
                
                guard error == nil else {
                    print( self.className, ("error calling GET", error!) as AnyObject)
                    return
                }
                
                guard data != nil else {
                    print( self.className, "Error: did not receive data" as AnyObject)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print( self.className, "Error: I's not a HTTP URL Resposne" as AnyObject)
                    return
                }
                
                print( self.className,  "Request response code: \(httpResponse.statusCode)"as AnyObject)
                print( self.className,  "Request repsonse status: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)))" as AnyObject)
                
                if let jsonData = data {
                    
                    do {
                        let json:JSON = try JSON(data: jsonData)
                        print( self.className,  "Request successfully sent!" as AnyObject)
                        
                        onCompletion(json, nil)
                        
                    } catch {
                        
                        print(self.className, "Request failed to send" as AnyObject)
                    }
                    
                } else {
                    
                    onCompletion(nil, error as NSError?)
                }
            })
            
            task.resume()
            
        } catch let error {
            
            print(self.className,  error.localizedDescription as AnyObject)
            onCompletion(nil, nil)
        }
    }
    
}
