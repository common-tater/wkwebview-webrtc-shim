// WebRTC JavaScript polyfill native bindings

var callbacks = window._ios_webrtc_polyfill_callbacks = {}

window._ios_webrtc_polyfill_sync = function (message) {
  return webkit.messageHandlers.sync.postMessage({
    message: message
  })
}

window._ios_webrtc_polyfill_async = function (message, cb) {
  var cbid = registerCallback(cb)

  webkit.messageHandlers.async.postMessage({
    message: message,
    cbid: cbid
  })
}

function registerCallback (cb) {
  var id = genId()

  while (callbacks[id]) {
    id = genId()
  }

  callbacks[id] = cb
  return id
}

function genId () {
  return Math.random().toString().slice(2)
}
