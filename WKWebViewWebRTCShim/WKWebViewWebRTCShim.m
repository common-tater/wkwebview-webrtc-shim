//
//  WKWebViewWebRTCShim.m
//  wkwebview-webrtc-shim
//
//  Created by Jesse Tane on 3/16/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#import "WKWebViewWebRTCShim.h"

#import "RTCPeerConnectionFactory.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCICEServer.h"
#import "RTCMediaConstraints.h"
#import "RTCPair.h"

@implementation WKWebViewWebRTCShim

@synthesize webView,
            connections,
            descriptions,
            candidates,
            channels;

- (id)initWithWebView:(WKWebView*)view
    contentController:(WKUserContentController *)controller {
  if (self = [super init]) {
    webView = view;
    connections = [[NSMutableDictionary alloc] init];
    descriptions = [[NSMutableDictionary alloc] init];
    candidates = [[NSMutableDictionary alloc] init];
    channels = [[NSMutableDictionary alloc] init];
    methods = @[
      @"RTCPeerConnection_new",
      @"RTCPeerConnection_setRemoteDescription",
      @"RTCPeerConnection_setLocalDescription",
      @"RTCPeerConnection_createOffer",
      @"RTCPeerConnection_createAnswer",
      @"RTCPeerConnection_addIceCandidate",
      @"RTCPeerConnection_createDataChannel",
      @"RTCPeerConnection_getStats",
      @"RTCPeerConnection_close",
      @"RTCSessionDescription_new",
      @"RTCIceCandidate_new",
      @"RTCDataChannel_send",
      @"RTCDataChannel_close"
    ];

    for (NSString *method in methods) {
      [controller addScriptMessageHandler:self name:method];
    }

    NSString * path = [[NSBundle mainBundle].resourcePath stringByAppendingString:@"/WKWebViewWebRTCShim.js"];
    NSString * bindingJs = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    WKUserScript * script = [[WKUserScript alloc] initWithSource:bindingJs injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:true];
    [controller addUserScript:script];

    [RTCPeerConnectionFactory initializeSSL];
    factory = [[RTCPeerConnectionFactory alloc] init];
  }

  return self;
}

#pragma mark incoming JavaScript message

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
  NSDictionary * params = (NSDictionary *) message.body;
  NSString *name = nil;

  for (NSString *method in methods) {
    if ([message.name isEqualToString:method]) {
      name = [method stringByAppendingString:@":"];
      break;
    }
  }

  if (!name) {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"unrecognized method");
#endif

    return;
  }
  
  // ridiculous hoop jumping to call method by name
  SEL selector = NSSelectorFromString(name);
  IMP imp = [self methodForSelector:selector];
  void (*func)(id, SEL, NSDictionary *) = (void *)imp;
  func(self, selector, params);
  
  // lame hack to fix over-retained message.body
  CFRelease((__bridge CFTypeRef) params);
}

- (RTCMediaConstraints*)defaultConstraints {
  return [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil
                                               optionalConstraints:nil];
}

#pragma mark RTCPeerConnection binding

- (void)RTCPeerConnection_new:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_new: %@", params);
#endif

  NSString *jsid = params[@"id"];
  NSArray *iceServersToParse = params[@"iceServers"];
  NSMutableArray *iceServers = [[NSMutableArray alloc] init];
  NSDictionary *server = nil;
  NSString *url = nil;
  NSString *username = nil;
  NSString *password = nil;

  for (server in iceServersToParse) {
    url = server[@"url"];
    username = server[@"username"];
    password = server[@"credential"];

    RTCICEServer *iceServer = [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:url]
                                                       username:username ? username : @""
                                                       password:password ? password : @""];

    [iceServers addObject:iceServer];
  }

  RTCPeerConnection * connection = [factory peerConnectionWithICEServers:iceServers
                                                             constraints:nil //[self defaultConstraints]
                                                                delegate:self];
  
  connection.jsid = jsid;
  connections[jsid] = connection;
}

- (void)RTCPeerConnection_createOffer:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_createOffer: %@", params);
#endif

  RTCPeerConnection *connection = connections[params[@"id"]];
  WKWebViewWebRTCShimSessionDescriptionCallbackWrapper *wrapper = [[WKWebViewWebRTCShimSessionDescriptionCallbackWrapper alloc] initWithShim:self
                                                                     operation:@"createOffer"
                                                                     onSuccess:params[@"onsuccess"]
                                                                       onError:params[@"onerror"]];

  [connection createOfferWithDelegate:wrapper constraints:[self defaultConstraints]];
}

- (void)RTCPeerConnection_createAnswer:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_createAnswer: %@", params);
#endif

  RTCPeerConnection *connection = connections[params[@"id"]];
  WKWebViewWebRTCShimSessionDescriptionCallbackWrapper *wrapper = [[WKWebViewWebRTCShimSessionDescriptionCallbackWrapper alloc] initWithShim:self
                                                                     operation:@"createAnswer"
                                                                     onSuccess:params[@"onsuccess"]
                                                                       onError:params[@"onerror"]];

  [connection createAnswerWithDelegate:wrapper constraints:[self defaultConstraints]];
}

- (void)RTCPeerConnection_setLocalDescription:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_setLocalDescription: %@", params);
#endif

  RTCPeerConnection *connection = connections[params[@"id"]];
  RTCSessionDescription *description = descriptions[params[@"description"]];
  WKWebViewWebRTCShimSessionDescriptionCallbackWrapper *wrapper = [[WKWebViewWebRTCShimSessionDescriptionCallbackWrapper alloc] initWithShim:self
                                                                     operation:@"setLocalDescription"
                                                                     onSuccess:params[@"onsuccess"]
                                                                       onError:params[@"onerror"]];
  
  [connection setLocalDescriptionWithDelegate:wrapper sessionDescription:description];
}

- (void)RTCPeerConnection_setRemoteDescription:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_setRemoteDescription: %@", params);
#endif

  RTCPeerConnection *connection = connections[params[@"id"]];
  RTCSessionDescription *description = descriptions[params[@"description"]];
  WKWebViewWebRTCShimSessionDescriptionCallbackWrapper *wrapper = [[WKWebViewWebRTCShimSessionDescriptionCallbackWrapper alloc] initWithShim:self
                                                                     operation:@"setRemoteDescription"
                                                                     onSuccess:params[@"onsuccess"]
                                                                       onError:params[@"onerror"]];

  [connection setRemoteDescriptionWithDelegate:wrapper sessionDescription:description];
}

- (void)RTCPeerConnection_addIceCandidate:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_addIceCandidate: %@", params);
#endif

  RTCPeerConnection *connection = connections[params[@"id"]];
  RTCICECandidate *candidate = candidates[params[@"candidate"]];
  
  [connection addICECandidate:candidate];

  NSString *js = [NSString stringWithFormat:@"RTCPeerConnection._executeCallback('%@', '%@', '%@')",
                  connection.jsid,
                  params[@"onsuccess"],
                  params[@"onerror"]];

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)RTCPeerConnection_createDataChannel:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_createDataChannel: %@", params);
#endif

  RTCPeerConnection *connection = connections[params[@"id"]];
  RTCDataChannel *channel = [connection createDataChannelWithLabel:params[@"label"] config:params[@"optional"]];

  NSString *jsid = params[@"channel"];
  channels[jsid] = channel;
  channel.jsid = jsid;
  channel.delegate = self;
}

- (void)RTCPeerConnection_getStats:(NSDictionary *)params {
  RTCPeerConnection *connection = connections[params[@"id"]];

  WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper *callbackWrapper = [[WKWebViewWebRTCShimPeerConnectionStatsCallbackWrapper alloc] initWithShim:self onSuccess:params[@"onsuccess"] onError:params[@"onerror"]];

  [connection getStatsWithDelegate:callbackWrapper
                  mediaStreamTrack:nil
                  statsOutputLevel:RTCStatsOutputLevelStandard];
}

- (void)RTCPeerConnection_close:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_close: %@", params);
#endif

  NSString *jsid = params[@"id"];
  RTCPeerConnection *connection = connections[jsid];

  if (connection.localDescription.jsid) {
    [descriptions removeObjectForKey:connection.localDescription.jsid];
  }
  if (connection.remoteDescription.jsid) {
    [descriptions removeObjectForKey:connection.remoteDescription.jsid];
  }

  connection.delegate = nil;
  [connection close];
  [connections removeObjectForKey:jsid];
}

#pragma mark RTCPeerConnectionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged {
  NSString *state;
  
  switch (stateChanged) {
    case RTCSignalingStable:
      state = @"stable";
      break;
    case RTCSignalingHaveLocalOffer:
      state = @"have-local-offer";
      break;
    case RTCSignalingHaveRemoteOffer:
      state = @"have-remote-offer";
      break;
    case RTCSignalingHaveLocalPrAnswer:
      state = @"have-local-pranswer";
      break;
    case RTCSignalingHaveRemotePrAnswer:
      state = @"have-remote-pranswer";
      break;
    case RTCSignalingClosed:
      state = @"closed";
      break;
    default:

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
      NSLog(@"RTCPeerConnection_onsignalingstatechange - unrecognized state %u", stateChanged);
#endif
      
      return;
  }

  NSString *js = [NSString stringWithFormat:@"var connection = window._WKWebViewWebRTCShim.connections['%@']; if (connection) { connection.signalingState = '%@'; var handler = connection.onsignalingstatechange; handler && handler(); }", peerConnection.jsid, state];

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_onsignalingstatechange: %@", js);
#endif

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream {
  NSString *js = [NSString stringWithFormat:@"var connection = window._WKWebViewWebRTCShim.connections['%@']; if (connection) { var handler = connection.onaddstream;  handler && handler(new Error('ENOTIMPLEMENTED')); }", peerConnection.jsid];
  
  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream {
  NSString *js = [NSString stringWithFormat:@"var connection = window._WKWebViewWebRTCShim.connections['%@']; if (connection) { var handler = connection.onremovestream; handler && handler(new Error('ENOTIMPLEMENTED')); }", peerConnection.jsid];
  
  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {
  NSString *js = [NSString stringWithFormat:@"var connection = window._WKWebViewWebRTCShim.connections['%@']; if (connection) { var handler = connection.onnegotiationneeded; handler && handler(new Error('ENOTIMPLEMENTED')); }", peerConnection.jsid];

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState {
  NSString *state;

  switch (newState) {
    case RTCICEConnectionNew:
      state = @"new";
      break;
    case RTCICEConnectionChecking:
      state = @"checking";
      break;
    case RTCICEConnectionConnected:
      state = @"connected";
      break;
    case RTCICEConnectionCompleted:
      state = @"completed";
      break;
    case RTCICEConnectionFailed:
      state = @"failed";
      break;
    case RTCICEConnectionDisconnected:
      state = @"disconnected";
      break;
    case RTCICEConnectionClosed:
      state = @"closed";
      break;
    default:
      
#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
      NSLog(@"RTCPeerConnection_oniceconnectionstatechange - unregognized state: %u", newState);
#endif

      return;
  }

  NSString *js = [NSString stringWithFormat:@"var connection = window._WKWebViewWebRTCShim.connections['%@']; if (connection) { connection.iceConnectionState = '%@'; var handler = connection.oniceconnectionstatechange; handler && handler(); }", peerConnection.jsid, state];

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_oniceconnectionstatechange: %@", js);
#endif

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState {
  NSString *state;
  NSString *iceComplete = @"";

  switch (newState) {
    case RTCICEGatheringNew:
      state = @"new";
      break;
    case RTCICEGatheringGathering:
      state = @"gathering";
      break;
    case RTCICEGatheringComplete:
      state = @"complete";
      iceComplete = @"handler = connection.onicecandidate; handler && handler({})";
      break;
    default:

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_onicegatheringstatechange - unregognized state: %u", newState);
#endif

    return;
  }

  NSString *js = [NSString stringWithFormat:@"var connection = window._WKWebViewWebRTCShim.connections['%@']; if (connection) { connection.iceGatheringState = '%@'; var handler = connection.onicegatheringstatechange; handler && handler(); %@ }",
                  peerConnection.jsid,
                  state,
                  iceComplete];

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_onicegatheringstatechange: %@", js);
#endif

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate {
  NSString *jsid = [self genUniqueId:candidates];
  candidate.jsid = jsid;
  candidates[jsid] = candidate;
  
  NSString *js = [NSString stringWithFormat:@"var connection = window._WKWebViewWebRTCShim.connections['%@'];", peerConnection.jsid];

  if (peerConnection.localDescription) {
    NSString *localDescriptionUpdate = [self escapeForJS:peerConnection.localDescription.description];
    js = [js stringByAppendingFormat:@" if (connection && connection.localDescription) { connection.localDescription.sdp = '%@' } ", localDescriptionUpdate];
  }

  js = [js stringByAppendingFormat:@"if (connection) { var handler = connection.onicecandidate; handler && handler({ candidate: new RTCIceCandidate({ sdpMid: '%@', sdpMLineIndex: '%ld', candidate: '%@' }, '%@') }) };",
        candidate.sdpMid,
        (long) candidate.sdpMLineIndex,
        [self escapeForJS:candidate.sdp],
        jsid];

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_onicecandidate: %@", js);
#endif

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)channel {
  NSString *jsid = [self genUniqueId:channels];
  channels[jsid] = channel;
  channel.jsid = jsid;
  channel.delegate = self;

  NSString *js = [NSString stringWithFormat:@"var connection = window._WKWebViewWebRTCShim.connections['%@']; if (connection) { var handler = connection.ondatachannel; if (handler) { handler({ channel: new RTCDataChannel('%@', null, '%@') }) }};",
                  peerConnection.jsid,
                  channel.label,
                  channel.jsid];

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCPeerConnection_ondatachannel: %@", js);
#endif

  [webView evaluateJavaScript:js completionHandler:nil];
}

#pragma mark RTCDataChannelDelegate

- (void)channelDidChangeState:(RTCDataChannel *)channel {
  NSString *state = nil;
  NSString *event = nil;

  switch (channel.state) {
    case kRTCDataChannelStateConnecting:
      state = @"connecting";
      break;
    case kRTCDataChannelStateOpen:
      state = @"open";
      event = @"onopen";
      break;
    case kRTCDataChannelStateClosing:
      state = @"closing";
      break;
    case kRTCDataChannelStateClosed:
      state = @"close";
      event = @"onclose";
      break;
    default:

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
      NSLog(@"RTCDataChannel_onstatechange - unregognized state: %u", channel.state);
#endif

      return;
  }

  NSString *js = [NSString stringWithFormat:@"var channel = window._WKWebViewWebRTCShim.channels['%@']; if (channel) { channel.readyState = '%@' }",
                  channel.jsid,
                  state];

  if (event) {
    js = [js stringByAppendingFormat:@"if (channel) { var handler = channel.%@; handler && handler() };", event];
  }

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCDataChannel_onstatechange: %@", js);
#endif

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)channel:(RTCDataChannel *)channel didReceiveMessageWithBuffer:(RTCDataBuffer *)buffer {
  NSString *js;

  if (buffer.isBinary) {
    js = [NSString stringWithFormat:@"var channel = window._WKWebViewWebRTCShim.channels['%@']; if (channel) { var handler = channel.onmessage; handler && handler({ data: window._WKWebViewWebRTCShim.base64ToData('%@') }) };",
          channel.jsid,
          [buffer.data base64EncodedStringWithOptions:0]];
  } else {
    js = [NSString stringWithFormat:@"var channel = window._WKWebViewWebRTCShim.channels['%@']; if (channel) { var handler = channel.onmessage; handler && handler({ data: '%@' }) };",
          channel.jsid,
          [[NSString alloc] initWithData:buffer.data encoding:NSUTF8StringEncoding]];
  }

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCDataChannel_onmessage: %ld", (unsigned long)buffer.data.length);
#endif

  [webView evaluateJavaScript:js completionHandler:nil];
}

#pragma mark RTCSessionDescription binding

- (void)RTCSessionDescription_new:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCSessionDescription_new: %@", params);
#endif

  NSString *jsid = params[@"id"];
  NSString *type = params[@"data"][@"type"];
  NSString *sdp = params[@"data"][@"sdp"];

  RTCSessionDescription *description = [[RTCSessionDescription alloc] initWithType:type
                                                                               sdp:sdp];

  description.jsid = jsid;
  descriptions[jsid] = description;
}

#pragma mark RTCIceCandidate bindings

- (void)RTCIceCandidate_new:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCIceCandidate_new: %@", params);
#endif

  NSString *jsid = params[@"id"];
  NSString *mid = params[@"data"][@"sdpMid"];
  NSString *sdp = params[@"data"][@"candidate"];
  NSInteger mLineIndex = [params[@"data"][@"sdpMLineIndex"] integerValue];

  RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:mid
                                                              index:mLineIndex
                                                                sdp:sdp];

  candidate.jsid = jsid;
  candidates[jsid] = candidate;
}

#pragma mark RTCDataChannel bindings

- (void)RTCDataChannel_send:(NSDictionary *)params {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:params[@"data"] options:0];
  RTCDataChannel *channel = channels[params[@"id"]];
  BOOL isBinary = [params[@"binary"] boolValue];
  RTCDataBuffer *buffer = [[RTCDataBuffer alloc] initWithData:data isBinary:isBinary];

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
NSLog(@"RTCDataChannel_send: %ld", (unsigned long)buffer.data.length);
#endif

  [channel sendData:buffer];
}

- (void)RTCDataChannel_close:(NSDictionary *)params {

#ifdef WKWEBVIEW_WEBRTC_SHIM_DEBUG
  NSLog(@"RTCDataChannel_close: %@", params);
#endif

  NSString *jsid = params[@"id"];
  RTCDataChannel *channel = channels[jsid];
  channel.delegate = nil;
  [channel close];
  [channels removeObjectForKey:jsid];
}

#pragma mark Helpers

- (NSString*)genUniqueId:(NSDictionary *)lookup {
  NSString *uid = [self genId];
  while ([lookup objectForKey:uid]) {
    uid = [self genId];
  }
  return uid;
}

- (NSString*)genId {
  NSMutableString* string = [NSMutableString stringWithCapacity:16];
  for (int i = 0; i < 16; i++) {
    [string appendFormat:@"%C", (unichar)('a' + arc4random_uniform(25))];
  }
  return string;
}

- (NSString*)escapeForJS:(NSString*)string {
  NSString* jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@[string] options:0 error:nil] encoding:NSUTF8StringEncoding];
  NSString* escapedString = [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
  return escapedString;
}

@end
