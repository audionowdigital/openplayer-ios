//
//  AudioController.h
//  OpenPlayer
//
//  Created by Radu Motisan on 06/06/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TPCircularBuffer.h"

#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif

/* The buffer size combined with the threshold for buffer-fill, will greatly affect the playback
 When choosing this value, we need to think of the download rate, and the playback rate */
#define kBufferLength 256000 //256KB buffer

@interface AudioController : NSObject {
	AudioComponentInstance audioUnit;
    //@public int _sampleRate, _channels, _bytesPerFrame; // currently not used
    @public TPCircularBuffer circbuffer;
}
@property (readonly) AudioComponentInstance audioUnit;

/* Initialize the audioUnit and allocate our own temporary buffer.
 The temporary buffer will hold the latest data coming in from the microphone,
 and will be copied to the output when this is requested. */
- (id) initWithSampleRate:(int)sampleRate channels:(int)channels;
/* Start the audioUnit. requested for feeding to the speakers, by use of the provided callbacks. */
- (BOOL) start;
/* Stop the audioUnit */
- (void) stop;
/* Pause the audioUnit */
- (void) pause;
/* Get the buffer fill percent */
- (int) getBufferFill;
/* Empty the circular buffer - needed for seeking */
- (void) emptyBuffer;

@end


