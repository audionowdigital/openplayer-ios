//
//  CircularBuffer.h
//  openplayer
//
//  Created by Radu Motisan on 16/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_CIRCULAR_SIZE 1024*1024

@interface Node : NSObject
{
    short val;
    Node *next;
}
@end

@interface CircularBuffer  {
    @public Node *first, *last, *read, *write;
}

- (id)init;
- (void)deinit;
- (void)push:(short *)buf amount:(int)amount;
// we can optimize this by seeing where we are in regards to the original list "last" elem.
- (int)checkFilled;
- (int)checkFillPercent;
// populate given buffer and return number of elements actually written
- (int)pull:(short *)buf amount:(int)amount;

@end