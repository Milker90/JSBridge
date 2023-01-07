//
//  Bridge.swift
//  JSBridge
//
//  Created by milker90 on 2023/1/5.
//

import Foundation
import JavaScriptCore

enum BridgeError: Error {
    case init_error
}

class Bridge: NSObject {
    private(set) var id: String
    private var reqNum: Int = 0
    
    private var jsBridgeValue: String?
    private var ctx: JSContext
    private var jsBridge: JSValue?
    private var moduleMap: [String: BridgeModule] = [:]
    private var callbackReqMap: [String: BridgeCallbackReq] = [:]

    private var moduleLock: NSLock
    private var reqLock: NSLock
    
    private let setJsBridgeIdFucName = "setBridgeId"
    private let receiveNativeReqFucName = "receiveNativeReq"
    private let receiveNativeCallbackReqFucName = "receiveNativeCallbackReq"
    private let sendReqToNativeFucName = "sendReqToNative"
    private let sendCallbackReqToNativeFucName = "sendCallbackReqToNative"

    deinit {
        moduleMap.removeAll()
        callbackReqMap.removeAll()
        jsBridge?.deleteProperty(sendReqToNativeFucName)
        jsBridge?.deleteProperty(sendCallbackReqToNativeFucName)
        jsBridge = nil
    }
    
    init(id: String = "", ctx: JSContext = JSContext(), jsBridgeValue: String = "") throws {
        self.reqLock = NSLock()
        self.moduleLock = NSLock()
        self.ctx = ctx
        self.id = id
        self.jsBridgeValue = jsBridgeValue
        super.init()
        
        try self.loadJs()
        try self.bridgeJsCtx()
    }
    
    convenience init(_ ctx: JSContext = JSContext()) throws {
        try self.init(id: "", ctx: ctx)
    }
    
    func setBridgeId(bridgeId: String) {
        jsBridge?.invokeMethod(setJsBridgeIdFucName, withArguments: [bridgeId])
        self.id = bridgeId
    }
    
    func addModules(_ modules: [BridgeModule]) {
        for module in modules {
            addModule(module)
        }
    }
    
    func addModule(_ module: BridgeModule) {
        moduleLock.lock()
        let moduleName = module.moduleName();
        guard moduleMap[moduleName] == nil else {
            moduleLock.unlock()
            return
        }
        
        moduleMap[moduleName] = module
        moduleLock.unlock()
    }
    
    func removeModule(_ moduleName: String) {
        moduleLock.lock()
        guard moduleMap[moduleName] == nil else {
            moduleLock.unlock()
            return
        }
        
        moduleMap[moduleName] = nil
        moduleLock.unlock()
    }
    
    func sendReqToJs(_ req: BridgeReq) {
        req.bridgeId = id
        
        reqLock.lock()
        reqNum = reqNum + 1
        req.reqId = "N_\(reqNum)"
        
        if let callbackReq = req as? BridgeCallbackReq {
            callbackReqMap[req.reqId!] = callbackReq
        }
        
        reqLock.unlock()
        jsBridge?.invokeMethod(receiveNativeReqFucName, withArguments: [req.toDict()])
    }
    
    func sendSuccessCallbackToJs(_ req: BridgeReq, data: Any?) {
        let res = BridgeRes(bridgeId: id, req: req, successData: data)
        jsBridge?.invokeMethod(receiveNativeCallbackReqFucName, withArguments: [res.toDict()])
    }
    
    func sendFailedCallbackToJs(_ req: BridgeReq, failedMsg: String, data: Any?) {
        let res = BridgeRes(bridgeId: id, req: req, failedMsg: failedMsg, data: nil)
        jsBridge?.invokeMethod(receiveNativeCallbackReqFucName, withArguments: [res.toDict()])
    }
    
    func callJsGlobalFunc(_ funcName: String) {
        guard let funcImp = ctx.objectForKeyedSubscript(funcName) else {
            return
        }
        
        funcImp.call(withArguments: []);
    }
    
    func checkBridgeIsOK() -> Bool {
        guard self.jsBridge != nil else {
            return false;
        }
        
        guard self.jsBridge?.hasProperty(receiveNativeReqFucName) == true else {
            return false
        }
        
        guard self.jsBridge?.hasProperty(sendReqToNativeFucName) == true else {
            return false
        }
        
        guard self.jsBridge?.hasProperty(sendCallbackReqToNativeFucName) == true else {
            return false
        }
        
        return true;
    }
    
    private func loadJs() throws {
        if ((jsBridgeValue == nil) || jsBridgeValue?.count == 0) {
            guard let jsPath = Bundle.main.path(forResource: "bridge", ofType: "js") else {
                throw BridgeError.init_error
            }
            
            let jsStr = try String(contentsOfFile: jsPath, encoding: .utf8)
            ctx.evaluateScript(jsStr)
        } else {
            ctx.evaluateScript(jsBridgeValue)
        }
    }
    
    private func bridgeJsCtx() throws {
        guard let jsBridgeObj = ctx.globalObject.forProperty("bridge") else {
            throw BridgeError.init_error
        }
        self.jsBridge = jsBridgeObj
        
        // 为jsbridge注入一个swift方法，使得js可以响应swift的请求
        let sendCallbackReqToNative :@convention(block) (Dictionary<String, Any>) -> Void = { [weak self] callbackResDict in
            if let strongSelf = self {
                guard let bridgeId = callbackResDict["bridgeId"] as? String,
                      let req = callbackResDict["req"] as? [String: Any],
                      let reqId = req["reqId"] as? String,
                      callbackResDict["code"] as? Int != nil,
                      bridgeId == strongSelf.id else {
                    print("callback res data is invalid: \(callbackResDict)")
                    return
                }
                
                guard let callbackReq = strongSelf.callbackReqMap[reqId] else {
                    print("not found callback req: \(callbackResDict)")
                    return
                }
                
                let res = BridgeRes(callbackResDict)
                callbackReq.callback(res)
                
                strongSelf.reqLock.lock()
                strongSelf.callbackReqMap[reqId] = nil
                strongSelf.reqLock.unlock()
            }
        }
        jsBridgeObj.setValue(sendCallbackReqToNative, forProperty: sendCallbackReqToNativeFucName)
                
        // 为jsbridge注入一个swift方法，使得js可以请求swift
        let sendReqToNative: @convention(block) (Dictionary<String, Any>) -> Void = { [weak self] reqDict in
            if let strongSelf = self {
                let req = BridgeReq(reqDict)
                
                guard let bridgeId = reqDict["bridgeId"] as? String,
                      let moduleName = reqDict["moduleName"] as? String,
                        reqDict["name"] as? String != nil,
                        reqDict["reqId"] as? String != nil,
                      bridgeId == strongSelf.id else {
                    let resReq = BridgeRes(bridgeId:strongSelf.id, req:req, failedMsg: "req params is invalid", data: nil)
                    strongSelf.jsBridge?.invokeMethod(strongSelf.receiveNativeCallbackReqFucName, withArguments: [resReq.toDict()])
                    return
                }
                
                guard let module = strongSelf.moduleMap[moduleName] else {
                    let resReq = BridgeRes(bridgeId:strongSelf.id, req:req, failedMsg: "Not found module: \(moduleName)", data: nil)
                    strongSelf.jsBridge?.invokeMethod(strongSelf.receiveNativeCallbackReqFucName, withArguments: [resReq.toDict()])
                    return
                }
                
                module.didReceiveReq(bridge: strongSelf, req: req)
            }
        }
        jsBridgeObj.setValue(sendReqToNative, forProperty: sendReqToNativeFucName)
    }
}
