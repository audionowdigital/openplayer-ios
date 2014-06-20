//
//  StreamConnection.h
//  Open Player
//
//  Created by Catalin BORA on 29/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StreamConnection : NSObject <NSURLConnectionDelegate>
{
    BOOL _isPaused;
    NSURL *streamUrl;
}

@property long long podcastSize;
@property BOOL connectionTerminated;
@property (nonatomic,strong) NSError *connectionError;

-(id)initWithURL:(NSURL *)url error:(NSError **)error;
-(NSData *)readAllBytesWithError:(NSError **)error;
-(NSData *)readBytesForLength:(NSUInteger)length error:(NSError **)error;
-(BOOL)seekToPosition:(NSUInteger)position error:(NSError **)error;
-(void)stopStream;
-(void)pauseConnection;
-(void)resumeConnection;
@end
