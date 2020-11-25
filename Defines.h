//
//
//
//
//
//
//

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
