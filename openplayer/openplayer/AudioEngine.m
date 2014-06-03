//
//  AudioEngine.m
//  Open Player
//
//  Created by Catalin BORA on 03/06/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "AudioEngine.h"

#define BUFFERS_COUNT 3
@interface AudioEngine()
{
@private
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[BUFFERS_COUNT];
}
@end

@implementation AudioEngine

// MARK: - Static Callbacks
// AudioQueue output queue callback.
void AudioEngineOutputBufferCallback (void *inUserData,
                                      AudioQueueRef inAQ,
                                      AudioQueueBufferRef inBuffer) {
    
    AudioEngine *engine = (__bridge AudioEngine*) inUserData;
    [engine readBuffer:inBuffer];
}

-(id)initWithSampleRate:(int)sampleRate channels:(int)channels error:(NSError **)error{
    
    self = [super init];
    if( self )
    {
        
        // Set up stream format fields
        AudioStreamBasicDescription localStreamFormat;
        localStreamFormat.mSampleRate = sampleRate;
        localStreamFormat.mFormatID = kAudioFormatLinearPCM;
        localStreamFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        localStreamFormat.mChannelsPerFrame = 2;
        localStreamFormat.mBitsPerChannel = localStreamFormat.mChannelsPerFrame *8;
        localStreamFormat.mBytesPerPacket = 2 * localStreamFormat.mChannelsPerFrame;
        localStreamFormat.mBytesPerFrame = 2 * localStreamFormat.mChannelsPerFrame;
        localStreamFormat.mFramesPerPacket = 1;
        localStreamFormat.mReserved = 0;
        
        //    self.streamFormat = localStreamFormat;
        
        // New output queue ---- PLAYBACK ----
        OSStatus status = AudioQueueNewOutput (&localStreamFormat,AudioEngineOutputBufferCallback,
                                               (__bridge void*)self,
                                               CFRunLoopGetCurrent(),
                                               kCFRunLoopCommonModes,
                                               0,
                                               &mQueue);
        
        NSAssert(status == noErr, @"Audio queue creation was successful.");
        
        // do i really need this ??
        AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0);
        
        // set the 3 internal audio buffers
        for(int i = 0; i < BUFFERS_COUNT; ++i)
        {
            UInt32 bufferSize = 128 * 1024;
            status = AudioQueueAllocateBuffer(mQueue, bufferSize, &mBuffers[i]);
            if(status != noErr)
            {
                if(*error)
                {
                    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
                }
                AudioQueueDispose(mQueue, true);
                mQueue = 0;
                return nil;
            }
            
        }
    }
    
    return self;
}

-(BOOL)play{
    //start play
    OSStatus osStatus = AudioQueueStart(mQueue, NULL);
    NSAssert(osStatus == noErr, @"AudioQueueStart failed");
    return (osStatus == noErr);
}

-(BOOL)stop{
    // stop play
    OSStatus osStatus = AudioQueueStop(mQueue, YES);
    NSAssert(osStatus == noErr, @"AudioQueueStop failed");
    return (osStatus == noErr);
}

- (void)readBuffer:(AudioQueueBufferRef)buffer{
    
    //TODO: fill the buffer with new bytes
    
//    typedef struct AudioQueueBuffer {
//        const UInt32   mAudioDataBytesCapacity;
//        void *const    mAudioData;
//        UInt32         mAudioDataByteSize;
//        void           *mUserData;
//    } AudioQueueBuffer;
//    typedef AudioQueueBuffer *AudioQueueBufferRef;
    
    //(char*)buffer->mAudioData
    //buffer->mAudioDataBytesCapacity = (int) 0;
    
    // write the buffers
    OSStatus status = AudioQueueEnqueueBuffer(mQueue, buffer, 0, 0);
    if(status != noErr)
    {
        NSLog(@"Error: %s status=%d", __PRETTY_FUNCTION__, (int)status);
    }
}

@end
