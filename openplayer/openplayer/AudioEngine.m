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

void AudioCallback (void *inUserData,
                    AudioQueueRef inAQ,
                    AudioQueueBufferRef inBuffer);

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
        
        //    self.streamFormat = localStreamFormat
        //playerThread
        // New output queue ---- PLAYBACK ----
        OSStatus status = AudioQueueNewOutput (&localStreamFormat,AudioCallback,
                                               (__bridge void*)self,
                                               CFRunLoopGetMain(),
                                               kCFRunLoopCommonModes,
                                               0,
                                               &mQueue);
        
        NSAssert(status == noErr, @"Audio queue creation was successful.");
        
        // do i really need this ??
        AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0);
        
        // init buffer
        self.buffer = [[NSMutableData  alloc] init];
        
        // calculate buffer size
        self.internalBufferSize = 1920;
        
        // set the 3 internal audio buffers
        for(int i = 0; i < BUFFERS_COUNT; ++i)
        {
            status = AudioQueueAllocateBuffer(mQueue, self.internalBufferSize, &mBuffers[i]);
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
    
    for(int i = 0; i < BUFFERS_COUNT; ++i)
    {
        [self readBuffer:mBuffers[i]];
    }
    
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
    
    // fill the buffer with new bytes
    
    //    typedef struct AudioQueueBuffer {
    //        const UInt32   mAudioDataBytesCapacity;     // max size of buffer
    //        void *const    mAudioData;                  // pointer to a data aereia
    //        UInt32         mAudioDataByteSize;          // length of the data in mAudioData
    //        void           *mUserData;
    //    } AudioQueueBuffer;
    //    typedef AudioQueueBuffer *AudioQueueBufferRef;
    
    // the external data has less data
    if (buffer->mAudioDataBytesCapacity > self.buffer.length) {
        // set the buffer length
        buffer->mAudioDataByteSize = self.buffer.length;
        
        // get a pointer to the stream buffer
        short *streamPointer = buffer->mAudioData;
        // assign streamPointer
        streamPointer = (short *)[self.buffer bytes];
        
        // empty the internal buffer
        self.buffer.length = 0;
        
    } else {
        // 1 get a part of self.buffer maxSize mAudioDataBytesCapacity
        // and write the mAudioData as above
        buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
        
        // define a buffer
        short *localBuffer = malloc( sizeof(short) * ( buffer->mAudioDataByteSize + 1 ) );
        // get a pointer to the stream buffer
        short *streamPointer = buffer->mAudioData;
        // assign localBuffer
        [self.buffer getBytes:localBuffer length:buffer->mAudioDataByteSize];
        streamPointer = localBuffer;

        //2 remover that part of self.buffer
        self.buffer = [[self.buffer subdataWithRange:NSMakeRange(buffer->mAudioDataByteSize,self.buffer.length -  buffer->mAudioDataByteSize)] mutableCopy];
    }
    
    // write the buffers
    OSStatus status = AudioQueueEnqueueBuffer(mQueue, buffer, 0, 0);
    if(status != noErr)
    {
        NSLog(@"Error: %s status=%d", __PRETTY_FUNCTION__, (int)status);
    }
}

// MARK: - Static Callbacks
// AudioQueue output queue callback.
void AudioCallback (void *inUserData,
                    AudioQueueRef inAQ,
                    AudioQueueBufferRef inBuffer) {
    
    NSLog(@" --- audio player buffer empty calback");
    AudioEngine *engine = (__bridge AudioEngine*) inUserData;
    [engine readBuffer:inBuffer];
}

@end
