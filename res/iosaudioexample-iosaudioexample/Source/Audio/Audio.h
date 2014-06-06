/*
 *  Audio.h
 *  IosAudioExample
 *
 *  Created by Pete Goodliffe on 18/11/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

// A few simple, common definitions used across audio output implementations

#define NUM_CHANNELS        2
#define SAMPLE_RATE         44100

#define ERROR_HERE(status) do {if (status) fprintf(stderr, "ERROR %d [%s:%u]\n", (int)status, __func__, __LINE__);}while(0);
