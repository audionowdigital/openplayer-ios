
//
//  AVBufferPlayer.h
//  OpenPlayer
//
//  Created by Radu Motisan on 05/06/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "AVBufferPlayer.h"

@implementation AVBufferPlayer
{
	AVAudioPlayer *_audioPlayer;
}

- (id)initWithBuffer:(short *)buffer frames:(int)frames
{
	if ((self = [super init]))
	{
		// AVAudioPlayer will only play formats it knows. It cannot play raw
		// audio data, so we will convert the raw floating point values into
		// a 16-bit WAV file.

		unsigned int payloadSize = frames * sizeof(SInt16);  // byte size of waveform data
		unsigned int wavSize = 44 + payloadSize;             // total byte size

		// Allocate a memory buffer that will hold the WAV header and the
		// waveform bytes.
		SInt8 *wavBuffer = (SInt8 *)malloc(wavSize);
		if (wavBuffer == NULL)
		{
			NSLog(@"Error allocating %u bytes", wavSize);
			return nil;
		}

		// Fake a WAV header.
		SInt8 *header = (SInt8 *)wavBuffer;
		header[0x00] = 'R';
		header[0x01] = 'I';
		header[0x02] = 'F';
		header[0x03] = 'F';
		header[0x08] = 'W';
		header[0x09] = 'A';
		header[0x0A] = 'V'; 
		header[0x0B] = 'E';
		header[0x0C] = 'f';
		header[0x0D] = 'm';
		header[0x0E] = 't';
		header[0x0F] = ' ';
		header[0x10] = 16;    // size of format chunk (always 16)
		header[0x11] = 0;
		header[0x12] = 0;
		header[0x13] = 0;
		header[0x14] = 1;     // 1 = PCM format
		header[0x15] = 0;
		header[0x16] = 1;     // number of channels 
		header[0x17] = 0;
/*		header[0x18] = 0x44;  // samples per sec (44100) : AC44,
		header[0x19] = 0xAC;*/
        header[0x18] = 0x80;  // samplerate: 48000 : BB80 //radu
        header[0x19] = 0xBB;
		header[0x1A] = 0; 
		header[0x1B] = 0;
		header[0x1C] = 0x88;  // bytes per sec (88200)
		header[0x1D] = 0x58;
		header[0x1E] = 0x01;
		header[0x1F] = 0;
		header[0x20] = 2;     // block align (bytes per sample)
		header[0x21] = 0;
		header[0x22] = 16;    // bits per sample
		header[0x23] = 0;
		header[0x24] = 'd';
		header[0x25] = 'a';
		header[0x26] = 't';
		header[0x27] = 'a';	

		*((SInt32 *)(wavBuffer + 0x04)) = payloadSize + 36;   // total chunk size
		*((SInt32 *)(wavBuffer + 0x28)) = payloadSize;        // size of waveform data

		// Convert the floating point audio data into signed 16-bit.
		SInt16 *payload = (SInt16 *)(wavBuffer + 44);
		for (int t = 0; t < frames; ++t)
		{
			payload[t] = buffer[t] ;
		}

		// Put everything in an NSData object.
		NSData *data = [[NSData alloc] initWithBytesNoCopy:wavBuffer length:wavSize];

		// Create the AVAudioPlayer.
		NSError *error;
		_audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
		if (_audioPlayer == nil)
		{
			NSLog(@"Error creating AVAudioPlayer: %@", error);
			return nil;
		}

		_audioPlayer.numberOfLoops = -1;
	}
	return self;
}

- (void)play
{
	[_audioPlayer play];
}

- (void)stop
{
	[_audioPlayer stop];
}

@end
