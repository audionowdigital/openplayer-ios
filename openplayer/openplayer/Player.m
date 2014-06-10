//
//  OpusPlayer.m
//  Open Player
//
//  Created by Florin Moisa on 27/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "Player.h"
#import "OpusDecoder.h"
#import "VorbisDecoder.h"

@interface Player()

-(void)sendEvent:(PlayerEvent)event;
-(void)sendEvent:(PlayerEvent)event
       withParam:(int)param;
-(void)sendEvent:(PlayerEvent)event
          vendor:(NSString *)vendor
           title:(NSString *)title
          artist:(NSString *)artist
           album:(NSString *)album
            date:(NSString *)date
           track:(NSString *)track;

@end

@implementation Player

double lastNetworkRequestTimestamp = 0;
double lastLibraryOutputTimestamp = 0;

-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler typeOfPlayer:(int)type
{
    if (self = [super init]) {
        _playerEvents = [[PlayerEvents alloc] initWithPlayerHandler:handler];
        _type = type;
        //_playerHandler = handler;
        _state = STATE_STOPPED;
       // audioManager = [Novocaine audioManager];

        
      //  sampleRate = 44100;
        
        
        
           }
    return self;
}



-(void)setDataSource:(NSURL *)sourceUrl
{
    if (![self isStopped]) {
        NSLog(@"Player Error: stream must be stopped before setting a data source");
        return;
    }
    
    NSError *error;
    
    _streamConnection = [[StreamConnection alloc] initWithURL:sourceUrl error:&error];

    if (error) {
        NSLog(@"Stream could not be initialized");
        //[self sendEvent:PLAYING_FAILED];
        [_playerEvents sendEvent:PLAYING_FAILED];
    }
    
    __block int result;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (_type == PLAYER_OPUS )
            result = opusDecodeLoop(self);
        else if (_type == PLAYER_VORBIS)
            result = vorbisDecodeLoop(self);
        
        // send events on main thread
        dispatch_async(dispatch_get_main_queue(), ^{

            switch (result) {
                
                case SUCCESS:
                    NSLog(@"Successfully finished decoding");
                    //[self sendEvent:PLAYING_FINISHED];
                    [_playerEvents sendEvent:PLAYING_FINISHED];
                    break;
                
                case NOT_A_HEADER:
                    NSLog(@"Not a header error received");
                    //[self sendEvent:PLAYING_FAILED];
                    [_playerEvents sendEvent:PLAYING_FAILED];
                    break;
                    
                case CORRUPT_HEADER:
                    NSLog(@"Corrupt header error received");
                    //[self sendEvent:PLAYING_FAILED];
                    [_playerEvents sendEvent:PLAYING_FAILED];
                    break;
                    
                case DECODE_ERROR:
                    NSLog(@"Decoding error received");
                    //[self sendEvent:PLAYING_FAILED];
                    [_playerEvents sendEvent:PLAYING_FAILED];
                    break;
                }

        });
        
    });
}

-(void)play
{
    if (![self isReadyToPlay]) {
        NSLog(@"Player Error: stream must be ready to play before starting to play");
        return;
    } else {
        //[_audioEngine play];
    }
}

-(void)pause
{
    if (![self isPlaying]) {
        NSLog(@"Player Error: stream must be playing before trying to pause it");
        return;
    }
}

-(void)stop
{
    [_streamConnection stopStream];
}

-(BOOL)isReadyToPlay
{
    return _state == STATE_READY_TO_PLAY;
}

-(BOOL)isPlaying
{
    return _state == STATE_PLAYING;
}

-(BOOL)isStopped
{
    return _state == STATE_STOPPED;
}

-(BOOL)isReadingHeader
{
    return _state == STATE_READING_HEADER;
}



-(void)onStartReadingHeader
{
    NSLog(@"onStartReadingHeader");
}

-(void)onStart:(long)sampleRate trackChannels:(long)channels trackVendor:(char *)vendor trackTitle:(char *)title trackArtist:(char *)artist trackAlbum:(char *)album trackDate:(char *)date trackName:(char *)track
{
    NSLog(@"on start %lu %lu %s %s %s %s %s %s", sampleRate, channels, vendor, title, artist, album, date, track);
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        //_audioEngine = [[AudioEngine alloc] initWithSampleRate:sampleRate channels:channels error:&error];
        
        iosAudio = [[AudioController alloc] init];
        
        [iosAudio start];
        
        if (error != nil) {
            NSLog(@" audioEngine error: %@",error);
        }

    });
}

-(void)onStop
{
    NSLog(@"Test callback !!!");
    [_player stop];
    
   // [_audioEngine stop];
}

-(int)onReadEncodedData:(char **)buffer ofSize:(long)amount
{
    NSError *error;
    NSData *data;
    
    // log demand

    if (lastNetworkRequestTimestamp != 0) {
        double timeSpent = [NSDate timeIntervalSinceReferenceDate] - lastNetworkRequestTimestamp;
        NSLog(@" decoder request: %ld bytes in %f ns",amount,timeSpent);
    }
    
    lastNetworkRequestTimestamp = [NSDate timeIntervalSinceReferenceDate];
    
    do {
        [NSThread sleepForTimeInterval:2];
        
        data = [_streamConnection readBytesForLength:amount error:&error];
        
        if (error) {
            NSLog(@"Error reading from input stream");
            return 0;
        }
    } while (!error && data.length == 0);
    
    NSLog(@"Read %lu encoded bytes from input stream.", (unsigned long)data.length);
    
    *buffer = (char *)[data bytes];
    
    return (int) data.length;
}

-(void)onWritePCMData:(short *)pcmData ofSize:(int)amount
{
    // TODO send pcm data to device's sound board
    
    // log data
    if (lastLibraryOutputTimestamp != 0) {
        double timeSpent = [NSDate timeIntervalSinceReferenceDate] - lastLibraryOutputTimestamp;
        NSLog(@" decoder output: %d bytes in %f ns",amount,timeSpent);
    }
    
    lastLibraryOutputTimestamp = [NSDate timeIntervalSinceReferenceDate];
    
    NSLog(@"Write %d from opusPlayer", amount);

    NSString *file3= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/testfile6.dat"];
    FILE *f3 = fopen([file3 UTF8String], "ab");
    fwrite(pcmData, 2, amount, f3);
    fclose(f3);

    
    _player = [[AVBufferPlayer alloc] initWithBuffer:pcmData frames:amount];
    
    [_player play];
    return;
    
    // copy incoming audio data to temporary buffer
    UInt32 size = min(amount, [iosAudio tempBuffer].mDataByteSize); // dont copy more data then we have, or then fits
    NSLog(@"Buf %d from opusPlayer", (unsigned int)[iosAudio tempBuffer].mDataByteSize);

	//memcpy([iosAudio tempBuffer].mData, pcmData, size);
    
    if (srcbuffer == nil ) {
        srcbuffer = (short *) malloc(amount);
        memcpy(srcbuffer, pcmData, amount);
        bufsize = amount;
        
    }
    
    
    NSString *file1= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/testfile.dat"];
//    file	NSPathStore2 *	@"/Users/radhoo/Library/Application Support/iPhone Simulator/7.1/Applications/A645981A-EF43-4D78-B0DC-9FD40B08B801/Documents/testfile.dat"	0x09a99ef0
    FILE *f = fopen([file1 UTF8String], "ab");
    fwrite(pcmData, 1, amount, f);
    fclose(f);

    NSString *file2= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/testfile2.dat"];
    FILE *f2 = fopen([file2 UTF8String], "ab");
    fwrite(pcmData, 2, amount, f2);
    fclose(f2);
    //exit(1);
    /*[_audioEngine.buffer appendBytes:pcmData length:ammount];
    
    NSLog(@"  WRITE: %d bytes to buffer -> buffer size up to %d ",ammount,_audioEngine.buffer.length);
    
    // ready to play only if we have data to fill 3 buffers
    if (_audioEngine.buffer.length > _audioEngine.internalBufferSize * 3) {
        
        [_audioEngine play];
        
        _state = 0;
    }*/
}


@end
