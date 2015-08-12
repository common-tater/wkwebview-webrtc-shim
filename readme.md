# wkwebview-webrtc-shim
`RTCPeerConnection` and `RTCDataChannel` shim for iOS.

## Why
So your WebRTC code can run on iOS.

## How
Make a static library from [this](http://www.webrtc.org/native-code/ios), then bind JavaScript to it across the postMessage bus.

## Install
First download and build libWebRTC (be warned, it takes a while):
```
$ bin/build-libwebrtc
```

Then drag the folder called "WKWebViewWebRTCShim" into your xcode project and import these frameworks:

- libc++.dylib
- libz.1.2.5.dylib
- AVFoundation.framework
- AudioToolbox.framework
- CoreMedia.framework

## Example
This code shows how to create and shim a WKWebView in Swift:

``` swift
var configuration = WKWebViewConfiguration()
var controller = WKUserContentController()
configuration.userContentController = controller

var webView = WKWebView(frame: container.frame, configuration: configuration)
container.addSubview(webView)

// apply shim
WKWebViewWebRTCShim(webView: webView, contentController: controller)

var request = NSURLRequest(URL: NSURL(string:"http://instant.io")!)
webView.loadRequest(request)
```

Note: since the shim is written in Objective C, you will need a [bridging header](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html) to use it with swift.

## Test
Install some dev dependencies:
```
$ npm install
```

Serve up [simple-peer](https://github.com/feross/simple-peer)'s tests with [zuul](https://github.com/defunctzombie/zuul):
```
$ npm run test
```

Open the example app in xcode and run it:
```
$ open example/WKWebViewWebRTCShimExample.xcodeproj
```

## License
MIT
