#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <ogg/ogg.h>
#include <opus.h>
#include <opus_header.h>

#ifndef _Included_org_xiph_opus_OpusDecoder
	#define _Included_org_xiph_opus_OpusDecoder
	#ifdef __cplusplus
	extern "C" {
	#endif

	// called to do the initialization
	int initJni(int debug0);

	//Starts the decoding from a vorbis bitstream to pcm
	int readDecodeWriteLoop(/*object OpusDataFeed*/);

	//Stops the Opus data feed
	void onStopDecodeFeed(/*jmethodID* stopMethodId*/);

	//Reads raw Opus data from the jni callback
	int onReadOpusDataFromOpusDataFeed(/*jmethodID* readOpusDataMethodId, char* buffer, jbyteArray* jByteArrayReadBuffer*/);

	//Writes the pcm data to the Java layer
	void onWritePCMDataFromOpusDataFeed(/*jmethodID* writePCMDataMethodId, ogg_int16_t* buffer, int bytes, jshortArray* jShortArrayWriteBuffer*/);

	//Starts the decode feed with the necessary information about sample rates, channels, etc about the stream
	void onStart(/*jmethodID* startMethodId, long sampleRate, long channels, char* vendor,
			char *title, char *artist, char *album, char *date, char *track*/);
	//Starts reading the header information
	void onStartReadingHeader(/*jmethodID* startReadingHeaderMethodId*/);

	//Inform player we are about to start a new iteration
	void onNewIteration(/*jmethodID* newIterationMethodId*/);

	#ifdef __cplusplus
	}
	#endif
#endif
