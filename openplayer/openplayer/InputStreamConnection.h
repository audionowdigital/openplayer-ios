//
//  InputStreamConnection.h
//  openplayer
//
//  Created by Florin Moisa on 24/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InputStreamConnection : NSObject
{
    NSURL *sourceUrl;
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
}

-(id)initWithUrl:(NSURL *)url;
-(long)readData:(uint8_t *)buffer maxLength:(NSUInteger) length;

@end
