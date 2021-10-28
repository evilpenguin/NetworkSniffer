//
//  Tweak.xm
//
//  Copyright (c) 2021 NetworkSniffer (https://github.com/evilpenguin/NetworkSniffer
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NSProtocol.h"
@import ObjectiveC.runtime;

@interface WKBrowsingContextController : NSObject
+ (void) registerSchemeForCustomProtocol:(NSString *)protocol;
@end

NSArray<Class> *_protocols(NSArray<Class> *classes) {
    NSMutableArray *protocolClasses = [classes mutableCopy];

    if (![protocolClasses containsObject:NSProtocol.class]) {
        [protocolClasses addObject:NSProtocol.class];
    }

    return protocolClasses.copy;
}

%hook __NSCFURLSessionConfiguration
 
- (NSArray<Class> *) protocolClasses {
    return _protocols(%orig);
}

%end

%hook NSURLSessionConfiguration
 
- (NSArray<Class> *) protocolClasses {
    return _protocols(%orig);
}

%end

%hook NSURLProtocol

+ (void) unregisterClass:(Class)protocolClass {
    if (protocolClass != NSProtocol.class) {
        %orig;
    }
}

%end

%ctor {
    DLog(@"Starting");

    // Add WKWebView 
    Class WKBrowsingContextController_class = objc_getClass("WKBrowsingContextController");
    [WKBrowsingContextController_class registerSchemeForCustomProtocol:@"http"];
    [WKBrowsingContextController_class registerSchemeForCustomProtocol:@"https"];

    // Register NSProtocol
    [NSURLProtocol registerClass:NSProtocol.class];
}
