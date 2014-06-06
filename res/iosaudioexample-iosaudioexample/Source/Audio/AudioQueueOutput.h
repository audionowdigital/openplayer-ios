//
//  AudioQueueOutput.h
//  IosAudioExample
//
//  Created by Pete Goodliffe on 17/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <CoreAudio/CoreAudioTypes.h>
#include <AudioToolbox/AudioQueue.h>
#include <AudioUnit/AudioUnit.h>

@protocol AudioProducer;

enum { AudioQueuOutputNumberBuffers = 3 };

@interface AudioQueueOutput : NSObject
{
    id<AudioProducer> producer;

    AudioStreamBasicDescription   dataFormat;
    AudioQueueRef                 queue;
    AudioQueueBufferRef           buffers[AudioQueuOutputNumberBuffers];
    UInt32                        bufferByteSize;
}

- (id) initWithProducer:(id<AudioProducer>)producer;

@end
