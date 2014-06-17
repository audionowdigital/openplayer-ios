//
//  CircularBuffer.h
//  openplayer
//
//  Created by Radu Motisan on 16/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_CIRCULAR_SIZE 1048576 //1MB

#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif

@interface Node : NSObject
{
    //@public short val;
    //@public Node *next;
}
@property short val;
@property Node *next;
@end

@interface CircularBuffer : NSObject  {
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