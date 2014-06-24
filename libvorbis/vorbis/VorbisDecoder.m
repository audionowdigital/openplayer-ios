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

#import <Foundation/Foundation.h>
#import "mach/mach.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

// include ogg/opus headers
#include <ogg/ogg.h>
#include <vorbis/codec.h>

// include the auxiliary logic
#include "VorbisDecoder.h"
#include "ErrorCodes.h"

#define VORBIS_HEADERS 3
#define BUFFER_LENGTH 4096
#define COMMENT_MAX_LEN 40

// Decode setup
// 20ms at 48000, TODO 120ms
#define MAX_FRAME_SIZE      960
#define OPUS_STACK_SIZE     31684

#define max(a,b) ({ __typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a > _b ? _a : _b; })
#define min(a,b) ({ __typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a < _b ? _a : _b; })

vm_size_t usedMemory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

// This is the only function we need ot call, assuming we have the interface already configured
int vorbisDecodeLoop(id<INativeInterface> callback) {
    fprintf(stderr, "vorbis decoding  called, initing buffers");
  	//--
    ogg_int16_t convbuffer[BUFFER_LENGTH]; /* take 8k out of the data segment, not the stack */
    int convsize=BUFFER_LENGTH;
    
    ogg_sync_state   oy; /* sync and verify incoming physical bitstream */
    ogg_stream_state os; /* take physical pages, weld into a logical stream of packets */
    ogg_page         og; /* one Ogg bitstream page. Vorbis packets are inside */
    ogg_packet       op; /* one raw packet of data for decode */
    
    vorbis_info      vi; /* struct that stores all the static vorbis bitstream settings */
    vorbis_comment   vc; /* struct that stores all the bitstream user comments */
    vorbis_dsp_state vd; /* central working state for the packet->PCM decoder */
    vorbis_block     vb; /* local working space for packet->PCM decode */
    
    char *buffer;
    int  bytes;
    
    
	char vendor[COMMENT_MAX_LEN] = {0};
	char title[COMMENT_MAX_LEN] = {0};
	char artist[COMMENT_MAX_LEN] = {0};
	char album[COMMENT_MAX_LEN] = {0};
	char date[COMMENT_MAX_LEN] = {0};
	char track[COMMENT_MAX_LEN] = {0};
    
    /********** Decode setup ************/
    
    //Notify the decode feed we are starting to initialize
    [callback onStartReadingHeader];
    //1
    ogg_sync_init(&oy); /* Now we can read pages */
    
    int inited = 0, header = 3;
    int eos = 0;
    int err = SUCCESS;
    int i;
    
    int last = 0, now = 0;
    // start source reading / decoding loop
    while (1) {
    	if (err != SUCCESS) {
    		fprintf(stderr, "Global loop closing for error: %d", err);
    		break;
    	}
        now = usedMemory();
        NSLog(@"Vorbis log --- %d", now - last);
        last = now;
        // READ DATA : submit a 4k block to Ogg layer
        buffer = ogg_sync_buffer(&oy,2500);//BUFFER_LENGTH);
        
        bytes = [callback onReadEncodedData:buffer ofSize:2500];//BUFFER_LENGTH];
        
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
        	// need more data, so go to PREVIOUS loop and read more */
        	if (result == 0) break;
           	// missing or corrupt data at this page position
           	if (result < 0) {
                fprintf(stderr,  "Corrupt or missing data in bitstream; continuing..");
        		continue;
           	}
           	// we finally have a valid page
			if (!inited) {
				ogg_stream_init(&os, ogg_page_serialno(&og));
                fprintf(stderr,  "inited stream, serial no: %ld", os.serialno);
				inited = 1;
				// reinit header flag here
				header = VORBIS_HEADERS;
                
			}
			//  add page to bitstream: can safely ignore errors at this point
			if (ogg_stream_pagein(&os, &og) < 0)
                fprintf(stderr,  "error 5 pagein");
            
			// consume all , break for error
			while (1) {
				result = ogg_stream_packetout(&os,&op);
                
				if(result == 0) break; // need more data so exit and go read data in PREVIOUS loop
				if(result < 0) continue; // missing or corrupt data at this page position , drop here or tolerate error?
                
                
				// decode available data
				if (header == 0) {
					float **pcm;
					int samples;
					// test for success!
					if(vorbis_synthesis(&vb,&op)==0) vorbis_synthesis_blockin(&vd,&vb);
					while((samples = vorbis_synthesis_pcmout(&vd,&pcm)) > 0) {
						//LOGE(LOG_TAG, "start while 8, decoding %d samples: %d convsize:%d", op.bytes,  samples, convsize);
						int j;
						int frame_size = (samples < convsize?samples : convsize);
                        
						// convert floats to 16 bit signed ints (host order) and interleave
						for(i = 0; i < vi.channels; i++){
							ogg_int16_t *ptr = convbuffer + i;
							float  *mono = pcm[i];
							for(j=0;j<frame_size;j++){
								int val = floor(mono[j]*32767.f+.5f);
								// might as well guard against clipping
								if(val>32767) { val=32767; }
								if(val<-32768) { val=-32768; }
								*ptr=val;
								ptr += vi.channels;
							}
						}
                        
						// Call decodefeed to push data to AudioTrack
                        [callback onWritePCMData:convbuffer ofSize:frame_size*vi.channels];
						vorbis_synthesis_read(&vd,frame_size); // tell libvorbis how many samples we actually consumed
					}
                    //free(&pcm);
				} // decoding done
                
				// do we need the header? that's the first thing to take
				if (header > 0) {
					if (header == VORBIS_HEADERS) {
						// prepare vorbis structures
						vorbis_info_init(&vi);
						vorbis_comment_init(&vc);
					}
					// we need to do this 3 times, for all 3 vorbis headers!
					// add data to header structure
					if(vorbis_synthesis_headerin(&vi,&vc,&op) < 0) {
						// error case; not a vorbis header
                        fprintf(stderr, "Err: not a vorbis header.");
						err = INVALID_HEADER;
						break;
					}
					// signal next header
					header--;
                    
					// we got all 3 vorbis headers
					if (header == 0) {
                        fprintf(stderr, "Vorbis header data: ver:%d ch:%d samp:%ld [%s]" ,  vi.version, vi.channels, vi.rate, vc.vendor);
						int i=0;
						for (i=0; i<vc.comments; i++) {
                            fprintf(stderr, "Header comment:%d len:%d [%s]", i, vc.comment_lengths[i], vc.user_comments[i]);
							char *c = vc.user_comments[i];
							int len = vc.comment_lengths[i];
                            // keys we are looking for in the comments, careful if size if bigger than 10
							char keys[5][10] = { "title=", "artist=", "album=", "date=", "track=" };
							char *values[5] = { title, artist, album, date, track }; // put the values in these pointers
							int j = 0;
							for (j = 0; j < 5; j++) { // iterate all keys
								int keylen = strlen(keys[j]);
								if (!strncasecmp(c, keys[j], keylen )) strncpy(values[j], c + keylen, min(len - keylen , COMMENT_MAX_LEN));
							}
						}
						// init vorbis decoder
						if(vorbis_synthesis_init(&vd,&vi) != 0) {
							// corrupt header
                            fprintf(stderr, "Err: corrupt header.");
							err = INVALID_HEADER;
							break;
						}
						// central decode state
						vorbis_block_init(&vd,&vb);
                        
						// header ready , call player to pass stream details and init AudioTrack
                        [callback onStart:vi.rate trackChannels:vi.channels trackVendor:vc.vendor trackTitle:title trackArtist:artist trackAlbum:album trackDate:date trackName:track];
					}
				} // header decoding
                
				// while packets
                
				// check stream end
				if (ogg_page_eos(&og)) {
                    fprintf(stderr,  "Stream finished.");
					// clean up this logical bitstream;
					ogg_stream_clear(&os);
					vorbis_comment_clear(&vc);
					vorbis_info_clear(&vi);  // must be called last
                    
					// clear decoding structures
					vorbis_block_clear(&vb);
					vorbis_dsp_clear(&vd);
                    
					// attempt to go for re-initialization until EOF in data source
					err = SUCCESS;
                    
					inited = 0;
					break;
				}
			}
        	// page if
        } // while pages
        
        //free(buffer);
        
    }
    
    
    
    // ogg_page and ogg_packet structs always point to storage in libvorbis.  They're never freed or manipulated directly
	vorbis_comment_clear(&vc);
	vorbis_info_clear(&vi);  // must be called last
    
	vorbis_block_clear(&vb);
	vorbis_dsp_clear(&vd);
    
    
    // OK, clean up the framer
    ogg_sync_clear(&oy);
    
    [callback onStop];
    
    return err;
    
}
