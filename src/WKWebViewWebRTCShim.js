(function (exports) {
  
  exports.RTCPeerConnection = RTCPeerConnection
  exports.RTCSessionDescription = RTCSessionDescription
  exports.RTCIceCandidate = RTCIceCandidate
  exports.RTCDataChannel = RTCDataChannel

  exports._WKWebViewWebRTCShim = {
    callbacks: {},
    connections: {},
    descriptions: {},
    candidates: {},
    channels: {},
    base64ToData: base64ToData
  }

  var callbacks = exports._WKWebViewWebRTCShim.callbacks
  var connections = exports._WKWebViewWebRTCShim.connections
  var descriptions = exports._WKWebViewWebRTCShim.descriptions
  var candidates = exports._WKWebViewWebRTCShim.candidates
  var channels = exports._WKWebViewWebRTCShim.channels

  RTCPeerConnection._executeCallback = function (id, cb1, cb2, getArgs) {
    var connection = connections[id]

    if (!connection) {
      delete callbacks[cb1]
      delete callbacks[cb2]
      return
    }

    callbacks[cb1].apply(null, getArgs && getArgs.call(connection))
  }

  function RTCPeerConnection (config, constraints) {
    this._id = genUniqueId(connections)
    this.iceConnectionState = 'new'
    this.iceGatheringState = 'new'
    connections[this._id] = this

    window.webkit.messageHandlers.RTCPeerConnection_new.postMessage({
      id: this._id,
      constraints: constraints,
      iceServers: config.iceServers
    })
  }

  RTCPeerConnection.prototype.createOffer = function (onsuccess, onerror) {
    postMessage('RTCPeerConnection_createOffer', {
      id: this._id
    }, onsuccess, onerror)
  }

  RTCPeerConnection.prototype.createAnswer = function (onsuccess, onerror) {
    postMessage('RTCPeerConnection_createAnswer', {
      id: this._id
    }, onsuccess, onerror)
  }

  RTCPeerConnection.prototype.setLocalDescription = function (description, onsuccess, onerror) {
    postMessage('RTCPeerConnection_setLocalDescription', {
      id: this._id,
      description: description._id
    }, onsuccess, onerror)
  }

  RTCPeerConnection.prototype.setRemoteDescription = function (description, onsuccess, onerror) {
    postMessage('RTCPeerConnection_setRemoteDescription', {
      id: this._id,
      description: description._id
    }, onsuccess, onerror)
  }

  RTCPeerConnection.prototype.addIceCandidate = function (candidate, onsuccess, onerror) {
    postMessage('RTCPeerConnection_addIceCandidate', {
      id: this._id,
      candidate: candidate._id,
    }, onsuccess, onerror)
  }

  RTCPeerConnection.prototype.createDataChannel =  function (label, optional) {
    var id = genUniqueId(channels)
    var channel = new RTCDataChannel(label, optional, id)

    window.webkit.messageHandlers.RTCPeerConnection_createDataChannel.postMessage({
      id: this._id,
      channel: channel._id,
      label: label,
      optional: optional
    })

    return channel
  }

  RTCPeerConnection.prototype.getStats =  function (cb) {
    postMessage('RTCPeerConnection_getStats', {
      id: this._id
    }, function (reportsData) {
      var reports = []

      for (var i in reportsData) {
        var reportData = reportsData[i]
        var report = new RTCStatsReport()
      }

      cb({ result: function () { return reports } })
    }, function () {})
  }

  RTCPeerConnection.prototype.close =  function () {
    delete connections[this._id]

    if (this.localDescription) {
      delete descriptions[this.localDescription._id]
    }

    if (this.remoteDescription) {
      delete descriptions[this.remoteDescription._id]
    }

    window.webkit.messageHandlers.RTCPeerConnection_close.postMessage({
      id: this._id
    })
  }

  function RTCSessionDescription (data, id) {
    this.type = data.type
    this.sdp = data.sdp
    this._id = id || genUniqueId(descriptions)
    descriptions[this._id] = this

    if (id) return

    window.webkit.messageHandlers.RTCSessionDescription_new.postMessage({
      id: this._id,
      data: data
    })
  }

  function RTCIceCandidate (data, id) {
    this.sdpMid = data.sdpMid
    this.sdpMLineIndex = data.sdpMLineIndex
    this.candidate = data.candidate
    this._id = id || genUniqueId(candidates)
    candidates[this._id] = this

    if (id) return

    window.webkit.messageHandlers.RTCIceCandidate_new.postMessage({
      id: this._id,
      data: data
    })
  }

  function RTCDataChannel (label, optional, id) {
    this.label = label
    this._id = id
    channels[id] = this
  }

  RTCDataChannel.prototype.send = function (data) {
    var encoded = dataToBase64(data)

    window.webkit.messageHandlers.RTCDataChannel_send.postMessage({
      id: this._id,
      data: encoded.data,
      binary: encoded.binary
    })
  }

  RTCDataChannel.prototype.close = function (data) {
    delete channels[this._id]

    window.webkit.messageHandlers.RTCDataChannel_close.postMessage({
      id: this._id
    })
  }

  function postMessage (name, params, onsuccess, onerror) {
    params.onsuccess = registerCallback(function (obj) {
      deregisterCallback(params.onsuccess)
      deregisterCallback(params.onerror)
      onsuccess(obj)
    })

    params.onerror = registerCallback(function (err) {
      deregisterCallback(params.onsuccess)
      deregisterCallback(params.onerror)
      onerror(err)
    })

    window.webkit.messageHandlers[name].postMessage(params)
  }

  function RTCStatsReport () {}

  // ipc helpers

  function registerCallback (cb) {
    var id = genUniqueId(callbacks)
    callbacks[id] = cb
    return id
  }

  function deregisterCallback (id) {
    delete callbacks[id]
  }

  function genUniqueId (lookup) {
    var id = genId()
 
    while (lookup[id]) {
      id = genId()
    }
 
    return id
  }

  function genId () {
    return Math.random().toString().slice(2)
  }

  function base64ToData (string) {
    var binaryString =  window.atob(string)
    var len = binaryString.length
    var bytes = new Uint8Array(len)

    for (var i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i)
    }

    return bytes.buffer
  }

  function dataToBase64 (data) {
    var binary = false

    if (data instanceof ArrayBuffer) {
      data = String.fromCharCode.apply(null, new Uint8Array(data))
      binary = true
    } else if (isTypedArray(data)) {
      data = String.fromCharCode.apply(null, data)
      binary = true
    }

    return {
      data: window.btoa(data),
      binary: binary
    }
  }

  function isTypedArray (obj) {
    return obj && obj.buffer
  }

})(window)
