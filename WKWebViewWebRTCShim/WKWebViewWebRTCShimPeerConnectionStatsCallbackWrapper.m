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
  NSMutableArray *json = [[NSMutableArray alloc] init];

  for (RTCStatsReport *report in stats) {
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    for (RTCPair *pair in report.values) {
      [values setObject:pair.value forKey:pair.key];
    }
    [json addObject:@{
      @"id": report.reportId,
      @"type": report.type,
      @"timestamp": @(report.timestamp),
      @"values": values
    }];
  }

  NSString* jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:json options:0 error:nil] encoding:NSUTF8StringEncoding];
  NSString *js = [NSString stringWithFormat:@"RTCPeerConnection._executeCallback('%@', '%@', '%@', function () { return [ JSON.parse('%@') ] })",
                  peerConnection.jsid,
                  onSuccess,
                  onError,
                  jsonString];

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_getStats: %@", stats);
#endif

  [shim.webView evaluateJavaScript:js completionHandler:nil];
}

@end
