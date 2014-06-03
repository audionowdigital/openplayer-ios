#import "INativeInterface.h"

@interface OpusDecoder : NSObject{
    
}


	// called to do the initialization
	int initJni(int debug0);

	//Starts the decoding from a vorbis bitstream to pcm
	int readDecodeWriteLoop(id<INativeInterface> callback);

	//Stops the Opus data feed
	void onStopDecodeFeed();

	//Reads raw Opus data from the jni callback
	int onReadOpusDataFromOpusDataFeed(char* buffer, unsigned char* pByteReadBuffer);

	//Writes the pcm data to the Java layer
	void onWritePCMDataFromOpusDataFeed(ogg_int16_t* buffer, int bytes, short *pShortWriteBuffer);

	//Starts the decode feed with the necessary information about sample rates, channels, etc about the stream
	void onStart(long sampleRate, long channels, char* vendor,
			char *title, char *artist, char *album, char *date, char *track);

	//Starts reading the header information
	void onStartReadingHeader();

    void testLib();
        
        
