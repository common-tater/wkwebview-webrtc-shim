//
//  wkwebview-webrtc-polyfill.h
//  webrtc-webview-ios
//
//  Created by Jesse Tane on 3/16/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#ifndef WKWebViewWebRTCShimSessionDescriptionCallbackWrapper_h
#define WKWebViewWebRTCShimSessionDescriptionCallbackWrapper_h

#import "WKWebViewWebRTCShim.h"

@interface WKWebViewWebRTCShimSessionDescriptionCallbackWrapper : NSObject <RTCSessionDescriptionDelegate> {
  WKWebViewWebRTCShim *shim;
  NSString *operationName;
  NSString *onError;
  NSString *onSuccess;
}

- (id)initWithShim:(WKWebViewWebRTCShim*)instance
         operation:(NSString*)name
         onSuccess:(NSString*)success
           onError:(NSString*)error;

@end

#endif
