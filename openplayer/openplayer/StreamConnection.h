//
//  StreamConnection.h
//  Open Player
//
//  Created by Catalin BORA on 29/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StreamConnection : NSObject

@property long long podcastSize;

-(id)initWithURL:(NSURL *)url error:(NSError **)error;
-(NSData *)readAllBytesWithError:(NSError **)error;
-(NSData *)readBytesForLength:(NSUInteger)length error:(NSError **)error;
-(void)stopStream;
@end
