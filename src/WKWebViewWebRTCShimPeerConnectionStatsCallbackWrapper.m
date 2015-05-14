//
//  WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper.m
//  CommonTater
//
//  Created by Jesse Tane on 5/12/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#import "WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper.h"

@implementation WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper

- (id)initWithShim:(WKWebViewWebRTCShim*)instance
         onSuccess:(NSString*)success
           onError:(NSString*)error {
  if (self = [super init]) {
    shim = instance;
    onSuccess = success;
    onError = error;
  }
  return self;
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
           didGetStats:(NSArray*)stats {
  NSString *js = [NSString stringWithFormat:@"RTCPeerConnection._executeCallback('%@', '%@', '%@', function () {})",
                  peerConnection.jsid,
                  onSuccess,
                  onError];

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_getStats: %@", stats);
#endif

  [shim.webView evaluateJavaScript:js completionHandler:nil];
}

@end
