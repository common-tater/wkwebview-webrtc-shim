//
//  wkwebview-webrtc-polyfill.m
//  webrtc-webview-ios
//
//  Created by Jesse Tane on 3/16/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#import "wkwebview-webrtc-polyfill.h"

#pragma mark jsid

// add jsid to RTCPeerConnection
@implementation RTCPeerConnection (JavaScript)
@dynamic jsid;
- (void)setJsid:(NSString *)_jsid {
  objc_setAssociatedObject(self, @selector(jsid), _jsid, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (id)jsid {
  return objc_getAssociatedObject(self, @selector(jsid));
}
@end

// add jsid to RTCSessionDescription
@implementation RTCSessionDescription (JavaScript)
@dynamic jsid;
- (void)setJsid:(NSString *)_jsid {
  objc_setAssociatedObject(self, @selector(jsid), _jsid, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (id)jsid {
  return objc_getAssociatedObject(self, @selector(jsid));
}
@end

// add jsid to RTCICECandidate
@implementation RTCICECandidate (JavaScript)
@dynamic jsid;
- (void)setJsid:(NSString *)_jsid {
  objc_setAssociatedObject(self, @selector(jsid), _jsid, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (id)jsid {
  return objc_getAssociatedObject(self, @selector(jsid));
}
@end

// add jsid to RTCDataChannel
@implementation RTCDataChannel (JavaScript)
@dynamic jsid;
- (void)setJsid:(NSString *)_jsid {
  objc_setAssociatedObject(self, @selector(jsid), _jsid, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (id)jsid {
  return objc_getAssociatedObject(self, @selector(jsid));
}
@end

#pragma mark JSSDCallbackWrapper

@implementation JSSDCallbackWrapper

- (id)initWithPolyfill:(WKWebViewWebRTCPolyfill*)fill
             operation:(NSString*)name
             onSuccess:(NSString*)success
               onError:(NSString*)error {
  if (self = [super init]) {
    polyfill = fill;
    operationName = name;
    onSuccess = success;
    onError = error;
  }
  return self;
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error {
  NSString *js = nil;
  
  if (error) {
    js = [NSString stringWithFormat:@"window._WKWebViewWebRTCPolyfill.callbacks['%@'](new Error('%@'));", onError, [error localizedDescription]];
  } else {
    NSString *sdpid = [polyfill genUniqueId:polyfill.descriptions];
    NSString *propertyName = nil;
    
    if ([operationName isEqualToString:@"createOffer"]) {
      propertyName = @"offer";
    } else if ([operationName isEqualToString:@"createAnswer"]) {
      propertyName = @"answer";
    }

    sdp.jsid = sdpid;
    polyfill.descriptions[sdpid] = sdp;

    js = [NSString stringWithFormat:@"var %@ = new RTCSessionDescription({ type: '%@', sdp: '%@' }, '%@'); window._WKWebViewWebRTCPolyfill.callbacks['%@'](%@);",
            propertyName,
            sdp.type,
            [polyfill escapeForJS:sdp.description],
            sdpid,
            onSuccess,
            propertyName];
  }

  [polyfill.webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {
  NSString *js = nil;
  
  if (error) {
    js = [NSString stringWithFormat:@"window._WKWebViewWebRTCPolyfill.callbacks['%@'](new Error('%@'));", onError, [error localizedDescription]];
  } else {
    RTCSessionDescription *sdp = nil;
    NSString *sdpid = [polyfill genUniqueId:polyfill.descriptions];
    NSString *propertyName = nil;

    if ([operationName isEqualToString:@"setLocalDescription"]) {
      propertyName = @"localDescription";
      sdp = peerConnection.localDescription;
    } else if ([operationName isEqualToString:@"setRemoteDescription"]) {
      propertyName = @"remoteDescription";
      sdp = peerConnection.remoteDescription;
    }
    
    sdp.jsid = sdpid;
    polyfill.descriptions[sdpid] = sdp;

    js = [NSString stringWithFormat:@"window._WKWebViewWebRTCPolyfill.connections['%@'].%@ = new RTCSessionDescription({ type: '%@', sdp: '%@' }, '%@'); window._WKWebViewWebRTCPolyfill.callbacks['%@']();",
            peerConnection.jsid,
            propertyName,
            sdp.type,
            [polyfill escapeForJS:sdp.description],
            sdpid,
            onSuccess];
  }
  
  [polyfill.webView evaluateJavaScript:js completionHandler:nil];
}

@end

#pragma mark WKWebViewWebRTCPolyfill

@implementation WKWebViewWebRTCPolyfill

@synthesize webView,
            connections,
            descriptions,
            candidates,
            channels;

- (id)initWithWebView:(WKWebView*)view
     contentController:(WKUserContentController *)controller {
  if (self = [super init]) {
    NSString * path = [[NSBundle mainBundle].resourcePath stringByAppendingString:@"/wkwebview-webrtc-polyfill.js"];
    NSString * bindingJs = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    WKUserScript * script = [[WKUserScript alloc] initWithSource:bindingJs injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:true];
    [controller addUserScript:script];

    methods = @[
      @"RTCPeerConnection_new",
      @"RTCPeerConnection_setRemoteDescription",
      @"RTCPeerConnection_setLocalDescription",
      @"RTCPeerConnection_createOffer",
      @"RTCPeerConnection_createAnswer",
      @"RTCPeerConnection_addIceCandidate",
      @"RTCPeerConnection_createDataChannel",
      @"RTCSessionDescription_new",
      @"RTCIceCandidate_new",
      @"RTCDataChannel_send"
    ];

    for (NSString *method in methods) {
      [controller addScriptMessageHandler:self name:method];
    }

    [RTCPeerConnectionFactory initializeSSL];
    factory = [[RTCPeerConnectionFactory alloc] init];

    webView = view;
    connections = [[NSMutableDictionary alloc] init];
    descriptions = [[NSMutableDictionary alloc] init];
    candidates = [[NSMutableDictionary alloc] init];
    channels = [[NSMutableDictionary alloc] init];
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

  if (name == nil) {
    NSLog(@"unrecognized method");
    return;
  }

  SEL selector = NSSelectorFromString(name);
  IMP imp = [self methodForSelector:selector];
  void (*func)(id, SEL, NSDictionary *) = (void *)imp;
  func(self, selector, params);
}

- (RTCMediaConstraints*)defaultConstraints {
  return [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil
                                               optionalConstraints:nil];
}

#pragma mark RTCPeerConnection binding

- (void)RTCPeerConnection_new:(NSDictionary *)params {
  NSString *jsid = params[@"id"];
  NSArray *iceServersToParse = params[@"iceServers"];
  NSMutableArray *iceServers = [[NSMutableArray alloc] init];

  for (NSString *url in iceServersToParse) {
    RTCICEServer *iceServer = [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:@"stun:23.21.150.121"]
                                                       username:@""
                                                       password:@""];
    [iceServers addObject:iceServer];
  }

  RTCPeerConnection * connection = [factory peerConnectionWithICEServers:iceServers
                                                             constraints:[self defaultConstraints]
                                                                delegate:self];
  
  connection.jsid = jsid;
  connections[jsid] = connection;
}

- (void)RTCPeerConnection_createOffer:(NSDictionary *)params {
  RTCPeerConnection *connection = connections[params[@"id"]];
  JSSDCallbackWrapper *wrapper = [[JSSDCallbackWrapper alloc] initWithPolyfill:self
                                                                     operation:@"createOffer"
                                                                     onSuccess:params[@"onsuccess"]
                                                                       onError:params[@"onerror"]];
  
  [connection createOfferWithDelegate:wrapper constraints:[self defaultConstraints]];
}

- (void)RTCPeerConnection_createAnswer:(NSDictionary *)params {
  RTCPeerConnection *connection = connections[params[@"id"]];
  JSSDCallbackWrapper *wrapper = [[JSSDCallbackWrapper alloc] initWithPolyfill:self
                                                                     operation:@"createAnswer"
                                                                     onSuccess:params[@"onsuccess"]
                                                                       onError:params[@"onerror"]];

  [connection createAnswerWithDelegate:wrapper constraints:[self defaultConstraints]];
}

- (void)RTCPeerConnection_setLocalDescription:(NSDictionary *)params {
  RTCPeerConnection *connection = connections[params[@"id"]];
  RTCSessionDescription *description = descriptions[params[@"description"]];
  JSSDCallbackWrapper *wrapper = [[JSSDCallbackWrapper alloc] initWithPolyfill:self
                                                                     operation:@"setLocalDescription"
                                                                     onSuccess:params[@"onsuccess"]
                                                                       onError:params[@"onerror"]];
  
  [connection setLocalDescriptionWithDelegate:wrapper sessionDescription:description];
}

- (void)RTCPeerConnection_setRemoteDescription:(NSDictionary *)params {
  RTCPeerConnection *connection = connections[params[@"id"]];
  RTCSessionDescription *description = descriptions[params[@"description"]];
  JSSDCallbackWrapper *wrapper = [[JSSDCallbackWrapper alloc] initWithPolyfill:self
                                                                     operation:@"setRemoteDescription"
                                                                     onSuccess:params[@"onsuccess"]
                                                                       onError:params[@"onerror"]];

  [connection setRemoteDescriptionWithDelegate:wrapper sessionDescription:description];
}

- (void)RTCPeerConnection_addIceCandidate:(NSDictionary *)params {
  RTCPeerConnection *connection = connections[params[@"id"]];
  RTCICECandidate *candidate = candidates[params[@"candidate"]];
  [connection addICECandidate:candidate];

  NSString *js = [NSString stringWithFormat:@"window._WKWebViewWebRTCPolyfill.callbacks['%@']();", params[@"onsuccess"]];
  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)RTCPeerConnection_createDataChannel:(NSDictionary *)params {
  RTCPeerConnection *connection = connections[params[@"id"]];
  RTCDataChannel *channel = [connection createDataChannelWithLabel:params[@"label"] config:params[@"optional"]];

  NSString *jsid = params[@"channel"];
  channels[jsid] = channel;
  channel.jsid = jsid;
  channel.delegate = self;
}

#pragma mark RTCPeerConnectionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged {
  NSString *js = [NSString stringWithFormat:@"var handler = window._WKWebViewWebRTCPolyfill.connections['%@'].onsignalingstatechange; handler && handler();", peerConnection.jsid];

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream {
  NSString *js = [NSString stringWithFormat:@"var handler = window._WKWebViewWebRTCPolyfill.connections['%@'].onaddstream; handler && handler(new Error('ENOTIMPLEMENTED'));", peerConnection.jsid];
  
  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream {
  NSString *js = [NSString stringWithFormat:@"var handler = window._WKWebViewWebRTCPolyfill.connections['%@'].onremovestream; handler && handler(new Error('ENOTIMPLEMENTED'));", peerConnection.jsid];
  
  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {
  NSString *js = [NSString stringWithFormat:@"var handler = window._WKWebViewWebRTCPolyfill.connections['%@'].onnegotiationneeded; handler && handler(new Error('ENOTIMPLEMENTED'));", peerConnection.jsid];
  
  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState {
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
  }
  
  NSString *js = [NSString stringWithFormat:@"var id = '%@'; window._WKWebViewWebRTCPolyfill.connections[id].iceConnectionState = '%@'; var handler = window._WKWebViewWebRTCPolyfill.connections[id].oniceconnectionstatechange; handler && handler();", peerConnection.jsid, state];
  
  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState {
  NSString *state;
  
  switch (newState) {
    case RTCICEGatheringNew:
      state = @"new";
      break;
    case RTCICEGatheringGathering:
      state = @"gathering";
      break;
    case RTCICEGatheringComplete:
      state = @"complete";
      break;
  }
  
  NSString *js = [NSString stringWithFormat:@"var id = '%@'; window._WKWebViewWebRTCPolyfill.connections[id].iceGatheringState = '%@'; var handler = window._WKWebViewWebRTCPolyfill.connections[id].onicegatheringstatechange; handler && handler();", peerConnection.jsid, state];

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate {
  NSString *jsid = [self genUniqueId:candidates];
  candidate.jsid = jsid;
  candidates[jsid] = candidate;
  
   NSString *js = [NSString stringWithFormat:@"var candidate = new RTCIceCandidate({ sdpMid: '%@', sdpMLineIndex: '%ld', candidate: '%@' }, %@); var handler = window._WKWebViewWebRTCPolyfill.connections['%@'].onicecandidate; handler && handler({ candidate: candidate });",
     candidate.sdpMid,
     (long) candidate.sdpMLineIndex,
     [self escapeForJS:candidate.sdp],
     jsid,
     peerConnection.jsid];

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)channel {
  NSString *jsid = [self genUniqueId:channels];

  channels[jsid] = channel;
  channel.jsid = jsid;
  channel.delegate = self;

  NSString *js = [NSString stringWithFormat:@"var channel = new RTCDataChannel('%@'); var handler = window._WKWebViewWebRTCPolyfill.connections['%@'].ondatachannel; handler && handler({ channel: channel });",
    channel.jsid,
    peerConnection.jsid];

  [webView evaluateJavaScript:js completionHandler:nil];
}

#pragma mark RTCDataChannelDelegate

- (void)channelDidChangeState:(RTCDataChannel *)channel {
  NSString *event = nil;
  
  switch (channel.state) {
    case kRTCDataChannelStateOpen:
      event = @"onopen";
      break;
    case kRTCDataChannelStateClosed:
      event = @"onclose";
      break;
    default:
      break;
  }

  NSString *js = [NSString stringWithFormat:@"var handler = window._WKWebViewWebRTCPolyfill.channels[%@].%@; handler && handler();",
    channel.jsid,
    event];

  [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)channel:(RTCDataChannel *)channel didReceiveMessageWithBuffer:(RTCDataBuffer *)buffer {
  NSString *js = [NSString stringWithFormat:@"var handler = window._WKWebViewWebRTCPolyfill.channels['%@'].onmessage; handler && handler({ data: window._WKWebViewWebRTCPolyfill.base64ToBinary('%@') });",
    channel.jsid,
    [buffer.data base64EncodedStringWithOptions:0]];
  
  [webView evaluateJavaScript:js completionHandler:nil];
}

#pragma mark RTCSessionDescription binding

- (void)RTCSessionDescription_new:(NSDictionary *)params {
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
  RTCDataBuffer *buffer = [[RTCDataBuffer alloc] initWithData:data isBinary:YES];
  [channel sendData:buffer];
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
  srand48(time(0));
  double r = drand48();
  NSString *uid = [NSString stringWithFormat:@"%f", r];
  return [uid substringFromIndex:2];
}

- (NSString*)escapeForJS:(NSString*)string {
  NSString* jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@[string] options:0 error:nil] encoding:NSUTF8StringEncoding];
  NSString* escapedString = [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
  return escapedString;
}

@end
