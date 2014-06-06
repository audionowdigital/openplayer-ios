//
//  main.m
//  IosAudioExample
//
//  Created by Pete Goodliffe on 17/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AudioProducer.h"
#import "AudioQueueOutput.h"
#import "AudioUnitOutput.h"

//#define USE_AUDIO_QUEUE_OUTPUT

#ifdef USE_AUDIO_QUEUE_OUTPUT
    #define AudioOutputType AudioQueueOutput
#else
    #define AudioOutputType AudioUnitOutput
#endif

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool     = [[NSAutoreleasePool alloc] init];

    SineWave         *sineWave = [[SineWave alloc] init];
    AudioOutputType  *output   = [[AudioOutputType alloc] initWithProducer:sineWave];

    int retVal = UIApplicationMain(argc, argv, nil, nil);

    [output release];
    [sineWave release];

    [pool release];
    return retVal;
}
