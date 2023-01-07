//
//  BridgeRes.swift
//  JSBridge
//
//  Created by milker90 on 2023/1/5.
//

import Foundation

enum BridgeResCode: Int {
    // req success code
    case success = 200
    // req failed
    case reqError = 400
}

class BridgeRes: NSObject {
    var bridgeId: String
    var req: BridgeReq
    var data: Any?
    var code: BridgeResCode?
    var msg: String?
    
    init(bridgeId: String, req: BridgeReq, failedMsg: String, data: Any?, code: BridgeResCode = .reqError) {
        self.code = code
        self.msg = failedMsg
        self.data = data
        self.req = req
        self.bridgeId = bridgeId
    }
    
    init(bridgeId: String, req: BridgeReq, successData: Any?) {
        self.code = .success
        self.data = successData
        self.req = req
        self.bridgeId = bridgeId
    }
    
    init(_ dict: [String: Any], _ req: BridgeReq) {
        self.bridgeId = dict["bridgeId"] as? String ?? ""
        self.req = req

        if ((dict["data"]) != nil) {
            self.data = dict["data"]
        }
        
        self.code = BridgeResCode(rawValue: dict["code"] as! Int)
        
        if ((dict["msg"]) != nil) {
            self.msg = dict["msg"] as? String
        }
    }
    
    init(_ dict: [String: Any]) {
        self.bridgeId = dict["bridgeId"] as? String ?? ""
        self.req = BridgeReq(dict["req"] as! [String : Any])

        if ((dict["data"]) != nil) {
            self.data = dict["data"]
        }
        
        self.code = BridgeResCode(rawValue: dict["code"] as! Int)
        
        if ((dict["msg"]) != nil) {
            self.msg = dict["msg"] as? String
        }
    }
    
    func toDict() -> [String: Any] {
        let dict = NSMutableDictionary()
        dict.setValue(bridgeId, forKey: "bridgeId")
        dict.setValue(req.toDict(), forKey: "req")

        if (data != nil) {
            dict.setValue(data, forKey: "data")
        }
        
        if (code != nil) {
            dict.setValue(code?.rawValue, forKey: "code")
        }
        
        if (msg != nil) {
            dict.setValue(msg, forKey: "msg")
        }
        
        return dict as! [String : Any]
    }
}
