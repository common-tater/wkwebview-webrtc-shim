# wkwebview-webrtc-shim
`RTCPeerConnection` and `RTCDataChannel` shim for iOS.

## Note
Still a WIP - use at your own risk!

## Build

Download and build libwebrtc (this could take a long time):
```
$ bin/build-libwebrtc
```

Install JavaScript dependencies:
```
$ npm install
```

## Test

Start HTTP server to serve up test app:
```
$ npm run test
```

Open test wrapper in xcode and run:
```
$ open test/WKWebViewWebRTCShimTest.xcodeproj
```

## License
MIT
