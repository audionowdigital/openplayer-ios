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
    // get a pointer to our object, so we can access some audioformat properties (bytesPerFrame)
    AudioController *this = (__bridge AudioController *)inRefCon;
    
    //a single channel: mono or interleaved stereo
    short *targetBuffer = (SInt16*)ioData->mBuffers[0].mData;
    int bytesToCopy = ioData->mBuffers[0].mDataByteSize;
    
    // Pull audio from playthrough buffer
    int32_t availableBytes;
    short *buffer = TPCircularBufferTail(&this->circbuffer, &availableBytes);
    // how much dow we need vs how much do we have
    int bytes = min(bytesToCopy, availableBytes);
    // push bytes
    memcpy(targetBuffer, buffer, bytes);
    TPCircularBufferConsume(&this->circbuffer, bytes);
	
    return noErr;
}



@implementation AudioController

@synthesize audioUnit;


/**
 Initialize the audioUnit and allocate our own temporary buffer.
 The temporary buffer will hold the latest data coming in from the microphone,
 and will be copied to the output when this is requested.
 */
- (id) initWithSampleRate:(int)sampleRate channels:(int)channels {
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
    
    // TODO: handle all error cases properly.
    // TODO: implement the circular buffer
    
    // init audio output based on given channels and samplerate
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = sampleRate;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags =    kAudioFormatFlagIsSignedInteger  | kAudioFormatFlagIsPacked  ;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mChannelsPerFrame = channels;
    streamFormat.mBitsPerChannel = 16; //sizeof(short) * 8
    streamFormat.mBytesPerFrame =  streamFormat.mBitsPerChannel * streamFormat.mChannelsPerFrame  / 8;
    streamFormat.mBytesPerPacket = streamFormat.mBytesPerFrame  * streamFormat.mFramesPerPacket ;
    err = AudioUnitSetProperty (audioUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
    NSAssert1(err == noErr, @"Error setting stream format: %ld", err);
    
    // save format data to our current instance
    _bytesPerFrame = streamFormat.mBytesPerFrame;
    _sampleRate = sampleRate;
    _channels = channels;
    
    // alloc circular buffer
    // Initialise buffer
    TPCircularBufferInit(&circbuffer, kBufferLength);
    
    return self;
}

// Start the audioUnit. requested for feeding to the speakers, by use of the provided callbacks.
- (void) start {
    // Finalize parameters on the unit
    OSErr err = AudioUnitInitialize(audioUnit);
    NSAssert1(err == noErr, @"Error initializing unit: %ld", err);
    
	OSStatus status = AudioOutputUnitStart(audioUnit);
    NSAssert1(status == noErr, @"Error starting audioOutputUnit: %ld", status);
}

// Stop the audioUnit
- (void) stop {
    // free it in reverse order
    AudioOutputUnitStop(audioUnit);
    AudioUnitUninitialize(audioUnit);
    AudioComponentInstanceDispose(audioUnit);
    audioUnit = nil;
    
    TPCircularBufferCleanup(&circbuffer);
    
}

- (void) pause
{
    AudioOutputUnitStop(audioUnit);
}

- (int) getBufferFill {
    int32_t availableBytes;
    TPCircularBufferTail(&circbuffer, &availableBytes);
    
    int p = 100 * availableBytes / kBufferLength;
    NSLog(@"percent:%d", p);
    return p;
}


@end
