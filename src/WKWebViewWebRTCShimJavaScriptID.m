//
//  WKWebViewWebRTCShimJavaScriptID.m
//  CommonTater
//
//  Created by Jesse Tane on 5/12/15.
//  Copyright (c) 2015 Common Tater. All rights reserved.
//

#import "WKWebViewWebRTCShimJavaScriptID.h"

//
@implementation RTCPeerConnection (JavaScript)
@dynamic jsid;
- (void)setJsid:(NSString *)_jsid {
    objc_setAssociatedObject(self, @selector(jsid), _jsid, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (id)jsid {
    return objc_getAssociatedObject(self, @selector(jsid));
}
@end

//
@implementation RTCSessionDescription (JavaScript)
@dynamic jsid;
- (void)setJsid:(NSString *)_jsid {
    objc_setAssociatedObject(self, @selector(jsid), _jsid, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (id)jsid {
    return objc_getAssociatedObject(self, @selector(jsid));
}
@end

//
@implementation RTCICECandidate (JavaScript)
@dynamic jsid;
- (void)setJsid:(NSString *)_jsid {
    objc_setAssociatedObject(self, @selector(jsid), _jsid, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (id)jsid {
    return objc_getAssociatedObject(self, @selector(jsid));
}
@end

//
@implementation RTCDataChannel (JavaScript)
@dynamic jsid;
- (void)setJsid:(NSString *)_jsid {
    objc_setAssociatedObject(self, @selector(jsid), _jsid, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (id)jsid {
    return objc_getAssociatedObject(self, @selector(jsid));
}
@end
