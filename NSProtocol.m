//
//  NSProtocol.m
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
#import <UIKit/UIKit.h>

static NSString * const NSProtocolHandledKey = @"NSProtocolHandledKey";

@interface NSProtocol() <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) dispatch_queue_t writeQueue;
@end

@interface UIApplication()
- (NSString *) userHomeDirectory;
@end

@implementation NSProtocol

#pragma mark - NSProtocol

+ (BOOL) canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:NSProtocolHandledKey inRequest:request]) {
        return NO;
    }

    return YES;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void) startLoading {
    // Add protocol key
    NSMutableURLRequest *mutableRequest = self.request.mutableCopy;
    [self.class setProperty:@YES forKey:NSProtocolHandledKey inRequest:mutableRequest];

    // Prepare
    [self prepare];

    // Log dictionary
    NSMutableDictionary *logResultsDictionary = [NSMutableDictionary dictionary];
    logResultsDictionary[@"Date"] = [NSDateFormatter localizedStringFromDate:NSDate.date dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterFullStyle];

    // Log request to dictionary
    [self _logRequest:mutableRequest toDictionary:logResultsDictionary];

    // Send request
    weakify(self);
    [[self.session dataTaskWithRequest:mutableRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        strongify(self);

        // Finalized response
        if (error) [self.client URLProtocol:self didFailWithError:error];
        else {
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
            [self.client URLProtocol:self didLoadData:data];
            [self.client URLProtocolDidFinishLoading:self];
        }        
        
        // Log response and data to dictionary
        [self _logResponse:(NSHTTPURLResponse *)response withData:data toDictionary:logResultsDictionary];

        // Write to disk
        [self _writeDictionaryToDisk:logResultsDictionary];

    }] resume];
}

- (void) stopLoading {
    [self.session invalidateAndCancel];
    [self.operationQueue cancelAllOperations];
}

#pragma mark - Lazy

- (NSURLSession *) session {
    if (!_session) {
        NSURLSessionConfiguration *configure = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:self.operationQueue];
    }

    return _session;
}

- (NSOperationQueue *) operationQueue {
    if (!_operationQueue) _operationQueue = [[NSOperationQueue alloc] init];

    return _operationQueue;
}

- (dispatch_queue_t) writeQueue {
    if (!_writeQueue) _writeQueue = dispatch_queue_create("NetworkSnifferQueue",  DISPATCH_QUEUE_SERIAL);

    return _writeQueue;
}

#pragma mark - Private methods

- (void) prepare {
    dispatch_async(self.writeQueue, ^{
        NSString *writePath = self._writePath;

        if (![NSFileManager.defaultManager fileExistsAtPath:writePath]) {
            [NSData.data writeToFile:writePath atomically:YES];
        } 
    });
}

- (NSString *) _writePath {
    static NSString *path = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSString *userHomeDirectory = UIApplication.sharedApplication.userHomeDirectory;
        path = [userHomeDirectory stringByAppendingPathComponent:@"networksniffer.log"];
    });

    return path;
}

- (void) _logRequest:(NSURLRequest *)request toDictionary:(NSMutableDictionary *)dictionary {
    // Dictionary
    NSMutableDictionary *requestDictionary = [NSMutableDictionary dictionary];
    dictionary[@"Request"] = requestDictionary;

    // HTTPMethod
    requestDictionary[@"HTTPMethod"] = request.HTTPMethod;

    // URL
    requestDictionary[@"URL"] = request.URL.absoluteString;

    // URL
    requestDictionary[@"MainDocumentURL"] = request.mainDocumentURL.absoluteString;

    // AllHTTPHeaderFields
    requestDictionary[@"Headers"] = request.allHTTPHeaderFields;

    // CachePolicy
    requestDictionary[@"CachePolicy"] = @(request.cachePolicy);

   // HTTPBody
    NSData *body = request.HTTPBody;
    if (body.length > 0) {
        NSMutableDictionary *bodyDictionary = [NSMutableDictionary dictionary];
        bodyDictionary[@"Length"] = @(body.length);
        bodyDictionary[@"Body"] = [self _bytesToString:body];

        requestDictionary[@"HTTPBody"] = bodyDictionary;
    }

    // HTTPBodyStream
    NSInputStream *bodyStream = request.HTTPBodyStream;
    if (bodyStream) {
        // Open the body before reading
        [bodyStream open];

        //NSUInteger readBytes = 0;
        NSMutableData *bodyStreamData = [NSMutableData data];
        while (bodyStream.hasBytesAvailable) {
            uint8_t buffer_byte[1];
            //readBytes +=  [bodyStream read:buffer_byte maxLength:1];
            [bodyStreamData appendBytes:(const void *)buffer_byte length:1];
        }

        // Close the body
        [bodyStream close];

        if (bodyStreamData.length > 0) {
            NSMutableDictionary *bodyStreamDictionary = [NSMutableDictionary dictionary];
            bodyStreamDictionary[@"Length"] = @(bodyStreamData.length);
            bodyStreamDictionary[@"Body"] = [self _bytesToString:bodyStreamData];

            requestDictionary[@"HTTPBodyStream"] = bodyStreamDictionary;
        }
    }
}

- (void) _logResponse:(NSHTTPURLResponse *)response withData:(NSData *)data toDictionary:(NSMutableDictionary *)dictionary {
    // Dictionary
    NSMutableDictionary *responseDictionary = [NSMutableDictionary dictionary];
    dictionary[@"Response"] = responseDictionary;

    // Status
    responseDictionary[@"StatusCode"] = @(response.statusCode);

    // Headers
    responseDictionary[@"Headers"] = response.allHeaderFields;

    // Data
    if (data.length > 0) {
        NSMutableDictionary *bodyDictionary = [NSMutableDictionary dictionary];
        bodyDictionary[@"Length"] = @(data.length);
        bodyDictionary[@"Body"] = [self _bytesToString:data];

        responseDictionary[@"HTTPBody"] = bodyDictionary;
    }
}

- (NSString *) _bytesToString:(NSData *)data {
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) return string;

    string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if (string.length > 0) return string;

    return [self _dataToHexString:data];
}

- (NSString *) _dataToHexString:(NSData *)data {
    NSMutableString *hexString  = [NSMutableString string];

    uint8_t *bytes = (uint8_t *)data.bytes;
    for (int i = 0; i < data.length; i++) {
        [hexString appendFormat:@"%02hhX", bytes[i]];
    }

    return hexString.copy;
}

- (void) _writeDictionaryToDisk:(NSMutableDictionary *)dictionary {
    if (dictionary.count > 0) {
        dispatch_async(self.writeQueue, ^{
            NSString *logPath = self._writePath;

            DLog(@"Writing to %@", logPath);
            DLog(@"%@", dictionary);

            // Convert to JSON
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];

            // Append
            if (jsonData && !error) {
                NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:logPath];
                [handle truncateFileAtOffset:handle.seekToEndOfFile];
                [handle writeData:jsonData];
                [handle writeData:[@"\n\n" dataUsingEncoding:NSUnicodeStringEncoding]];
                [handle closeFile];
            }
        });
    }
}

@end
