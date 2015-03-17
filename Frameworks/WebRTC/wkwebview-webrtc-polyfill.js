(function (exports) {
  
  exports.RTCPeerConnection = RTCPeerConnection
  exports.RTCSessionDescription = RTCSessionDescription
  exports.RTCIceCandidate = RTCIceCandidate
  exports.RTCDataChannel = RTCDataChannel

  exports._WKWebViewWebRTCPolyfill = {
    callbacks: {},
    connections: {},
    descriptions: {},
    candidates: {},
    channels: {},
    base64ToBinary: base64ToBinary
  }

  var callbacks = exports._WKWebViewWebRTCPolyfill.callbacks
  var connections = exports._WKWebViewWebRTCPolyfill.connections
  var descriptions = exports._WKWebViewWebRTCPolyfill.descriptions
  var candidates = exports._WKWebViewWebRTCPolyfill.candidates
  var channels = exports._WKWebViewWebRTCPolyfill.channels

  function RTCPeerConnection (config, constraints) {
    this._id = genUniqueId(connections)
    connections[this._id] = this

    window.webkit.messageHandlers.RTCPeerConnection_new.postMessage({
      id: this._id,
      constraints: constraints,
      iceServers: config.iceServers.map(function (server) {
        return server.url
      })
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
    var channel = new RTCDataChannel(id)

    window.webkit.messageHandlers.RTCPeerConnection_createDataChannel.postMessage({
      id: this._id,
      channel: channel._id,
      label: label,
      optional: optional
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

  function RTCDataChannel (id) {
    this._id = id
    channels[id] = this
  }

  RTCDataChannel.prototype.send = function (data) {
    window.webkit.messageHandlers.RTCDataChannel_send.postMessage({
      id: this._id,
      data: binaryToBase64(data)
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

    console.log('posting', name)
    window.webkit.messageHandlers[name].postMessage(params)
  }

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

  function base64ToBinary (string) {
    var binaryString =  window.atob(string)
    var len = binaryString.length
    var bytes = new Uint8Array(len)

    for (var i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i)
    }

    return bytes.buffer
  }

  function binaryToBase64 (buffer) {
    return window.btoa(String.fromCharCode.apply(null, new Uint8Array(buffer)))
  }

})(window)
