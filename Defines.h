//
//  Defines.h
//
//  Copyright (c) 2020 NetworkSniffer (https://github.com/evilpenguin/NetworkSniffer
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

#ifndef Defines_h
#define Defines_h

#import <Foundation/Foundation.h>
#import <syslog.h>

// Weakify and Strongify
#define weakify(var) \
    __weak __typeof(var) KPWeak_##var = var

#define strongify(var) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    __strong __typeof(var) var = KPWeak_##var \
    _Pragma("clang diagnostic pop")

// Logging

#ifdef DEBUG
    #define DLog(FORMAT, ...) syslog(LOG_ERR, "+[NetworkSniffer] %s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
    #define HLog(bytes, length) \
        NSMutableString *LogString_##string = [NSMutableString string]; \
        for (int i = 0; i < length; i++) [LogString_##string appendFormat:@"%02hhX", bytes[i]]; \
        syslog(LOG_ERR, "+[NetworkSniffer] %s", LogString_##string.UTF8String)
#else 
    #define DLog(...) (void)0
    #define HLog(...) (void)0
#endif

#endif /* Defines_h */
