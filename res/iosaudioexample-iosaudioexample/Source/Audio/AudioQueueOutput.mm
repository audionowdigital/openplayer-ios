//
//  AudioQueueOutput.m
//  IosAudioExample
//
//  Created by Pete Goodliffe on 17/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AudioQueueOutput.h"
#import "Audio.h"
#import "AudioProducer.h"

#define FRAMES_PER_BUFFER (SAMPLE_RATE/5)

static void audioQueueCallback(void *inUserData, AudioQueueRef inAQ,  AudioQueueBufferRef inCompleteAQBuffer);

@interface AudioQueueOutput ()
- (void) start;
- (void) stop;
- (void) audioQueueCallback:(AudioQueueRef)aq  buffer:(AudioQueueBufferRef)completeAQBuffer;
@end

//==============================================================================

@implementation AudioQueueOutput

- (id) initWithProducer:(id<AudioProducer>)newProducer
{
    if ((self = [super init]))
    {
        producer = newProducer;
        producer.sampleRate = SAMPLE_RATE;
        [self start];
    }
    return self;
}

- (void) dealloc
{
    [self stop];
    [super dealloc];
}

- (void) start
{
    bufferByteSize = FRAMES_PER_BUFFER*NUM_CHANNELS*sizeof(Sample);

    FillOutASBDForLPCM(dataFormat,
                       SAMPLE_RATE,      // Float64 inSampleRate,
                       NUM_CHANNELS,     // UInt32 inChannelsPerFrame,
                       sizeof(Sample)*8, // UInt32 inValidBitsPerChannel,
                       sizeof(Sample)*8, // UInt32 inTotalBitsPerChannel,
                       false,            // bool inIsFloat,
                       false,            // bool inIsBigEndian,
                       false             // bool inIsNonInterleaved = false
                       );

    OSStatus err =
    AudioQueueNewOutput(&dataFormat,
                        &audioQueueCallback,
                        self,
                        NULL,//CFRunLoopGetCurrent(), NULL means "an internal audio queue thread"
                        kCFRunLoopCommonModes,
                        0,
                        &queue);

    if (err)
    {
        ERROR_HERE(err);
        return;
    }

    // "Prime the pump" - fill and enqueue the first batch of buffers before we start
    for (unsigned i = 0; i < AudioQueuOutputNumberBuffers; ++i)
    {
        AudioQueueAllocateBuffer(queue, bufferByteSize, &buffers[i]);
        [self audioQueueCallback:queue  buffer:buffers[i]];

    }

    // Here, you can set up any audio queue state prior to starting playback
    //Float32 gain = 1.0;
    //AudioQueueSetParameter(queue, kAudioQueueParam_Volume, gain);

    // Now we're ready to start the audio queue
    err = AudioQueueStart(queue, NULL);
    ERROR_HERE(err);
}

- (void) stop
{
    OSStatus err = AudioQueueStop(queue, 0);
    ERROR_HERE(err);

	err = AudioQueueDispose(queue, true);
    ERROR_HERE(err);
}

- (void) audioQueueCallback:(AudioQueueRef)aq  buffer:(AudioQueueBufferRef)buffer
{
    const int       numberOfFrames  = FRAMES_PER_BUFFER;
    const int       numberOfSamples = numberOfFrames * NUM_CHANNELS;
    Sample * const  samples         = (Sample*)buffer->mAudioData;

    [producer produceSamples:samples size:numberOfSamples];

    buffer->mAudioDataByteSize = bufferByteSize;
    OSStatus err = AudioQueueEnqueueBuffer(queue, buffer, 0 /*CBR*/, 0 /*non compressed*/);
    ERROR_HERE(err);
}

void audioQueueCallback(void *inUserData, AudioQueueRef inAQ,  AudioQueueBufferRef inCompleteAQBuffer)
{
    AudioQueueOutput *self = (AudioQueueOutput*)inUserData;
    [self audioQueueCallback:inAQ buffer:inCompleteAQBuffer];
}

@end


