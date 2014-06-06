//
//  AudoUnitOutput.h
//  IosAudioExample
//
//  Created by Pete Goodliffe on 18/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <CoreAudio/CoreAudioTypes.h>
#include <AudioToolbox/AudioQueue.h>
#include <AudioUnit/AudioUnit.h>

@protocol AudioProducer;

@interface AudioUnitOutput : NSObject
{
    id<AudioProducer> producer;

    AudioComponentInstance audioUnit;
}

- (id) initWithProducer:(id<AudioProducer>)producer;

@end
