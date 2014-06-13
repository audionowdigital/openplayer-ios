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
        _state = STATE_STOPPED;
        waitPlayCondition = [NSCondition new];
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
    }
    
    _state = STATE_PLAYING;
    [waitPlayCondition signal];
    
    
    [_streamConnection resumeConnection];
    [iosAudio start];
}

-(void)pause
{
    if (![self isPlaying]) {
        NSLog(@"Player Error: stream must be playing before trying to pause it");
        return;
    }
    
    _state = STATE_READY_TO_PLAY;
    
    [_streamConnection pauseConnection];
    [iosAudio pause];
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
    
    _state = STATE_READING_HEADER;
}

-(void)onStart:(int)sampleRate trackChannels:(int)channels trackVendor:(char *)pvendor trackTitle:(char *)ptitle trackArtist:(char *)partist trackAlbum:(char *)palbum trackDate:(char *)pdate trackName:(char *)ptrack
{
    NSLog(@"on start %d %d %s %s %s %s %s %s", sampleRate, channels, pvendor, ptitle, partist, palbum, pdate, ptrack);
    
    _sampleRate = sampleRate;
    _channels = channels;
    
    NSError *error = nil;
    
    if (error != nil) {
        NSLog(@" audioEngine error: %@",error);
    }
    
    // aici initializam audiocontroller-ul . Va trebui sa pasam corect parametrii primiti in onStart: frecventa si nr canale
    iosAudio = [[AudioController alloc] initWithSampleRate:sampleRate channels:channels];
    
    _state = STATE_READY_TO_PLAY;
    [self play];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //TODO: if it's the first time send onStart, else send onTrackInfo
        NSString *ns_vendor = [NSString stringWithUTF8String:pvendor];
        NSString *ns_title = [NSString stringWithUTF8String:ptitle];
        NSString *ns_artist = [NSString stringWithUTF8String:partist];
        NSString *ns_album = [NSString stringWithUTF8String:palbum];
        NSString *ns_date = [NSString stringWithUTF8String:pdate];
        NSString *ns_track = [NSString stringWithUTF8String:ptrack];
        [_playerEvents sendEvent:TRACK_INFO vendor:ns_vendor title:ns_title artist:ns_artist album:ns_album date:ns_date track:ns_track];
        
    });
}

-(void)onStop
{
    _state = STATE_STOPPED;
    
    [iosAudio stop];
}


-(void)waitPlay
{
        
    [waitPlayCondition lock];
    
    while (_state == STATE_READY_TO_PLAY) {
        [waitPlayCondition wait];
    }
    
    [waitPlayCondition unlock];

}


-(int)onReadEncodedData:(char **)buffer ofSize:(long)amount
{
    NSError *error;
    NSData *data;
    
    [self waitPlay];
    
    // log demand

    if (lastNetworkRequestTimestamp != 0) {
        double timeSpent = [NSDate timeIntervalSinceReferenceDate] - lastNetworkRequestTimestamp;
        NSLog(@" decoder request: %ld bytes in %f ns",amount,timeSpent);
    }
    
    lastNetworkRequestTimestamp = [NSDate timeIntervalSinceReferenceDate];
    
    do {
        
        data = [_streamConnection readBytesForLength:amount error:&error];
        
        if (data.length == 0) {
            [NSThread sleepForTimeInterval:0.1]; // will only affect the initial buffering time
        }
        
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
    
    [self waitPlay];
    
    // log data
    if (lastLibraryOutputTimestamp != 0) {
        double timeSpent = [NSDate timeIntervalSinceReferenceDate] - lastLibraryOutputTimestamp;
        NSLog(@" decoder output: %d bytes in %f ns",amount,timeSpent);
    }
    lastLibraryOutputTimestamp = [NSDate timeIntervalSinceReferenceDate];
    
    NSLog(@"Write %d from opusPlayer", amount);

   /* // convert to mono
    short *monoBuffer;
    int len = amount / _channels;
    monoBuffer = (short *)malloc(len * sizeof(short));
    if (_channels == 2)
        for (int i = 0; i < len; i++) monoBuffer[i] = (pcmData[i * 2] + pcmData[i * 2 + 1]) / 2;
    else
        monoBuffer = pcmData;
    
    if (srcbuffer1 == nil ) {
        srcbuffer1 = (short *) malloc(1920*1024*10);
    }
    memcpy(srcbuffer1 + bufsize1, monoBuffer, len * sizeof(short));
    bufsize1 += len;*/
    
    if (srcbuffer1 == nil ) {
        srcbuffer1 = (short *) malloc(1920*1024*10);
    }
    memcpy(srcbuffer1 + bufsize1, pcmData, amount * sizeof(short));
    bufsize1 += amount;
    
    
    
    /*NSString *file3= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/testfile6.dat"];
    FILE *f3 = fopen([file3 UTF8String], "ab");
    fwrite(pcmData, 2, amount, f3);
    fclose(f3);*/

    
    // just a random buffer, will crash when filled
    
}


@end
