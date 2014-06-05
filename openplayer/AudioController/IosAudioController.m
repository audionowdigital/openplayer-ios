//
//  IosAudioController.m
//  Aruts
//
//  Created by Simon Epskamp on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IosAudioController.h"
#import <AudioToolbox/AudioToolbox.h>

#define kOutputBus 0
#define kInputBus 1

IosAudioController* iosAudio;

void checkStatus(int ids, int status){
	if (status) {
		printf("%d Status not 0! %d\n",ids, status);
//		exit(1);
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
	NSLog(@"Give me data!");
	for (int i=0; i < ioData->mNumberBuffers; i++) { // in practice we will only ever have 1 buffer, since audio format is mono
		AudioBuffer buffer = ioData->mBuffers[i];
		
//		NSLog(@"  Buffer %d has %d channels and wants %d bytes of data.", i, buffer.mNumberChannels, buffer.mDataByteSize);
		
		// copy temporary buffer dat2a to output buffer
		UInt32 size = min(buffer.mDataByteSize, [iosAudio tempBuffer].mDataByteSize); // dont copy more data then we have, or then fits
		memcpy(buffer.mData, [iosAudio tempBuffer].mData, size);
		buffer.mDataByteSize = size; // indicate how much data we wrote in the buffer
		
		// uncomment to hear random noise
		/*
		UInt16 *frameBuffer = buffer.mData;
		for (int j = 0; j < inNumberFrames; j++) {
			frameBuffer[j] = rand();
		}
		*/
		
	}
	
    return noErr;
}

@implementation IosAudioController

@synthesize audioUnit, tempBuffer;

/**
 Initialize the audioUnit and allocate our own temporary buffer.
 The temporary buffer will hold the latest data coming in from the microphone,
 and will be copied to the output when this is requested.
 */
- (id) init {
	self = [super init];
	
	OSStatus status;
	
	// Describe audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	// Get component
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// Get audio units
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
	checkStatus(1,status);
	
	UInt32 flag = 1;
	// Enable IO for playback
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, 
								  kAudioUnitScope_Output, 
								  kOutputBus,
								  &flag, 
								  sizeof(flag));
	checkStatus(2,status);
	
	// Describe format
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 2;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
	
	// Apply format
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Output, 
								  kInputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	checkStatus(3,status);
	
	// Set output callback
    AURenderCallbackStruct callbackStruct;
	
	callbackStruct.inputProc = playbackCallback;
	callbackStruct.inputProcRefCon = NULL;//(__bridge void *)(self);
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_SetRenderCallback, 
								  kAudioUnitScope_Global, 
								  kOutputBus,
								  &callbackStruct, 
								  sizeof(callbackStruct));
	checkStatus(4,status);
	
	
	// Allocate our own buffers (2 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
	// Practice learns the buffers used contain 512 frames, if this changes it will be fixed in processAudio.
	tempBuffer.mNumberChannels = 1;
	tempBuffer.mDataByteSize = 512 * 2;
	tempBuffer.mData = malloc( 512 * 2 );
	
	// Initialise
	status = AudioUnitInitialize(audioUnit);
	checkStatus(5,status);
	
	return self;
}

/**
 Start the audioUnit. requested for feeding to the speakers, by
 use of the provided callbacks.
 */
- (void) start {
	OSStatus status = AudioOutputUnitStart(audioUnit);
	checkStatus(6,status);
}

/**
 Stop the audioUnit
 */
- (void) stop {
	OSStatus status = AudioOutputUnitStop(audioUnit);
	checkStatus(7,status);
}

/**
 Change this funtion to decide what is done with incoming
 audio data from the microphone.
 Right now we copy it to our own temporary buffer.
 */

	// copy incoming audio data to temporary buffer
//	memcpy(tempBuffer.mData, bufferList->mBuffers[0].mData, bufferList->mBuffers[0].mDataByteSize);


/**
 Clean up.
 */
- (void) dealloc {
	//[super	dealloc];
	AudioUnitUninitialize(audioUnit);
	free(tempBuffer.mData);
}

@end
