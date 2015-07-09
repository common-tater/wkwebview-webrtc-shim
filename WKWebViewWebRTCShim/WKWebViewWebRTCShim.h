//
//  WKWebViewWebRTCShim.h
//  wkwebview-webrtc-shim
//
//  Created by Jesse Tane on 3/16/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#ifndef WKWebViewWebRTCShim_h
#define WKWebViewWebRTCShim_h

//#define WKWEBVIEW_WEBRTC_SHIM_DEBUG 1

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "RTCPeerConnection.h"
#import "RTCSessionDescription.h"
#import "RTCIceCandidate.h"
#import "RTCDataChannel.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCStatsDelegate.h"
#import "RTCStatsReport.h"
#import "RTCPair.h"

@class WKWebViewWebRTCShim;
@class RTCPeerConnectionFactory;

#import "WKWebViewWebRTCShimJavaScriptID.h"
#import "WKWebViewWebRTCShimSessionDescriptionCallbackWrapper.h"
#import "WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper.h"

@interface WKWebViewWebRTCShim : NSObject <WKScriptMessageHandler, RTCPeerConnectionDelegate, RTCDataChannelDelegate> {
  NSArray *methods;
  RTCPeerConnectionFactory *factory;
}

@property (nonatomic, assign) WKWebView *webView;
@property (nonatomic, retain) NSMutableDictionary *connections;
@property (nonatomic, retain) NSMutableDictionary *descriptions;
@property (nonatomic, retain) NSMutableDictionary *candidates;
@property (nonatomic, retain) NSMutableDictionary *channels;

- (id) initWithWebView:(WKWebView*)view contentController:(WKUserContentController *)controller;
- (NSString*)escapeForJS:(NSString*)string;
- (NSString*)genUniqueId:(NSDictionary*)lookup;

@end

#endif
