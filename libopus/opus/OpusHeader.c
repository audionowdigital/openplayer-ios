//
//  OpusHeader.c
//  libopus
//
//  Created by Radu Motisan on 03/06/14.
//  Copyright (c) 2014 Xiph.org/Sudeium. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
// include ogg/opus headers
#include <ogg/ogg.h>
#include <opus.h>
#include <opus_header.h>
// include our logic
#include "OpusHeader.h"
#include "ErrorCodes.h"


/*Process an Opus header and setup the opus decoder based on it.
 It takes several pointers for header values which are needed
 elsewhere in the code.*/
OpusDecoder *process_header(ogg_packet *op, int *rate, int *channels, int *preskip, int quiet) {
	int err;
	OpusDecoder *st;
	OpusHeader header;
    
	if (opus_header_parse(op->packet, op->bytes, &header) == 0) {
        fprintf(stderr, "Cannot parse header");
		return NULL;
	} else
        fprintf(stderr, "Header parsed: ch:%d samplerate:%d", header.channels, header.input_sample_rate);
	*channels = header.channels;
    
	// validate sample rate: If the rate is unspecified we decode to 48000
	if (!*rate) *rate = header.input_sample_rate;
	if (*rate == 0) *rate = 48000;
	if (*rate < 8000 || *rate > 192000) {
        fprintf(stderr, "Invalid input_rate %d, defaulting to 48000 instead.",*rate);
		*rate = 48000;
	}
    
	*preskip = header.preskip;
	st = opus_decoder_create(*rate, header.channels, &err); // was 48000
	if (err != OPUS_OK)	{
        fprintf(stderr, "Cannot create decoder: %s", opus_strerror(err));
		return NULL;
	}
	if (!st) {
        fprintf(stderr, "Decoder initialization failed: %s", opus_strerror(err));
		return NULL;
	}
    
	if (header.gain != 0) {
		// Gain API added in a newer libopus version, if we don't have it we apply the gain ourselves. We also add in a user provided manual gain at the same time.
		int gainadj = (int) header.gain;
		err = opus_decoder_ctl(st, OPUS_SET_GAIN(gainadj));
		if (err != OPUS_OK) {
            fprintf(stderr, "Error setting gain: %s", opus_strerror(err));
            return NULL;
		}
	}
    
	if (!quiet) {
        fprintf(stderr, "Decoding to %d Hz (%d channels)", *rate, *channels);
		if (header.version != 1)
            fprintf(stderr, "Header v%d",header.version);
        
		if (header.gain != 0) {
            fprintf(stderr, "Playback gain: %f dB\n", header.gain / 256.);
		}
	}
    
	return st;
}



// OpusTags | Len 4B | Vendor String (len) | Len 4B Tags | Len Tag 1 4B | Tag 1 String (Len) | Len Tag 2 4B ..
int process_comments(char *c, int length, char *vendor, char *title,  char *artist, char *album, char *date, char *track, int maxlen) {
	int err = SUCCESS;
    fprintf(stderr, "process_comments called for %d bytes.", length);
    
	if (length < (8 + 4 + 4)) {
		err = INVALID_HEADER;
		return err;;
	}
	if (strncmp(c, "OpusTags", 8) != 0) {
		err = INVALID_HEADER;
		return err;
	}
	c += 8; // skip header
	int len = readint(c, 0);
	c += 4;
	if (len < 0 || len > (length - 16)) {
        fprintf(stderr, "invalid/corrupt comments");
		err = INVALID_HEADER;
		return err;
	}
	strncpy(vendor, c, min(len, maxlen));
    
	c += len;
	int fields = readint(c, 0); // the -16 check above makes sure we can read this.
	c += 4;
	length -= 16 + len;
	if (fields < 0 || fields > (length >> 2)) {
        fprintf(stderr, "invalid/corrupt comments");
		err = INVALID_HEADER;
		return err;
	}
    fprintf(stderr, "Go and read %d fields:", fields);
	int i = 0;
	for (i = 0; i < fields; i++) {
	    if (length < 4){
            fprintf(stderr, "invalid/corrupt comments");
			err = INVALID_HEADER;
			return err;
	    }
	    len = readint(c, 0);
	    c += 4;
	    length -= 4;
	    if (len < 0 || len > length)
	    {
            fprintf(stderr, "invalid/corrupt comments");
			err = INVALID_HEADER;
			return err;
	    }
        
        char *tmp = (char *)malloc(len + 1); // we also need the ending 0
	    strncpy(tmp, c, len);
	    tmp[len] = 0;
        fprintf(stderr, "Header comment:%d len:%d [%s]", i, len, tmp);
        free(tmp);
        
	    // keys we are looking for in the comments
		char keys[5][10] = { "title=", "artist=", "album=", "date=", "track=" };
		char *values[5] = { title, artist, album, date, track }; // put the values in these pointers
	    int j = 0;
	    for (j = 0; j < 5; j++) { // iterate all keys
	    	int keylen = strlen(keys[j]);
	    	if (!strncasecmp(c, keys[j], keylen )) strncpy(values[j], c + keylen, min(len - keylen , maxlen));
	    }
	    /*if (!strncasecmp(c, "title=", 6)) strncpy(title, c + 6, min(len - 6 , maxlen));
         if (!strncasecmp(c, "artist=", 7)) strncpy(artist, c + 7, min(len - 7 , maxlen));
         if (!strncasecmp(c, "album=", 6)) strncpy(album, c + 6, min(len - 6 , maxlen));
         if (!strncasecmp(c, "date=", 5)) strncpy(date, c + 5, min(len - 5 , maxlen));
         if (!strncasecmp(c, "track=", 6)) strncpy(track, c + 6, min(len - 6 , maxlen));*/
        
	    c += len;
	    length -= len;
    }
    return err;
}
