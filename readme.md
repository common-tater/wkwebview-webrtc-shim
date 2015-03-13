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
