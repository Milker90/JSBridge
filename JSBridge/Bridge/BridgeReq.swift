//
//  BridgeReq.swift
//  JSBridge
//
//  Created by milker90 on 2023/1/5.
//

import Foundation

class BridgeReq: NSObject {
    var bridgeId: String?
    var reqId: String?
    var moduleName: String
    var name: String
    var params: [Any]?
    
    init(moduleName: String, name: String, params: [Any]?) {
        self.moduleName = moduleName
        self.name = name
        self.params = params
    }
    
    init(_ dict: [String: Any]) {
        self.moduleName = dict["moduleName"] as? String ?? ""
        self.name = dict["name"] as? String ?? ""
        
        if ((dict["bridgeId"]) != nil) {
            self.bridgeId = dict["bridgeId"] as? String
        }
        
        if ((dict["reqId"]) != nil) {
            self.reqId = dict["reqId"] as? String
        }
        
        if ((dict["params"]) != nil) {
            self.params = dict["params"] as? [Any]
        }
                
    }
    
    func toDict() -> [String: Any] {
        let dict = NSMutableDictionary()
        if (bridgeId != nil) {
            dict.setValue(bridgeId, forKey: "bridgeId")
        }
        
        if (reqId != nil) {
            dict.setValue(reqId, forKey: "reqId")
        }
        
        dict.setValue(moduleName, forKey: "moduleName")
        dict.setValue(name, forKey: "name")
        dict.setValue(params, forKey: "params")
        return dict as! [String : Any]
    }
}

class BridgeCallbackReq: BridgeReq {
    var callback: (BridgeRes) -> Void
    
    init(_ dict: [String: Any], callback: @escaping (BridgeRes) -> Void) {
        self.callback = callback
        super.init(dict)
    }
    
    init(moduleName: String, name: String, params: [Any]?, callback: @escaping (BridgeRes) -> Void) {
        self.callback = callback
        super.init(moduleName: moduleName, name: name, params: params)
    }
}
