//
//  InputStreamConnection.m
//  openplayer
//
//  Created by Florin Moisa on 24/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import "InputStreamConnection.h"

@implementation InputStreamConnection

-(id)initWithUrl:(NSURL *)url
{
    if (self = [super init]) {
        
        srcSize = -1;
        isHTTPHeaderAvailable = NO;
        isSourceInited = NO;
        isSkipAvailable = NO;
        sourceUrl = url;
        
        BOOL ret = YES;
        if ([sourceUrl isFileURL]) {
            NSLog(@"Initialize stream from file url: %@", url);
            ret = [self initFileConnection];
        } else {
            NSLog(@"Initialize stream from network url: %@", url);
            ret = [self initSocketConnection:0];
        }
        
        if (!ret) {
            self = nil;
        }
    }
    return self;
}

-(BOOL)openStream:(NSStream *)stream {
    [stream open];
    
    double startTime = [NSDate timeIntervalSinceReferenceDate] * 1000.0; // we want it in ms
    
    while ((long)([NSDate timeIntervalSinceReferenceDate] * 1000.0 - startTime) < kTimeout) {
        
        NSLog(@"Stream state: %d", [stream streamStatus]);
        
        switch ([stream streamStatus]) {
            case NSStreamStatusOpen:
                return YES;
                
            case NSStreamStatusClosed:
            case NSStreamStatusError:
                return NO;
                
            default: break;
        }
        
        [NSThread sleepForTimeInterval:0.1];
    }
    
    return NO;
}

- (BOOL)initSocketConnection:(long)offset
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    int port = [sourceUrl port] > 0 ? [[sourceUrl port] intValue] : 80;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)[sourceUrl host], port, &readStream, &writeStream);
    
    inputStream = (__bridge_transfer NSInputStream *)readStream;
    outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    
    if (![self openStream:outputStream]) {
        NSLog(@"Error opening output stream ! %@", [outputStream streamError]);
        return NO;
    }
    
    NSLog(@"output socket stream opened");
       
    // do a HTTP Get on the resource we want
    NSString * str = [NSString stringWithFormat:@"GET %@ HTTP/1.0\r\nHost: %@\r\nRange: bytes=%ld-\r\n\r\n",
            [sourceUrl path], [sourceUrl host], offset];
    
    NSLog(@"Do get for: %@", str);
    const uint8_t * rawstring = (const uint8_t *)[str UTF8String];
    [outputStream write:rawstring maxLength:strlen((const char *)rawstring)];
    // leave the outputstream open
    
    if (![self openStream:inputStream]) {
        NSLog(@"Error opening input stream !");
        return NO;
    }
    
    NSLog(@"input socket stream opened");
    
    // Check HTTP response code (must be 200!) and then read HTTP Header and store useful details
    NSMutableString *strHeader = [NSMutableString string];
    NSInteger result;
    int eoh = 0;
    uint8_t ch;
    while((result = [inputStream read:&ch maxLength:1]) != 0) {
        if(result > 0) {
            // add data to our string
            [strHeader appendFormat:@"%c", ch];
            // check ending condition
            if (ch == '\r' || ch == '\n') eoh ++;
            else if (eoh > 0) eoh --;
            // if we have the header ending characters, stop
            if (eoh == 4) {
                NSLog(@"HTTP Header received:%@", strHeader);
                isHTTPHeaderAvailable = YES;
                break;
            }
            // if there is no header, quit
            if (eoh > 1000) {
                NSLog(@"No HTTP Header found");
                return NO;
            }
        } else {
            NSLog(@"Error %@", [inputStream streamError]);
            return NO;
        }
    }
    // Check header data
    
    returnHeaders = [NSMutableDictionary new];
    
    NSArray *lines = [strHeader componentsSeparatedByString:@"\r\n"];
    NSArray *keyvalue;
    
    for (NSString *line in lines) {
        keyvalue = [line componentsSeparatedByString:@": "];
        if (keyvalue.count == 2) {
            [returnHeaders setObject:[keyvalue objectAtIndex:1] forKey:[keyvalue objectAtIndex:0]];
        } else {
            keyvalue = [line componentsSeparatedByString:@" "];
            if ([[keyvalue objectAtIndex:0] rangeOfString:@"HTTP"].length > 0) {
                [returnHeaders setObject:[keyvalue objectAtIndex:1] forKey:@"status"];
            }
        }
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    int httpStatus = [[formatter numberFromString:returnHeaders[@"status"]] intValue];
    
    if (httpStatus < 200 && httpStatus >= 300) {
        NSLog(@"HTTP status not OK");
        return NO;
    }
    
    // params: Get the range for skip
    rangeUnit = returnHeaders[@"Accept-Ranges"];
    // params: Get the resource size
    NSNumber * srcIntSize = [formatter numberFromString:returnHeaders[@"Content-Length"]];
    srcSize = [srcIntSize longValue];

    isSourceInited = YES;
    if (rangeUnit != NULL) isSkipAvailable = YES;
    NSLog(@"HTTP Header data: Content size:%ld Skip-Range:%@" , srcSize, rangeUnit);
    
    NSLog(@"Init flags: isHTTPHeaderAvailable:%d isSkipAvailable:%d isSourceInited:%d",
          isHTTPHeaderAvailable, isSkipAvailable, isSourceInited);
    
    return YES;
}


    
-(BOOL)seekTo:(float)percent {
    long offset = percent * srcSize;

    // allow skip only if isSourceInited is true
    
    if (offset > srcSize) return NO;
    
    NSLog(@"Seek offset:%ld", offset);
    
    if ([sourceUrl isFileURL]) {
        
        [inputStream setProperty:@(offset) forKey:NSStreamFileCurrentOffsetKey];
    } else if (isSkipAvailable) {
        // a strange limit we need to impose on seeking to the begining .
        if (offset < 512) offset = 512;
        // we should already have the header read, so we drop the current connection and simply jump away
        [self closeStream];
        // restart connection at the new offset - not all servers support this. If fails, we'll simply play the content from the start
        [self initSocketConnection:offset];
    }
    return YES;
}

- (BOOL)initFileConnection
{
    
    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[sourceUrl path] error:nil];
    if (fileAttrs != nil) {
        srcSize = fileAttrs.fileSize;
    } else {
        NSLog(@"Could not determine file size");
    }
    
    inputStream = [[NSInputStream alloc] initWithURL:sourceUrl];
    
    if (![self openStream:inputStream]) {
        NSLog(@"Error opening input stream !");
        return NO;
    }
    
    return inputStream != nil;
}

-(long)readData:(uint8_t *)buffer maxLength:(NSUInteger) length {
    // if we skip data, we might delay the read, wait if socket disconnected, but with a timeout
    double startTime = [NSDate timeIntervalSinceReferenceDate] * 1000.0; // we want it in ms
    
    while ([inputStream streamStatus] != NSStreamStatusOpen &&
           (long)([NSDate timeIntervalSinceReferenceDate] * 1000.0 - startTime) < kTimeout) {
        NSLog(@"readData wait with timeout");
        [NSThread sleepForTimeInterval:0.1];
    }
    
    // finally read the data
    return [inputStream read:buffer maxLength:length];
}

-(void)closeStream
{
    [outputStream close];
    [inputStream close];
    
    outputStream = nil;
    inputStream = nil;
    
    isSourceInited = NO;
}


@end
