class BridgeReq {
  constructor(moduleName, name, params) {
    this.moduleName = moduleName
    this.name = name
    this.params = params
    this.reqId = ''
    this.bridgeId = ''
  }
}

class BridgeCallbackReq extends BridgeReq {
  constructor(moduleName, name, params, callback) {
    super(moduleName, name, params)
    this.callback = callback
  }
}

class BridgeRes {
  constructor(data) {
    this.bridgeId = data.bridgeId
    this.req = data.req
    this.data = data.data
    this.code = data.code
    this.msg = data.msg
  }
}

const BridgeResCode = {
  success: 200,
  reqError: 400,
}

class Bridge {
  constructor(global) {
    this.id = ''
    this.sendReqToNative = null
    this.sendCallbackReqToNative = null
    this.global = global
    this.reqNum = 0
    this.callbackReqMap = {}
    this.moduleMap = {}
  }

  setBridgeId(bridgeId) {
    this.id = bridgeId
  }

  addModules(modules) {
    for (const module of modules) {
      this.addModule(module)
    }
  }

  addModule(module) {
    let moduleName = module.moduleName();
    if (!moduleName) {
      return
    }

    if (this.moduleMap[moduleName]) {
      return
    }

    this.moduleMap[moduleName] = module
  }

  removeModule(moduleName) {
    if (!moduleName) {
      return
    }

    if (!this.moduleMap[moduleName]) {
      return
    }

    delete this.moduleMap[moduleName]
  }

  // receive native req
  receiveNativeReq(req) {
    // console.log(req, this.id);
    if (!req.moduleName ||
      !req.reqId ||
      !req.name ||
      req.bridgeId !== this.id) {
      let res = new BridgeRes({
        bridgeId: this.id,
        req,
        code: BridgeResCode.reqError,
        msg: "req params is invalid"
      })
      this.sendCallbackReqToNative(res)
      return
    }

    if (!this.moduleMap[req.moduleName]) {
      let res = new BridgeRes({
        bridgeId: this.id,
        req,
        code: BridgeResCode.reqError,
        msg: `Not found module ${req.moduleName}`
      })
      this.sendCallbackReqToNative(res)
      return
    }


    let didReceiveReqFunc = this.moduleMap[req.moduleName]["didReceiveReq"]
    if (didReceiveReqFunc) {
      didReceiveReqFunc.call(this.moduleMap[req.moduleName], this, req)
    }
  }

  receiveNativeCallbackReq(res) {
    // console.log("res", res);
    if (!res.req ||
      !res.code ||
      !res.req.reqId ||
      res.bridgeId !== this.id) {
      console.log(`callback res data is invalid, ${res}`)
      return
    }

    let req = this.callbackReqMap[res.req.reqId]
    if (!req) {
      console.log(`not found callback req, ${req}`)
      return
    }

    // console.log("req", req);
    if (req.callback) {
      // TODO: this
      req.callback.call(this.global, res)
      delete this.callbackReqMap[res.req.reqId]
    }
  }

  // send msg to native, depend native inject sendReqToNative func to bridge
  // sendReqToNative
  sendReq(req) {
    if (!this.sendReqToNative) {
      return
    }

    req.bridgeId = this.id
    this.reqNum++
    req.reqId = `J_${this.reqNum}`
    if (req instanceof BridgeCallbackReq) {
      this.callbackReqMap[req.reqId] = req
      let { callback, ...willMsg } = req
      this.sendReqToNative(willMsg)
    } else {
      this.sendReqToNative(req)
    }
  }

  sendSuccessCallbackToNative(req, data) {
    if (!this.sendCallbackReqToNative) {
      return
    }

    let res = new BridgeRes({
      bridgeId: this.id,
      req,
      code: BridgeResCode.success,
      data,
    })

    this.sendCallbackReqToNative(res)
  }

  sendFailedCallbackToNative(req, failedMsg, data) {
    if (!this.sendCallbackReqToNative) {
      return
    }

    let res = new BridgeRes({
      bridgeId: this.id,
      req,
      code: BridgeResCode.reqError,
      data,
      msg: failedMsg,
    })

    this.sendCallbackReqToNative(res)
  }
}

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

var bridge = new Bridge(this);
bridge.addModules([new WorldModule()])

// test code
function testJSCallNative() {
  let req = new BridgeCallbackReq("Hello", "addTwoNum", [1, 2], (res) => {
    console.log(`${res.req.reqId}: ${res.code} ${res.data}`)
  })
  bridge.sendReq(req)
}

