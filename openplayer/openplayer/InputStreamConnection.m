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
        sourceUrl = url;
        
        if ([sourceUrl isFileURL]) {
            NSLog(@"Initialize stream from file url: %@", url);
        } else {
            NSLog(@"Initialize stream from network url: %@", url);
        }
        
//        dispatch_async(dispatch_queue_create("com.audionnowdigital.streamconnection", NULL), ^
//        {
//            
//            
//        });
        
    }
    return self;
}

-(BOOL)openStream:(NSStream *)stream
{
    BOOL streamOpened = NO;
    BOOL streamError = NO;
    
    [stream open];
    
    while (!streamOpened && !streamError) {
        
        NSLog(@"Stream state: %d", [stream streamStatus]);
        
        switch ([stream streamStatus]) {
            case NSStreamStatusOpen:
                streamOpened = YES;
                break;
                
            case NSStreamStatusClosed:
            case NSStreamStatusError:
                
                streamError = YES;
                break;
                
            default:
                break;
        }
        
        [NSThread sleepForTimeInterval:0.1];  // maybe we can reduce this value
    }
    
    if (streamOpened){
        return YES;
    }
    
    if (streamError) {
        return NO;
    }

    return NO;
}

- (BOOL)initSocketConnection
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)[sourceUrl host], [[sourceUrl port] longValue], &readStream, &writeStream);
    
    inputStream = (__bridge_transfer NSInputStream *)readStream;
    outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    
    if (![self openStream:outputStream]) {
        NSLog(@"Error opening output stream ! %@", [outputStream streamError]);
        return NO;
    }
    
    NSLog(@"output socket stream opened");
       
    // do a HTTP Get on the resource we want
    NSString * str = [NSString stringWithFormat:@"GET %@ HTTP/1.0\r\n\r\n", [sourceUrl path]];
    NSLog(@"Do get for: %@", str);
    const uint8_t * rawstring = (const uint8_t *)[str UTF8String];
    [outputStream write:rawstring maxLength:strlen(rawstring)];
    [outputStream close];
    
    if (![self openStream:inputStream]) {
        NSLog(@"Error opening input stream !");
        return NO;
    }
    
    NSLog(@"input socket stream opened");
    
    return YES;
    
}

- (void)initFileConnection
{
    
}

-(long)readData:(uint8_t *)buffer maxLength:(NSUInteger) length
{
    
    if (inputStream == nil) {
        if ([sourceUrl isFileURL]){
            [self initFileConnection];
        } else {
            [self initSocketConnection];
        }
    }
    
    return [inputStream read:buffer maxLength:length];
    
}


@end
