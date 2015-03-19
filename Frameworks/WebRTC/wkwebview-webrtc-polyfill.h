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
#import <WebKit/WebKit.h>

#import "RTCPeerConnection.h"
#import "RTCSessionDescription.h"
#import "RTCIceCandidate.h"
#import "RTCDataChannel.h"
#import "RTCSessionDescriptionDelegate.h"

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

// RTCSessionDescriptionDelegate to wrap js callbacks

@class WKWebViewWebRTCPolyfill;

@interface JSSDCallbackWrapper : NSObject <RTCSessionDescriptionDelegate> {
  WKWebViewWebRTCPolyfill *polyfill;
  NSString *operationName;
  NSString *onError;
  NSString *onSuccess;
}
@end

// the polyfill

@class RTCPeerConnectionFactory;

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
