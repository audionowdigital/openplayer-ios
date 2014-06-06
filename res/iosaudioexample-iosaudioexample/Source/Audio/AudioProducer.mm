/*
 *  AudioProducer.cpp
 *  IosAudioExample
 *
 *  Created by Pete Goodliffe on 17/11/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "AudioProducer.h"

#import <cmath>

@implementation SineWave

/// The scaling factor to apply after multiplication by the
/// coefficient
static const int32_t scale = (1<<29);

@synthesize sampleRate, frequency, peak;

- (void) setUp
{
    using std::ldexp;
    using std::sin;
    using std::cos;

    double step = 2.0 * M_PI * frequency / sampleRate;

    c  = (2 * cos(step) * scale);
    s1 = (peak * sin(-step));
    s2 = (peak * sin(-2.0*step));
}

- (id) init
{
    if ((self = [super init]))
    {
        sampleRate = 44100;
        peak       = 0x7fff;
        frequency  = 523.8;
        [self setUp];
    }
    return self;
}

- (void) setSampleRate:(float)newSampleRate
{
    sampleRate = newSampleRate;
    [self setUp];
}

- (void) setPeakLevel:(Sample)newPeak
{
    peak = newPeak;
    [self setUp];
}

- (void) setFrequency:(float)newFrequency
{
    frequency = newFrequency;
    [self setUp];
}

- (Sample) nextSample
{
    int64_t temp = (int64_t)c * (int64_t)s1;
    Sample result = Sample(temp/scale) - s2;
    s2 = s1;
    s1 = result;
    return result;
}

- (void) produceSamples:(Sample *)audioBuffer size:(size_t)size
{
    fprintf(stderr, ".");

    for (size_t n = 0; n < size; n += 2)
    {
        Sample next = [self nextSample];

        audioBuffer[n] = audioBuffer[n+1] = next;
    }
}

@end

