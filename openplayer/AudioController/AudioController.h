//
//  AudioController.h
//  OpenPlayer
//
//  Created by Radu Motisan on 06/06/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

// http://www.cocoawithlove.com/2010/10/ios-tone-generator-introduction-to.html
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TPCircularBuffer.h"

#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif

#define kBufferLength 1048576

@interface AudioController : NSObject {
	AudioComponentInstance audioUnit;
    @public int _sampleRate, _channels, _bytesPerFrame;
    TPCircularBuffer circbuffer;
}

@property (readonly) AudioComponentInstance audioUnit;



- (id) initWithSampleRate:(int)sampleRate channels:(int)channels;
- (void) start;
- (void) stop;
- (void) pause;
- (int) getBufferFill;

@end


