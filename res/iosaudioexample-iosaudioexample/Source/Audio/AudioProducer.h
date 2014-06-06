/*
 *  AudioProducer.h
 *  IosAudioExample
 *
 *  Created by Pete Goodliffe on 17/11/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

/// Type of audio sample produced by an AudioProducer
typedef SInt16 Sample;


/// Protocol for objects that produce audio
@protocol AudioProducer

@property (nonatomic) float sampleRate;

/// Fills a buffer with "size" samples.
/// The buffer should be filled in with interleaved stereo samples.
- (void) produceSamples:(Sample *)audioBuffer size:(size_t)size;

@end


/// Simple AudioProducer that produces a sine wave
@interface SineWave : NSObject <AudioProducer>
{
    // Sine wave parameters
    float  sampleRate;
    float  frequency;
    Sample peak;

    // Resonant filter state
    int32_t c;   ///< The coefficient in the resonant filter
    Sample  s1;  ///< The previous output sample
    Sample  s2;  ///< The output sample before last
}

@property (nonatomic) float  frequency;
@property (nonatomic) Sample peak;

@end
