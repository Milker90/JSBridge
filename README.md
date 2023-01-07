## JSBridge

实现iOS和JS通信类似Http请求

## 类介绍
Bridge 管理请求和响应，管理注册模块和分发请求到注册模块

BridgeModule 业务模块，实现响应请求

BridgeReq 请求信息

BridgeRes 响应信息

以上类在Native和JS都会实现, 由于JS是单线程，所以在Bridge类实现会和Native有所不同，Native会处理线程安全问题


## 例子
在iOS端创建一个Bridge对象和一个HelloModule，在js中创建一个Bridge对象和一个WorldModule，然后在iOS中调用WorldModule中的接口，在js中调用HelloModule的接口

在iOS种添加一个HelloModule
```swift
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
```

在js中添加一个WorldModule
```js
class WorldModule {
  moduleName() {
    return "World"
  }

  didReceiveReq(bridge, req) {
    if (req.name === "getPlanetName") {
      let res = this.getPlanetName()
      bridge.sendSuccessCallbackToNative(req, res)
    }
  }

  getPlanetName() {
    return "Earth"
  }
}
```

在iOS中创建一个bridge对象，并添加HelloModule
```swift
  do {
      bridge = try Bridge()
      let isOK = bridge?.checkBridgeIsOK()
      print("bridge isOK:\(String(describing: isOK))")
      bridge?.addModules([HelloModule()])
  } catch {
      print("\(error)")
  }
```

在js中创建一个bridge对象，并添加WorldModule
```js
  var bridge = new Bridge(this);
  bridge.addModules([new WorldModule()])
```

在iOS中调用js中的WorldModule
```swift
  let req = BridgeCallbackReq(moduleName: "World", name: "getPlanetName", params: nil) { res in
      print("\(String(describing: Thread.current)) \(String(describing: res.req.reqId)): \(String(describing: res.code?.rawValue)) \(String(describing: res.data))")
  }
  self.bridge?.sendReqToJs(req)
```

在js中调用iOS中的HelloModule
```js
  let req = new BridgeCallbackReq("Hello", "addTwoNum", [1, 2], (res) => {
    console.log(`${res.req.reqId}: ${res.code} ${res.data}`)
  })
  bridge.sendReq(req)
```

具体例子可查看工程代码

## 后续问题
请求队列考虑