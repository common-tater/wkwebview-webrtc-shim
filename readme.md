# wkwebview-webrtc-shim
A `RTCPeerConnection` and `RTCDataChannel` polyfill for `WKWebView` using `WKScriptMessageHandler` and [webrtc.org](http://www.webrtc.org/native-code/ios)'s AppRTCDemo.

## Why
Apple is not supporting WebRTC yet.

## How
Build libWebRTC.a and get it into your project. See below for help:
* http://www.webrtc.org
* https://github.com/common-tater/webrtc-build-ios
* http://ninjanetic.com/how-to-get-started-with-webrtc-and-ios-without-wasting-10-hours-of-your-life

## Notes
Just a prototype for the moment!  

[simple-peer](https://github.com/feross/simple-peer)'s test suite passes and [instant.io](https://instant.io/) (webtorrent) works.

#### TODO
* Not sure where but something is doing real work in the main thread. This can block the UI (albeit very briefly) but could probably be easily fixed by profiling the app and applying `dispatch_async` where necessary.
* There are some leaks on both the JavaScript and native sides - connection lifecycles need to be more carefully observed to eliminate these.
