//
//  OpusDecoder.m
//  libopus
//
//  Created by Radu Motisan on 03/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

/* Takes a opus bitstream from java callbacks from JNI and writes raw stereo PCM to
the jni callbacks. Decodes simple and chained OggOpus files from beginning
to end. */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

// include ogg/opus headers
#include <ogg/ogg.h>
#include <opus.h>
#include <opus_header.h>

// include the auxiliary logic
#include "OpusDecoder.h"
#include "OpusHeader.h"
#include "ErrorCodes.h"

#define OPUS_HEADERS 2
#define BUFFER_LENGTH 4096
#define COMMENT_MAX_LEN 40

// Decode setup
// 20ms at 48000, TODO 120ms
#define MAX_FRAME_SIZE      960
#define OPUS_STACK_SIZE     31684



// This is the only function we need ot call, assuming we have the interface already configured
int opusDecodeLoop(id<INativeInterface> callback) {
    fprintf(stderr, "startDecoding called, initing buffers");

    // prepare the buffers
    ogg_int16_t convbuffer[BUFFER_LENGTH]; //take 8k out of the data segment, not the stack
    int convsize = BUFFER_LENGTH;
    
    ogg_sync_state   oy; /* sync and verify incoming physical bitstream */
    ogg_stream_state os; /* take physical pages, weld into a logical stream of packets */
    ogg_page         og; /* one Ogg bitstream page. Opus packets are inside */
    ogg_packet       op; /* one raw packet of data for decode */
    
    char *buffer;
    int  bytes;
    
	// global data
	int frame_size =0;
	OpusDecoder *st = NULL;
	opus_int64 packet_count;
	int stream_init = 0;
	int eos = 0;
	int channels = 0;
	int rate = 0;
	int preskip = 0;
	int gran_offset = 0;
	int has_opus_stream = 0;
	ogg_int32_t opus_serialno = 0;
	int proccessing_page = 0;
	
	char vendor[COMMENT_MAX_LEN] = {0};
	char title[COMMENT_MAX_LEN] = {0};
	char artist[COMMENT_MAX_LEN] = {0};
	char album[COMMENT_MAX_LEN] = {0};
	char date[COMMENT_MAX_LEN] = {0};
	char track[COMMENT_MAX_LEN] = {0};

    //Notify the decode feed we are starting to initialize
    [callback onStartReadingHeader];

    ogg_sync_init(&oy); // Now we can read pages
    int inited = 0, header = OPUS_HEADERS;
    int err = SUCCESS;
    int i;

    // start source reading / decoding loop
    while (1) {
    	if (err != SUCCESS) {
            fprintf(stderr, "Global loop closing for error: %d", err);
    		break;
    	}

        // READ DATA : submit a 4k block to Ogg layer
        buffer = ogg_sync_buffer(&oy,BUFFER_LENGTH);
        
        char *buferCopy;
        
        bytes = [callback onReadEncodedData:&buferCopy ofSize:BUFFER_LENGTH];
        
        memcpy(buffer, buferCopy, bytes);

        ogg_sync_wrote(&oy,bytes);

        // Check available data
        if (bytes == 0) {
            fprintf(stderr, "Data source finished.");
        	err = SUCCESS;
        	break;
        }

        // loop pages
        while (1) {
        	// exit loop on error
        	if (err != SUCCESS) break;
        	// sync the stream and get a page
        	int result = ogg_sync_pageout(&oy,&og);
        	// need more data, so go to PREVIOUS loop and read more
        	if (result == 0) break;
           	// missing or corrupt data at this page position
           	if (result < 0) {
                fprintf(stderr, "Corrupt or missing data in bitstream; continuing..");
        		continue;
           	}
           	// we finally have a valid page
			if (!inited) {
				ogg_stream_init(&os, ogg_page_serialno(&og));
                fprintf(stderr, "inited stream, serial no: %ld", os.serialno);
				inited = 1;
				// reinit header flag here
				header = OPUS_HEADERS;

			}
			//  add page to bitstream: can safely ignore errors at this point
			if (ogg_stream_pagein(&os, &og) < 0)
                fprintf(stderr, "error 5 pagein");

			// consume all , break for error
			while (1) {
				result = ogg_stream_packetout(&os,&op);

				if(result == 0) break; // need more data so exit and go read data in PREVIOUS loop
				if(result < 0) continue; // missing or corrupt data at this page position , drop here or tolerate error?


				// decode available data
				if (header == 0) {
					int ret = opus_decode(st, (unsigned char*) op.packet, op.bytes, convbuffer, MAX_FRAME_SIZE, 0);

					/*If the decoder returned less than zero, we have an error.*/
					if (ret < 0) {
                        fprintf(stderr, "Decoding error: %s", opus_strerror(ret));
						err = DECODE_ERROR;
						break;
					}
					frame_size = (ret < convsize?ret : convsize);

                    [callback onWritePCMData:convbuffer ofSize:channels*frame_size];


				} // decoding done

				// do we need the header? that's the first thing to take
				if (header > 0) {
					if (header == OPUS_HEADERS) { // first header
						//if (op.b_o_s && op.bytes >= 8 && !memcmp(op.packet, "OpusHead", 8)) {
						if (op.bytes < 8 || memcmp(op.packet, "OpusHead", 8) != 0) {
							err = NOT_HEADER;
							break;
						}
						// prepare opus structures
						st = process_header(&op, &rate, &channels, &preskip, 0);
					}
					if (header == OPUS_HEADERS -1) { // second and last header, read comments
						// err = we ignore comment errors
						process_comments((char *)op.packet, op.bytes, vendor, title, artist, album, date, track, COMMENT_MAX_LEN);
					}
					// we need to do this 2 times, for all 2 opus headers! add data to header structure

					// signal next header
					header--;

					// we got all opus headers
					if (header == 0) {
                        //  header ready , call player to pass stream details and init AudioTrack
                        [callback onStart:rate trackChannels:channels trackVendor:vendor trackTitle:title trackArtist:artist trackAlbum:album trackDate:date trackName:track];
                        
					}
				} // header decoding

				// while packets

				// check stream end
				if (ogg_page_eos(&og)) {
                    fprintf(stderr, "Stream finished.");
					// clean up this logical bitstream;
					ogg_stream_clear(&os);

					// attempt to go for re-initialization until EOF in data source
					err = SUCCESS;

					inited = 0;
					break;
				}
			}
        	// page if
        } // while pages

    }

    // ogg_page and ogg_packet structs always point to storage in libopus.  They're never freed or manipulated directly
    // OK, clean up the framer
    ogg_sync_clear(&oy);

    [callback onStop];

    return err;
}
