//
//  SecondController.m
//  Open Player
//
//  Created by Catalin BORA on 29/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "SecondController.h"
#import "StreamConnection.h"
#import <AudioToolbox/AudioToolbox.h>

#define kPodcastURL @"http://www.markosoft.ro/opus/02_Archangel.opus"
#define kStreamURL @"http://icecast1.pulsradio.com:80/mxHD.ogg"

@interface SecondController ()

@property (nonatomic, strong) StreamConnection *connection;

@end

@implementation SecondController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playAudio:(id)sender {

    AudioQueueRef outputQueue;
    int sampleRate = 44100;
    
    // Get the preferred sample rate (8,000 Hz on iPhone, 44,100 Hz on iPod touch)
    OSStatus err;
    //NSLog (@"Current hardware sample rate: %1.0f", sampleRate);
    
    self.index = 0;
    
    int bufferByteSize;
    AudioQueueBufferRef buffer;
    
    // Set up stream format fields
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = sampleRate;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    streamFormat.mBitsPerChannel = 16;
    streamFormat.mChannelsPerFrame = 2;
    streamFormat.mBytesPerPacket = 2 * streamFormat.mChannelsPerFrame;
    streamFormat.mBytesPerFrame = 2 * streamFormat.mChannelsPerFrame;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mReserved = 0;
    
    // New output queue ---- PLAYBACK ----
    err = AudioQueueNewOutput (&streamFormat,AudioEngineOutputBufferCallback,
                               (__bridge void*)self,
                               CFRunLoopGetCurrent(),
                               kCFRunLoopCommonModes,
                               0,
                               &outputQueue);
    
    if (err != noErr) NSLog(@"AudioQueueNewOutput() error: %d", (int)err);
    
    AudioQueueSetParameter(outputQueue, kAudioQueueParam_Volume, 1.0);
    
    // Enqueue buffers
    bufferByteSize = (sampleRate > 16000)? 2176 : 512; // 40.5 Hz : 31.25 Hz
    for (int i=0; i<3; i++) {
        err = AudioQueueAllocateBuffer (outputQueue, bufferByteSize, &buffer);
        if (err == noErr) {
            [self generateTone: buffer];
            err = AudioQueueEnqueueBuffer (outputQueue, buffer, 0, nil);
            if (err != noErr) NSLog(@"AudioQueueEnqueueBuffer() error: %d", (int)err);
        } else {
            NSLog(@"AudioQueueAllocateBuffer() error: %d", (int)err);
            return;
        }
    }
    
    // Start playback
    err = AudioQueueStart(outputQueue, nil);

}

// AudioQueue output queue callback.
void AudioEngineOutputBufferCallback (void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    
    SecondController *engine = (__bridge SecondController*) inUserData;
    
    [engine generateTone:inBuffer];
    OSStatus err = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

-(void) generateTone: (AudioQueueBufferRef) buffer{
    
    int sampleRate = 44100;
    int outputFrequency = 1.0;
    //int outputBuffersToRewrite = 3;
    
    if (outputFrequency == 0.0) {
        memset(buffer->mAudioData, 0, buffer->mAudioDataBytesCapacity);
        buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
    } else {
        // Make the buffer length a multiple of the wavelength for the output frequency.
        int sampleCount = buffer->mAudioDataBytesCapacity / sizeof (SInt16);
        double bufferLength = sampleCount;
        double wavelength = sampleRate / outputFrequency;
        double repetitions = floor (bufferLength / wavelength);
        if (repetitions > 0.0) {
            sampleCount = round (wavelength * repetitions);
        }
        
        double      x, y;
        double      sd = 1.0 / sampleRate;
        double      amp = 0.9;
        double      max16bit = SHRT_MAX;
        int i;
        SInt16 *p = buffer->mAudioData;
        
        for (i = 0; i < sampleCount; i++) {
            x = i * sd * outputFrequency;
            
            y = sin (x * 2.0 * M_PI);
            
//            switch (outputWaveform) {
//                case kSine:
//                    y = sin (x * 2.0 * M_PI);
//                    break;
//                case kTriangle:
//                    x = fmod (x, 1.0);
//                    if (x < 0.25)
//                        y = x * 4.0; // up 0.0 to 1.0
//                    else if (x < 0.75)
//                        y = (1.0 - x) * 4.0 - 2.0; // down 1.0 to -1.0
//                    else
//                        y = (x - 1.0) * 4.0; // up -1.0 to 0.0
//                    break;
//                case kSawtooth:
//                    y  = 0.8 - fmod (x, 1.0) * 1.8;
//                    break;
//                case kSquare:
//                    y = (fmod(x, 1.0) < 0.5)? 0.7: -0.7;
//                    break;
//                default: y = 0; break;
//            }
            p[i] = self.index++ * max16bit * amp; ;
            //self.index +=0.000000000005;
            //p[i] = y
           // NSLog(@" %d", p[i]);
        }
        
        buffer->mAudioDataByteSize = sampleCount * sizeof (SInt16);
    }
}

- (IBAction)stopAudio:(id)sender {
}

- (IBAction)connectToStream:(id)sender {
    
    NSURL *url = [NSURL URLWithString:kStreamURL];
   
    NSError *error;
    self.connection = [[StreamConnection alloc] initWithURL:url error:&error];
    
    self.maxSizeLabel.text =@"Unknow";
}

- (IBAction)readStreamData:(id)sender {
    
    NSError *error;
    NSData *buffer = [self.connection readAllBytesWithError:&error];
    
    self.bufferSizeLabel.text = [NSString stringWithFormat:@"%d",buffer.length];
    
    self.maxSizeLabel.text = [NSString stringWithFormat:@"%lld",self.connection.podcastSize];
}
- (IBAction)readPartOfBuffer:(id)sender {
    
    NSError *error;
    NSData *data = [self.connection readBytesForLength:1000000 error:&error];
    NSLog(@" and the error was: %@ ",error);
}

- (IBAction)connectionStop:(id)sender {
    [self.connection stopStream];
}

- (IBAction)connectToPodcast:(id)sender {
    
    NSURL *url = [NSURL URLWithString:kPodcastURL];
    
    NSError *error;
    self.connection = [[StreamConnection alloc] initWithURL:url error:&error];
}
- (IBAction)seekToByte:(id)sender {

    self.maxSizeLabel.text = [NSString stringWithFormat:@"%lld",self.connection.podcastSize];
    
    // seek
    NSError *error;
    BOOL state = [self.connection seekToPosition:1000000 error:&error];
    
    NSLog(@" seek state %d and error %@ ",state,error);
    
}

- (IBAction)connectToFile:(id)sender {
    
    [self connectionStop:nil];
    
    // write to file
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject];
    NSString *documentPath = [documentsDirectory stringByAppendingPathComponent:@"Charles.bin"];
    NSURL *url = [NSURL URLWithString:documentPath];
    
    NSError *nserror = nil;
    //self.response = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&nserror];
    //this will set the image when loading is finished
    
    
    //self.bufferSizeLabel.text =[ NSString stringWithFormat:@"%d",self.response.length];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
