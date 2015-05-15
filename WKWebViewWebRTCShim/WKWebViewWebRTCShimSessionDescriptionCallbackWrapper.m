//
//  wkwebview-webrtc-polyfill.m
//  webrtc-webview-ios
//
//  Created by Jesse Tane on 3/16/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#import "WKWebViewWebRTCShimSessionDescriptionCallbackWrapper.h"

@implementation WKWebViewWebRTCShimSessionDescriptionCallbackWrapper

- (id)initWithShim:(WKWebViewWebRTCShim*)instance
         operation:(NSString*)name
         onSuccess:(NSString*)success
           onError:(NSString*)error {
  if (self = [super init]) {
    shim = instance;
    operationName = name;
    onSuccess = success;
    onError = error;
  }
  return self;
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error {
  NSString *js = @"";

  if (error) {
    js = [NSString stringWithFormat: @"RTCPeerConnection._executeCallback('%@', '%@', '%@', function () { return [ '%@' ] })",
          peerConnection.jsid,
          onError,
          onSuccess,
          error.localizedDescription];
  } else {
    NSString *sdpid = [shim genUniqueId:shim.descriptions];
    NSString *propertyName = nil;

    if ([operationName isEqualToString:@"createOffer"]) {
      propertyName = @"offer";
    } else if ([operationName isEqualToString:@"createAnswer"]) {
      propertyName = @"answer";
    }

    sdp.jsid = sdpid;
    shim.descriptions[sdpid] = sdp;

    js = [NSString stringWithFormat:@"RTCPeerConnection._executeCallback('%@', '%@', '%@', function () { return [ new RTCSessionDescription({ type: '%@', sdp: '%@' }, '%@') ] })",
          peerConnection.jsid,
          onSuccess,
          onError,
          sdp.type,
          [shim escapeForJS:sdp.description],
          sdpid];
  }

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_on%@: %@", operationName, js);
#endif

  [shim.webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {
  NSString *js = nil;

  if (error) {
    js = [NSString stringWithFormat: @"RTCPeerConnection._executeCallback('%@', '%@', '%@', function () { return [ '%@' ] })",
          peerConnection.jsid,
          onError,
          onSuccess,
          error.localizedDescription];
  } else {
    RTCSessionDescription *sdp = nil;
    NSString *sdpid = [shim genUniqueId:shim.descriptions];
    NSString *propertyName = nil;

    if ([operationName isEqualToString:@"setLocalDescription"]) {
      propertyName = @"localDescription";
      sdp = peerConnection.localDescription;
    } else if ([operationName isEqualToString:@"setRemoteDescription"]) {
      propertyName = @"remoteDescription";
      sdp = peerConnection.remoteDescription;
    }
    
    sdp.jsid = sdpid;
    shim.descriptions[sdpid] = sdp;

    js = [NSString stringWithFormat:@"RTCPeerConnection._executeCallback('%@', '%@', '%@', function () { this.%@ = new RTCSessionDescription({ type: '%@', sdp: '%@' }, '%@') })",
          peerConnection.jsid,
          onSuccess,
          onError,
          propertyName,
          sdp.type,
          [shim escapeForJS:sdp.description],
          sdpid];
  }

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_on%@: %@", operationName, js);
#endif

  [shim.webView evaluateJavaScript:js completionHandler:nil];
}

@end
