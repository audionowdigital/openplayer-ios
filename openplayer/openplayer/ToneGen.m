//
//  ToneGen.m
//  openplayer
//
//  Created by Florin Moisa on 30/05/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <AudioUnit/AudioUnit.h>
#import "ToneGen.h"

OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags  *ioActionFlags,
                    const AudioTimeStamp        *inTimeStamp,
                    UInt32                      inBusNumber,
                    UInt32                      inNumberFrames,
                    AudioBufferList             *ioData);
void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState);


@interface ToneGen()
@property (nonatomic) AudioComponentInstance toneUnit;
@property (nonatomic) NSTimer *timer;
- (void)createToneUnit;
@end


@implementation ToneGen
@synthesize toneUnit = _toneUnit;
@synthesize timer = _timer;
@synthesize delegate = _delegate;
@synthesize frequency = _frequency;
@synthesize sampleRate = _sampleRate;
@synthesize theta = _theta;

- (id) init
{
    self = [super init];
    if (self)
    {
        self.sampleRate = 44100;
        self.frequency = 1440.0f;
        return self;
    }
    return nil;
}

- (void)play:(float)ms
{
    [self play];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:(ms / 100)
                                                  target:self
                                                selector:@selector(stop)
                                                userInfo:nil
                                                 repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)play
{
    if (!self.toneUnit)
    {
        [self createToneUnit];
        
        // Stop changing parameters on the unit
        OSErr err = AudioUnitInitialize(self.toneUnit);
        if (err)
            NSLog(@"Error initializing unit");
        
        // Start playback
        err = AudioOutputUnitStart(self.toneUnit);
        if (err)
            NSLog(@"Error starting unit");
    }
}

- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;
    
    if (self.toneUnit)
    {
        AudioOutputUnitStop(self.toneUnit);
        AudioUnitUninitialize(self.toneUnit);
        AudioComponentInstanceDispose(self.toneUnit);
        self.toneUnit = nil;
    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(toneStop)]) {
        [self.delegate performSelector:@selector(toneStop)];
    }
}

- (void)createToneUnit
{
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_GenericOutput;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    // Get the default playback output unit
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    if (!defaultOutput)
        NSLog(@"Can't find default output");
    
    // Create a new unit based on this that we'll use for output
    OSErr err = AudioComponentInstanceNew(defaultOutput, &_toneUnit);
    if (err)
        NSLog(@"Error creating unit");
    
    // Set our tone rendering function on the unit
    AURenderCallbackStruct input;
    input.inputProc = RenderTone;
    input.inputProcRefCon = (__bridge void*)self;
    err = AudioUnitSetProperty(self.toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
    if (err)
        NSLog(@"Error setting callback");
    
    // Set the format to 32 bit, single channel, floating point, linear PCM
    const int four_bytes_per_float = 4;
    const int eight_bits_per_byte = 8;
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = self.sampleRate;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamFormat.mBytesPerPacket = four_bytes_per_float;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = four_bytes_per_float;
    streamFormat.mChannelsPerFrame = 1;
    streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
    err = AudioUnitSetProperty (self.toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
    if (err)
        NSLog(@"Error setting stream format");
}

@end


OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags  *ioActionFlags,
                    const AudioTimeStamp        *inTimeStamp,
                    UInt32                      inBusNumber,
                    UInt32                      inNumberFrames,
                    AudioBufferList             *ioData)

{
    // Fixed amplitude is good enough for our purposes
    const double amplitude = 0.25;
    
    // Get the tone parameters out of the view controller
    ToneGen *toneGen = (__bridge ToneGen *)inRefCon;
    double theta = toneGen.theta;
    double theta_increment = 2.0 * M_PI * toneGen.frequency / toneGen.sampleRate;
    
    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        buffer[frame] = sin(theta) * amplitude;
        
        theta += theta_increment;
        if (theta > 2.0 * M_PI)
        {
            theta -= 2.0 * M_PI;
        }
    }
    
    // Store the theta back in the view controller
    toneGen.theta = theta;
    
    return noErr;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
    ToneGen *toneGen = (__bridge ToneGen *)inClientData;
    [toneGen stop];
}