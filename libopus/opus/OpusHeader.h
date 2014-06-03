//
//  OpusHeader.h
//  libopus
//
//  Created by Radu Motisan on 03/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#ifndef libopus_OpusHeader_h
#define libopus_OpusHeader_h

// include ogg/opus headers
#include <ogg/ogg.h>
#include <opus.h>
#include <opus_header.h>

// read an int from multiple bytes
#define readint(buf, offset) (((buf[offset + 3] << 24) & 0xff000000) | ((buf[offset + 2] << 16) & 0xff0000) | ((buf[offset + 1] << 8) & 0xff00) | (buf[offset] & 0xff))

#define max(a,b) ({ __typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a > _b ? _a : _b; })
#define min(a,b) ({ __typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a < _b ? _a : _b; })


OpusDecoder *process_header(ogg_packet *op, int *rate, int *channels, int *preskip, int quiet);

int process_comments(char *c, int length, char *vendor, char *title,  char *artist, char *album, char *date, char *track, int maxlen);


#endif
