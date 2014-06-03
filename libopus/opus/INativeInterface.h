//
//  INativeInterface.h
//  libopus
//
//  Created by Florin Moisa on 02/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

@protocol INativeInterface

//Reads raw opus data from the jni callback
-(int)onReadEncodedData:(const char *)buffer ofSize:(long)amount;

//Writes the pcm data to the Java layer
-(void)onWritePCMData:(short *)pcmData ofSize:(int)amount;

//Starts reading the header information
-(void)onStartReadingHeader;

//Starts the decode feed with the necessary information about sample rates, channels, etc about the stream
-(void)onStart:(long)sampleRate trackChannels:(long)channels trackVendor:(char*)vendor trackTitle:(char *)title trackArtist:(char *)artist trackAlbum:(char *)album trackDate:(char *)date trackName:(char *)track;

//Stops the opus data feed
-(void)onStop;

@end

