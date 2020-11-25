//
//
//
//
//
//
//

#import "NSProtocol.h"
@import ObjectiveC.runtime;

@interface WKBrowsingContextController : NSObject
+ (void) registerSchemeForCustomProtocol:(NSString *)protocol;
@end

%ctor {
    DLog(@"Starting");

    // Add WKWebView 
    Class WKBrowsingContextController_class = objc_getClass("WKBrowsingContextController");
    [WKBrowsingContextController_class registerSchemeForCustomProtocol:@"http"];
    [WKBrowsingContextController_class registerSchemeForCustomProtocol:@"https"];

    // Register NSProtocol
    [NSURLProtocol registerClass:NSProtocol.class];
}
