//
//  WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper.h
//  CommonTater
//
//  Created by Jesse Tane on 5/12/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#ifndef WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper_h
#define WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper_h

#import "WKWebViewWebRTCShim.h"

@interface WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper : NSObject <RTCStatsDelegate> {
    WKWebViewWebRTCShim *shim;
    NSString *onError;
    NSString *onSuccess;
}

- (id)initWithShim:(WKWebViewWebRTCShim*)instance
         onSuccess:(NSString*)success
           onError:(NSString*)error;

@end

#endif
