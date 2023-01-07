//
//  ViewController.swift
//  JSBridge
//
//  Created by milker90 on 2023/1/7.
//

import UIKit

class ViewController: UIViewController {
    var bridge: Bridge?
    var jsCallNativetimer: Timer?
    var nativetCallJsimer: Timer?
    
    @objc func jsCallNative() {
        bridge?.callJsGlobalFunc("testJSCallNative")
    }
    
    @objc func nativetCallJs() {
        DispatchQueue.global().async {
            let req1 = BridgeCallbackReq(moduleName: "World", name: "getPlanetName", params: nil) { res in
                print("\(String(describing: Thread.current)) \(String(describing: res.req.reqId)): \(String(describing: res.code?.rawValue)) \(String(describing: res.data))")
            }
            self.bridge?.sendReqToJs(req1)
            
            let req2 = BridgeCallbackReq(moduleName: "World", name: "getPlanetName", params: nil) { res in
                print("\(String(describing: Thread.current)) \(String(describing: res.req.reqId)): \(String(describing: res.code?.rawValue)) \(String(describing: res.data))")
            }
            self.bridge?.sendReqToJs(req2)
        }
        
        DispatchQueue.global().async {
            let req = BridgeCallbackReq(moduleName: "World", name: "getPlanetName", params: nil) { res in
                print("\(String(describing: Thread.current)) \(String(describing: res.req.reqId)): \(String(describing: res.code?.rawValue)) \(String(describing: res.data))")
            }
            self.bridge?.sendReqToJs(req)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            bridge = try Bridge()
            let isOK = bridge?.checkBridgeIsOK()
            print("bridge isOK:\(String(describing: isOK))")
            bridge?.addModules([HelloModule()])
        } catch {
            print("\(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        jsCallNativetimer?.invalidate()
        nativetCallJsimer?.invalidate()

        jsCallNativetimer = Timer(timeInterval: 0.1, target: self, selector: #selector(jsCallNative), userInfo: nil, repeats: true)
        RunLoop.current.add(jsCallNativetimer!, forMode: .common)

        nativetCallJsimer = Timer(timeInterval: 0.2, target: self, selector: #selector(nativetCallJs), userInfo: nil, repeats: true)
        RunLoop.current.add(nativetCallJsimer!, forMode: .common)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        jsCallNativetimer?.invalidate()
        jsCallNativetimer = nil
        nativetCallJsimer?.invalidate()
        nativetCallJsimer = nil
    }
}
