//
//  WKWebViewWebRTCShimJavaScriptID.h
//  CommonTater
//
//  Created by Jesse Tane on 5/12/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#ifndef WKWebViewWebRTCShimJavaScriptID_h
#define WKWebViewWebRTCShimJavaScriptID_h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "RTCPeerConnection.h"
#import "RTCSessionDescription.h"
#import "RTCIceCandidate.h"
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

#endif
