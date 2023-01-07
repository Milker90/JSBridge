//
//  TestBridgeModule.swift
//  JSBridge
//
//  Created by milker90 on 2023/1/6.
//

import Foundation

class HelloModule: NSObject, BridgeModule {
    func moduleName() -> String {
        return "Hello"
    }
    
    func didReceiveReq(bridge: Bridge, req: BridgeReq) {
        if (req.name == "addTwoNum") {
            let ret = self.addTwoNum(req.params?[0] as! Int, req.params?[1] as! Int)
            bridge.sendSuccessCallbackToJs(req, data: ret)
        }
    }
    
    func addTwoNum(_ num1: Int, _ num2: Int) -> Int {
        return num1 + num2
    }    
}
