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

#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif


@interface AudioController : NSObject {
	AudioComponentInstance audioUnit;
	AudioBuffer tempBuffer; // this will hold the latest data from the microphone
    
    
}

@property (readonly) AudioComponentInstance audioUnit;
@property AudioBuffer tempBuffer;



- (id) init;
- (void) start;
- (void) stop;
- (void) processAudio: (AudioBufferList*) bufferList;
- (AudioBuffer) getBuffer;

@end


// setup a global iosAudio variable, accessible everywhere
extern AudioController* iosAudio;

extern short *srcbuffer;
extern long bufsize;
extern long bufreadpos;