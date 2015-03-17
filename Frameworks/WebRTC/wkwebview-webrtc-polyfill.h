//
//  wkwebview-webrtc-polyfill.h
//  webrtc-webview-ios
//
//  Created by Jesse Tane on 3/16/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#ifndef webrtc_webview_ios_wkwebview_webrtc_polyfill_h
#define webrtc_webview_ios_wkwebview_webrtc_polyfill_h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <WebKit/WebKit.h>
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCICEServer.h"
#import "RTCMediaConstraints.h"
#import "RTCSessionDescription.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCIceCandidate.h"
#import "RTCPair.h"
#import "RTCDataChannel.h"

// add jsid as associated object
@interface RTCPeerConnection (JavaScript)
@property (nonatomic, copy) NSString *jsid;
@end

// add jsid as associated object
@interface RTCSessionDescription (JavaScript)
@property (nonatomic, copy) NSString *jsid;
@end

// add jsid as associated object
@interface RTCICECandidate (JavaScript)
@property (nonatomic, copy) NSString *jsid;
@end

// add jsid as associated object
@interface RTCDataChannel (JavaScript)
@property (nonatomic, copy) NSString *jsid;
@end

@class WKWebViewWebRTCPolyfill;

// RTCSessionDescriptionDelegate to wrap js callbacks
@interface JSSDCallbackWrapper : NSObject <RTCSessionDescriptionDelegate> {
  WKWebViewWebRTCPolyfill *polyfill;
  NSString *operationName;
  NSString *onError;
  NSString *onSuccess;
}
@end

// the polyfill
@interface WKWebViewWebRTCPolyfill : NSObject <WKScriptMessageHandler, RTCPeerConnectionDelegate, RTCDataChannelDelegate> {
  NSArray *methods;
  RTCPeerConnectionFactory *factory;
}

@property (nonatomic, retain) WKWebView *webView;
@property (nonatomic, retain) NSMutableDictionary *connections;
@property (nonatomic, retain) NSMutableDictionary *descriptions;
@property (nonatomic, retain) NSMutableDictionary *candidates;
@property (nonatomic, retain) NSMutableDictionary *channels;

- (id) initWithWebView:(WKWebView*)view contentController:(WKUserContentController *)controller;
- (NSString*)escapeForJS:(NSString*)string;
- (NSString*)genUniqueId:(NSDictionary*)lookup;

@end

#endif
