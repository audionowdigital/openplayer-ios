//
//  OpusPlayer.m
//  Open Player
//
//  Created by Florin Moisa on 27/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "ANDOpenPlayer.h"
#import "OpusDecoder.h"
#import "VorbisDecoder.h"

@interface ANDOpenPlayer()

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

@implementation ANDOpenPlayer


-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler typeOfPlayer:(int)type
{
    if (self = [super init]) {
        _playerEvents = [[ANDPlayerEvents alloc] initWithPlayerHandler:handler];
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
                
                case INVALID_HEADER:
                    NSLog(@"Invalid header error received");
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
    [_audio start];
}

-(void)pause
{
    if (![self isPlaying]) {
        NSLog(@"Player Error: stream must be playing before trying to pause it");
        return;
    }
    
    _state = STATE_READY_TO_PLAY;
    
    [_streamConnection pauseConnection];
    [_audio pause];
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

-(void)onStartReadingHeader {
    NSLog(@"onStartReadingHeader");
    _state = STATE_READING_HEADER;
}

// Called by the native decoder when we got the header data
-(void)onStart:(int)sampleRate trackChannels:(int)channels trackVendor:(char *)pvendor trackTitle:(char *)ptitle trackArtist:(char *)partist trackAlbum:(char *)palbum trackDate:(char *)pdate trackName:(char *)ptrack {
    NSLog(@"on start %d %d %s %s %s %s %s %s", sampleRate, channels, pvendor, ptitle, partist, palbum, pdate, ptrack);
    
    _sampleRate = sampleRate;
    _channels = channels;
    
    // init audiocontroller and pass freq and channels as parameters
    _audio = [[AudioController alloc] initWithSampleRate:sampleRate channels:channels];

    _state = STATE_READY_TO_PLAY;
    [self play];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *ns_vendor = [NSString stringWithUTF8String:pvendor];
        NSString *ns_title = [NSString stringWithUTF8String:ptitle];
        NSString *ns_artist = [NSString stringWithUTF8String:partist];
        NSString *ns_album = [NSString stringWithUTF8String:palbum];
        NSString *ns_date = [NSString stringWithUTF8String:pdate];
        NSString *ns_track = [NSString stringWithUTF8String:ptrack];
        [_playerEvents sendEvent:TRACK_INFO vendor:ns_vendor title:ns_title artist:ns_artist album:ns_album date:ns_date track:ns_track];
    });
}

// Called by the native decoder when decoding is finished (end of source or error)
-(void)onStop {
    _state = STATE_STOPPED;
    [_audio stop];
}

// Blocks the current thread
-(void)waitPlay {
    [waitPlayCondition lock];
    
    while (_state == STATE_READY_TO_PLAY) {
        [waitPlayCondition wait];
    }
    [waitPlayCondition unlock];
}

// Called when the decoder asks for encoded data to decode . A few blocking conditions apply here
-(int)onReadEncodedData:(char **)buffer ofSize:(long)amount {
    // block if paused
    [self waitPlay];
    
    // block until we need data
    while ([_audio getBufferFill] > 50) {
        [NSThread sleepForTimeInterval:0.1];
        NSLog(@"Circular audio buffer overfill, waiting..");
    }
    
    // block until we have data from the network
    NSData *data;
    NSError *error;
    do {
        data = [_streamConnection readBytesForLength:amount error:&error];
        if (data.length == 0) {
            [NSThread sleepForTimeInterval:1]; // will only affect the initial buffering time
        }
        if (error) {
            NSLog(@"Error reading from input stream");
            return 0;
        }
    } while (!error && data.length == 0);
    
    *buffer = (char *)[data bytes];
    return (int) data.length;
}

// Called when decoded data is available - we take it and write it to the circular buffer
-(void)onWritePCMData:(short *)pcmData ofSize:(int)amount {
    // block if paused
    [self waitPlay];
    NSLog(@"Write %d from opusPlayer", amount);
    
    // before writting any bytes, see if the buffer is not full. using the waitBuffer for that
    TPCircularBufferProduceBytes(&_audio->circbuffer, pcmData, amount * sizeof(short));
}


@end
