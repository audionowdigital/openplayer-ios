//
//  AudioController.m
//  OpenPlayer
//
//  Created by Radu Motisan on 06/06/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "AudioController.h"
#import <AudioToolbox/AudioToolbox.h>

#define kOutputBus 0


AudioController* iosAudio;
short *srcbuffer1 = nil, *srcbuffer2 = nil;
bool use1 = false, use2 = false;
long bufsize1, bufsize2, offset1;

void checkStatus(int ids, int status){
	if (status) {
		printf("%d Status not 0! %d\n",ids, status);
        //exit(1);
	}
}

/**
 This callback is called when the audioUnit needs new data to play through the
 speakers. If you don't have any, just don't write anything in the buffers
 */
bool dump = false;
static OSStatus playbackCallback(void *inRefCon, 
								 AudioUnitRenderActionFlags *ioActionFlags, 
								 const AudioTimeStamp *inTimeStamp, 
								 UInt32 inBusNumber, 
								 UInt32 inNumberFrames, 
								 AudioBufferList *ioData) {
    
    if (srcbuffer1!=nil && bufsize1 > 0) {
        AudioBuffer buffer = ioData->mBuffers[0]; //mono/?
        
        UInt32 size = min(inNumberFrames, bufsize1 - offset1); // dont copy more data then we have, or then
        
       
        memcpy((short *)buffer.mData, srcbuffer1 + offset1, size*2 );
        offset1 += size; // frames, not bytes, we're using shorts for a frame
        
        if (!dump && bufsize1 > 2000000) {
            NSString *file3= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/testfile6.dat"];
            FILE *f3 = fopen([file3 UTF8String], "ab");
            fwrite(srcbuffer1, 2, bufsize1, f3);
            fclose(f3);
            dump = true;
        }
        NSLog(@"buffers:%d Buffer size:%d offset:%d take:%d", ioData->mNumberBuffers, bufsize1, offset1, size);
       
    }
  
	
    return noErr;
}

@implementation AudioController

@synthesize audioUnit, tempBuffer;

- (AudioBuffer)getBuffer {
    return tempBuffer;
}

/**
 Initialize the audioUnit and allocate our own temporary buffer.
 The temporary buffer will hold the latest data coming in from the microphone,
 and will be copied to the output when this is requested.
 */
- (id) init {
    self = [super init];
    // Configure the search parameters to find the default playback output unit
    // (called the kAudioUnitSubType_RemoteIO on iOS but
    // kAudioUnitSubType_DefaultOutput on Mac OS X)
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    // Get the default playback output unit
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    NSAssert(defaultOutput, @"Can't find default output");
    
    // Create a new unit based on this that we'll use for output
    OSErr err = AudioComponentInstanceNew(defaultOutput, &audioUnit);
    NSAssert1(audioUnit, @"Error creating unit: %ld", err);
    
    // Set our tone rendering function on the unit
    AURenderCallbackStruct input;
    input.inputProc = playbackCallback;
    input.inputProcRefCon = (__bridge void *)(self);
    err = AudioUnitSetProperty(audioUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
    NSAssert1(err == noErr, @"Error setting callback: %ld", err);
    
    // Set the format to 32 bit, single channel, floating point, linear PCM
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = 48000;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags =     kAudioFormatFlagIsSignedInteger  | kAudioFormatFlagIsPacked  ;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mChannelsPerFrame = 2;
    streamFormat.mBytesPerPacket = 4;
    streamFormat.mBytesPerFrame = 4;//    mBytesPerFrame = mBitsPerChannels * mChannelsPerFrame / 8
    streamFormat.mBitsPerChannel = 16;
    err = AudioUnitSetProperty (audioUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
    
    
	
    // set preferred buffer size for simulator
    //Float32 preferredBufferSize = .0232; // in seconds
    //err = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
    

    
    NSAssert1(err == noErr, @"Error setting stream format: %ld", err);
    
    
    return self;
}

// Start the audioUnit. requested for feeding to the speakers, by use of the provided callbacks.
- (void) start {
    // Finalize parameters on the unit
    OSErr err = AudioUnitInitialize(audioUnit);
    NSAssert1(err == noErr, @"Error initializing unit: %ld", err);
    
	OSStatus status = AudioOutputUnitStart(audioUnit);
	checkStatus(6,status);
}

// Stop the audioUnit
- (void) stop {
	//OSStatus status = AudioOutputUnitStop(audioUnit);
	//checkStatus(7,status);
    
    // Tear it down in reverse
    AudioOutputUnitStop(audioUnit);
    AudioUnitUninitialize(audioUnit);
    AudioComponentInstanceDispose(audioUnit);
    audioUnit = nil;
}

/**
 Change this funtion to decide what is done with incoming
 audio data from the microphone.
 Right now we copy it to our own temporary buffer.
 */

// copy incoming audio data to temporary buffer
//	memcpy(tempBuffer.mData, bufferList->mBuffers[0].mData, bufferList->mBuffers[0].mDataByteSize);


// Clean up.
- (void) dealloc {
	//[super	dealloc];
	AudioUnitUninitialize(audioUnit);
	free(tempBuffer.mData);
}

@end
