//
//  BridgeModule.swift
//  JSBridge
//
//  Created by milker90 on 2023/1/6.
//

import Foundation

protocol BridgeModule: NSObjectProtocol {
    func moduleName() -> String
    func didReceiveReq(bridge: Bridge, req: BridgeReq) -> Void
}
