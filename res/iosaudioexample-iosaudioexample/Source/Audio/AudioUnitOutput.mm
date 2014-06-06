//
//  AudoUnitOutput.mm
//  IosAudioExample
//
//  Created by Pete Goodliffe on 18/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AudioUnitOutput.h"
#import "Audio.h"
#import "AudioProducer.h"

#define OUTPUT_BUS 0

static OSStatus
audioUnitCallback(void                        *inRefCon,
                  AudioUnitRenderActionFlags  *ioActionFlags,
                  const AudioTimeStamp        *inTimeStamp,
                  UInt32                       inBusNumber,
                  UInt32                       inNumberFrames,
                  AudioBufferList             *ioData);

@interface AudioUnitOutput ()
- (void) start;
- (void) stop;
- (OSStatus) audioUnitCallback:(AudioUnitRenderActionFlags *)ioActionFlags
                     timestamp:(const AudioTimeStamp       *)inTimeStamp
                     busNumber:(UInt32                      )inBusNumber
                  numberFrames:(UInt32                      )inNumberFrames
                          data:(AudioBufferList            *)ioData;
@end

//==============================================================================

@implementation AudioUnitOutput

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
	OSStatus status = noErr;

	AudioComponentDescription desc;
	desc.componentType          = kAudioUnitType_Output;
	desc.componentSubType       = kAudioUnitSubType_RemoteIO;
	desc.componentFlags         = 0;
	desc.componentFlagsMask     = 0;
	desc.componentManufacturer  = kAudioUnitManufacturer_Apple;

	AudioComponent outputComponent = AudioComponentFindNext(NULL, &desc);

	status = AudioComponentInstanceNew(outputComponent, &audioUnit);
    ERROR_HERE(status);

	UInt32 flag = 1;
	status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, OUTPUT_BUS, &flag, sizeof(flag));
    ERROR_HERE(status);

	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate         = SAMPLE_RATE;
	audioFormat.mFormatID           = kAudioFormatLinearPCM;
	audioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket    = 1;
	audioFormat.mChannelsPerFrame   = NUM_CHANNELS;
	audioFormat.mBitsPerChannel     = 16;
	audioFormat.mBytesPerPacket     = 4;
	audioFormat.mBytesPerFrame      = 4;

	status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, OUTPUT_BUS, &audioFormat, sizeof(audioFormat));
    ERROR_HERE(status);

	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc       = audioUnitCallback;
	callbackStruct.inputProcRefCon = self;

    if (!status)
    {
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, OUTPUT_BUS, &callbackStruct, sizeof(callbackStruct));
        ERROR_HERE(status);
    }
    if (!status)
    {
        status = AudioUnitInitialize(audioUnit);
        ERROR_HERE(status);
    }

	status = AudioOutputUnitStart(audioUnit);
    ERROR_HERE(status);
}

- (void) stop
{

    OSStatus err = AudioOutputUnitStop(audioUnit);
    if (err) ERROR_HERE(err);

	err = AudioUnitUninitialize(audioUnit);
    if (err) ERROR_HERE(err);

}

- (OSStatus) audioUnitCallback:(AudioUnitRenderActionFlags *)ioActionFlags
                     timestamp:(const AudioTimeStamp       *)inTimeStamp
                     busNumber:(UInt32                      )inBusNumber
                  numberFrames:(UInt32                      )inNumberFrames
                          data:(AudioBufferList            *)ioData
{
	for(UInt32 i = 0; i < ioData->mNumberBuffers; i++)
    {
        Sample * const  samples       = (Sample*)ioData->mBuffers[i].mData;
		const size_t    samplesToFill = ioData->mBuffers[i].mDataByteSize / sizeof(Sample);
        [producer produceSamples:samples size:samplesToFill];
	}
    return noErr;
}

OSStatus
audioUnitCallback(void                        *inRefCon,
                  AudioUnitRenderActionFlags  *ioActionFlags,
                  const AudioTimeStamp        *inTimeStamp,
                  UInt32                       inBusNumber,
                  UInt32                       inNumberFrames,
                  AudioBufferList             *ioData)
{
    // This MUST be here, or we leak autoreleased objects every time this function is called
    // (of course, I don't autorelease anything here, but it's an example)
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    AudioUnitOutput *self = (AudioUnitOutput*)inRefCon;
    return [self audioUnitCallback:ioActionFlags
                         timestamp:inTimeStamp
                         busNumber:inBusNumber
                      numberFrames:inNumberFrames
                              data:ioData];

	[pool drain];
}

@end
