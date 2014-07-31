//
//  InputStreamConnection.h
//  openplayer
//
//  Created by Florin Moisa on 24/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTimeout 2000   // timeout for network operations in miliseconds

@interface InputStreamConnection : NSObject
{
    NSURL *sourceUrl;
    
    NSInputStream *inputStream;         // this is what we use mostly, to read data from the server
    NSOutputStream *outputStream;       // only for HTTP GET
    
    NSMutableDictionary *returnHeaders;
    
    long srcSize;                       // source length in bytes if none . If invalid or unavailable, this is -1
    long readoffset;
    NSString *rangeUnit;
    
    BOOL isHTTPHeaderAvailable;         // set to true when the HTTP header has been downloaded successfully
    
    BOOL isSourceInited;                // set to true on init, and to false on close
    BOOL isSkipAvailable;
}

-(id)initWithUrl:(NSURL *)url;
-(long)readData:(uint8_t *)buffer maxLength:(NSUInteger) length;
-(long)getReadOffset;
-(long)getSourceLength;
-(void)closeStream;
-(BOOL)seekTo:(float)percent;

@end
