# webrtc-webview-ios
An iOS application template that presents a single fullscreen `WKWebView` with the `RTCPeerConnection` and `RTCDataChannel` APIs polyfilled using `WKScriptMessageHandler` and [webrtc.org](http://www.webrtc.org/native-code/ios)'s AppRTCDemo.

## Why
Apple is not supporting WebRTC yet.

## How
Build libWebRTC.a and get it to `Framworks/WebRTC/libWebRTC.a`. See:
* http://ninjanetic.com/how-to-get-started-with-webrtc-and-ios-without-wasting-10-hours-of-your-life/
* https://github.com/common-tater/webrtc-build-ios

## Notes
Just a prototype for the moment!  

[simple-peer](https://github.com/feross/simple-peer)'s test suite passes and [instant.io](https://instant.io/) (aka webtorrent) works.

#### TODO
* Not sure where but something is doing real work in the main thread. This can block the UI (albeit very briefly) but could probably be easily fixed by profiling the app and applying `dispatch_async` where necessary.
* There are some leaks on both the JavaScript and native sides - connection lifecycles need to be a bit more carefully observed to completely eliminate these.
