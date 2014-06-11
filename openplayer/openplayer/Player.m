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

-(void)onStart:(long)sampleRate trackChannels:(long)channels trackVendor:(char *)pvendor trackTitle:(char *)ptitle trackArtist:(char *)partist trackAlbum:(char *)palbum trackDate:(char *)pdate trackName:(char *)ptrack
{
    NSLog(@"on start %lu %lu %s %s %s %s %s %s", sampleRate, channels, pvendor, ptitle, partist, palbum, pdate, ptrack);
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        
        // aici initializam audiocontroller-ul . Va trebui sa pasam corect parametrii primiti in onStart: frecventa si nr canale
        iosAudio = [[AudioController alloc] initWithSampleRate:sampleRate channels:channels];
        [iosAudio start];

        
        if (error != nil) {
            NSLog(@" audioEngine error: %@",error);
        }
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
    NSLog(@"Test callback !!!");
    [iosAudio stop];
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
    // log data
    if (lastLibraryOutputTimestamp != 0) {
        double timeSpent = [NSDate timeIntervalSinceReferenceDate] - lastLibraryOutputTimestamp;
        NSLog(@" decoder output: %d bytes in %f ns",amount,timeSpent);
    }
    lastLibraryOutputTimestamp = [NSDate timeIntervalSinceReferenceDate];
    
    NSLog(@"Write %d from opusPlayer", amount);

    /*NSString *file3= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/testfile6.dat"];
    FILE *f3 = fopen([file3 UTF8String], "ab");
    fwrite(pcmData, 2, amount, f3);
    fclose(f3);*/

    
    // just a random buffer, will crash when filled
    if (srcbuffer1 == nil ) {
        srcbuffer1 = (short *) malloc(1920*1024*10);
    }
    memcpy(srcbuffer1 + bufsize1, pcmData, amount * 2);
    bufsize1 += amount;
    
}


@end
