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
short *srcbuffer = nil;
long bufsize;
long bufreadpos;
double lastTimeStamp;

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
static OSStatus playbackCallback(void *inRefCon, 
								 AudioUnitRenderActionFlags *ioActionFlags, 
								 const AudioTimeStamp *inTimeStamp, 
								 UInt32 inBusNumber, 
								 UInt32 inNumberFrames, 
								 AudioBufferList *ioData) {    
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    
    // log data
    if (lastTimeStamp != 0) {
        double timeSpent = [NSDate timeIntervalSinceReferenceDate] - lastTimeStamp;
        NSLog(@" audio requests: %d bytes in %f ns",(unsigned int)inNumberFrames,timeSpent);
    }
    
    lastTimeStamp = [NSDate timeIntervalSinceReferenceDate];
    
//	NSLog(@"Give me data! Buffers:%d Frames:%d", (unsigned int)ioData->mNumberBuffers, inNumberFrames);
	/*for (int i=0; i < ioData->mNumberBuffers; i++) { // in practice we will only ever have 1 buffer, since audio format is mono
		AudioBuffer bufferdest = ioData->mBuffers[i];
		
        // NSLog(@"  Buffer %d has %d channels and wants %d bytes of data.", i, buffer.mNumberChannels, buffer.mDataByteSize);
		
		UInt32 size = min(bufferdest.mDataByteSize, bufsize); // dont copy more data then we have, or then
        
        if (buffer!=nil && bufsize > 0) {
            memcpy(bufferdest.mData, buffer, size);
            //buffer.mDataByteSize = size; // indicate how much data we wrote in the buffer
            //[io sAudio getBuffer].mDataByteSize = 0;
            
            
            NSString *file= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/testfile4.dat"];
            FILE *f = fopen([file UTF8String], "ab");
            fwrite(buffer, 2, bufsize, f);
            fclose(f);
            bufsize = 0;
            
            free(buffer);
            buffer = nil;
            
        }*/
    if (srcbuffer!=nil && bufsize > 0) {
        AudioBuffer buffer = ioData->mBuffers[0]; //mono/?
        UInt32 size = min(inNumberFrames, bufsize); // dont copy more data then we have, or then
        
        UInt16 *frameBuffer = buffer.mData;
        for (int j = 0; j < inNumberFrames; j++) {
            frameBuffer[j] = srcbuffer[j];
        }
        bufsize = 0;
        
        free(srcbuffer);
        srcbuffer = nil;
    }
  
   
	// uncomment to hear random noise
	
	/*UInt16 *frameBuffer = buffer.mData;
	for (int j = 0; j < inNumberFrames; j++) {
		frameBuffer[j] = rand();
	}*/

	
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
    const int four_bytes_per_float = 4;
    const int eight_bits_per_byte = 8;
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = 44100;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags =
    kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
 //   kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamFormat.mBytesPerPacket = 2;//four_bytes_per_float;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = 2;//four_bytes_per_float;
    streamFormat.mChannelsPerFrame = 1;
    streamFormat.mBitsPerChannel = 16;//four_bytes_per_float * eight_bits_per_byte;
    err = AudioUnitSetProperty (audioUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
    
    // set preferred buffer size
    //Float32 preferredBufferSize = .04; // in seconds
    //err = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);

    
    NSAssert1(err == noErr, @"Error setting stream format: %ld", err);
    
    // Allocate our own buffers (1 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
	// Practice learns the buffers used contain 512 frames, if this changes it will be fixed in processAudio.
	tempBuffer.mNumberChannels = 2;
	tempBuffer.mDataByteSize = 1024 * 2;
	tempBuffer.mData = malloc( 1024 * 2 );
	
    
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
