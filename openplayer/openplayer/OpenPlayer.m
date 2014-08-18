//
//  OpusPlayer.m
//  Open Player
//
//  Created by Florin Moisa on 27/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "OpenPlayer.h"
#import "OpusDecoder.h"
#import "VorbisDecoder.h"
#import "AudioController.h"
#import "InputStreamConnection.h"
#import "PlayerTools.h"


@implementation OpenPlayer

#pragma mark - Section 1: Client interface - initialization and methods to control the Player -

-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler typeOfPlayer:(int)type enableLogs:(BOOL)useLogs
{
    if (self = [super init]) {
        _playerEvents = [[PlayerEvents alloc] initWithPlayerHandler:handler];
        _type = type;
        self.state = STATE_STOPPED;
        waitPlayCondition = [NSCondition new];
        LOGS_ENABLED = useLogs;
    }
    return self;
}


-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler typeOfPlayer:(int)type
{
    if (self = [self initWithPlayerHandler:handler typeOfPlayer:type enableLogs:NO]) {
        // nothing
    }
    return self;
}

-(void)setDataSource:(NSURL *)sourceUrl
{
    // for live source
    [self setDataSource:sourceUrl withSize:-1];
}


-(void)setDataSource:(NSURL *)sourceUrl withSize:(long)sizeInSeconds
{
    DLog(@"CMD: setDataSource call. state:%d", self.state);
    
    if (![self isStopped]) {
        DLog(@"Player Error: stream must be stopped before setting a data source");
        return;
    }
    
    srcSizeInSeconds = sizeInSeconds;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        inputStreamConnection = [[InputStreamConnection alloc] initWithUrl:sourceUrl];
        
        if (!inputStreamConnection) {
            DLog(@"Input stream could not be opened");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_playerEvents sendEvent:PLAYING_FAILED];
            });
                           
            return;
        }
        
        int result;
        
        if (_type == PLAYER_OPUS )
            result = opusDecodeLoop(self);
        else if (_type == PLAYER_VORBIS)
            result = vorbisDecodeLoop(self);
        
        // send events on main thread
        dispatch_async(dispatch_get_main_queue(), ^{

            switch (result) {
                
                case SUCCESS:
                    DLog(@"Successfully finished decoding");
                    [_playerEvents sendEvent:PLAYING_FINISHED];
                    break;
                
                case INVALID_HEADER:
                    DLog(@"Invalid header error received");
                    [_playerEvents sendEvent:PLAYING_FAILED];
                    break;
                    
                case DECODE_ERROR:
                    DLog(@"Decoding error received");
                    [_playerEvents sendEvent:PLAYING_FAILED];
                    break;
                
                case DATA_ERROR:
                    DLog(@"Decoding data error received");
                    [_playerEvents sendEvent:PLAYING_FAILED];
                    break;
            }
            
            [self stop];
        });
        
    });
}

-(void)play
{
    DLog(@"CMD: play call. state:%d", self.state);
    
    if (![self isReadyToPlay]) {
        DLog(@"Player Error: stream must be ready to play before starting to play");
        return;
    }
    
    self.state = STATE_PLAYING;
    [waitPlayCondition signal];
    
    DLog(@"Ready to play, go for stream and audio");
    
    [_audio start];
}

-(void)pause
{
    DLog(@"CMD: pause call. state:%d", self.state);
    
    if (![self isPlaying]) {
        DLog(@"Player Error: stream must be playing before trying to pause it");
        return;
    }
    
    self.state = STATE_READY_TO_PLAY;
    
    [_audio pause];
}

-(void)stop
{
    DLog(@"CMD: stop call. state:%d", self.state);
    
    if (![self isStopped]) {        
        _writtenPCMData = 0;
        _writtenMiliSeconds = 0;
        
        // keep the state change before close stream to avoid race condition which may call stop one more time from onStop() callback, which causes a crash in Audio Controller
        self.state = STATE_STOPPED;
    
        [inputStreamConnection closeStream];
        inputStreamConnection = nil;
        
        // empty the circular buffer than stop and dealloc all audio related objects
        [_audio emptyBuffer];
        [_audio stop];
    }
}

-(void)seekToPercent:(float)percent{
    DLog(@"Seek request: %f" , percent);
    
    if (srcSizeInSeconds == -1) {
        DLog(@"Player error: Stream is live, cannot seek");
        return;
    }
    
    if (!([self isPlaying] || [self isReadyToPlay])) {
        DLog(@"Player error: stream must be playing or paused.");
        return;
    }
    
    if ([self isPlaying]) {
        [_audio pause];
    }
    
    [_audio emptyBuffer];
    
    [inputStreamConnection seekTo:percent];
    _writtenMiliSeconds = percent * srcSizeInSeconds * 1000;
    
    if ([self isPlaying]) {
        [_audio start];
    }
}

#pragma mark - Section 2: Client interface - methods to read Player state -


-(BOOL)isReadyToPlay
{
    return self.state == STATE_READY_TO_PLAY;
}

-(BOOL)isPlaying
{
    return self.state == STATE_PLAYING;
}

-(BOOL)isStopped
{
    return self.state == STATE_STOPPED;
}

-(BOOL)isReadingHeader
{
    return self.state == STATE_READING_HEADER;
}


#pragma mark - Section 3: Decoder callback interface -

// Called when the decoder asks for encoded data to decode . A few blocking conditions apply here
-(int)onReadEncodedData:(char *)buffer ofSize:(long)amount {
    
    if ([self isStopped]) return 0;
        
    // block if paused
    [self waitPlay];
    
    DLog(@"Read %d from input stream", amount);
    
    // block until we need data
    while ([_audio getBufferFill] > 30) {
        
        // if player is paused, don't cycle indefinetly
        [self waitPlay];
        
        [NSThread sleepForTimeInterval:0.1];
        DLog(@"Circular audio buffer overfill, waiting..");
    }
    
    return [inputStreamConnection readData:buffer maxLength:amount];
    
}

// Called when decoded data is available - we take it and write it to the circular buffer
-(void)onWritePCMData:(short *)pcmData ofSize:(int)amount {
    // block if paused
    [self waitPlay];
    
    DLog(@"Write %d from opusPlayer", amount);
    
    // before writting any bytes, see if the buffer is not full. using the waitBuffer for that
    TPCircularBufferProduceBytes(&_audio->circbuffer, pcmData, amount * sizeof(short));
    
    // count data
    _writtenPCMData += amount;
    _writtenMiliSeconds += [self convertSamplesToMs:amount];
    
    //_writtenMiliSeconds = percent * srcSizeInSeconds * 1000;
    long length = [inputStreamConnection getSourceLength];
    if (srcSizeInSeconds > 0 && length > 0) {
        float div = (float)[inputStreamConnection getReadOffset] / (float)length;
        _writtenMiliSeconds = div * 1000 * srcSizeInSeconds;
    }
    
    //DLog(@"Florin %ld vs backup: %ld", _writtenMiliSeconds, _miliSecondsBackup );
    
    // limit the sending frequency to one second, or we get playback problems
    // send another message if time elapsed is more than 500msec from last event
    // must be done as ABS to cover the case of seeking to the past.
    if (abs(_writtenMiliSeconds - _miliSecondsBackup) > 500) {
        _miliSecondsBackup =_writtenMiliSeconds;
        // DLog(@"Written pcm:%d sec: %d", _writtenPCMData, _seconds);
        // send a notification of progress
        dispatch_async( dispatch_get_main_queue(), ^{
            [_playerEvents sendEvent:PLAY_UPDATE withParam:(_writtenMiliSeconds / 1000)];
        });
    }
}

// Called at the very beginning , just before we start reading the header
-(void)onStartReadingHeader {
    DLog(@"onStartReadingHeader");
    if ([self isStopped]) {
        self.state = STATE_READING_HEADER;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_playerEvents sendEvent:READING_HEADER];
        });
    }
}

// Called by the native decoder when we got the header data
-(void)onStart:(int)sampleRate trackChannels:(int)channels trackVendor:(char *)pvendor trackTitle:(char *)ptitle trackArtist:(char *)partist trackAlbum:(char *)palbum trackDate:(char *)pdate trackName:(char *)ptrack {
   
    DLog(@"onStart called %d %d %s %s %s %s %s %s, state:%d",
          sampleRate, channels, pvendor, ptitle, partist, palbum, pdate, ptrack, self.state);

    // we get this message ONLY for READINGHEADER player state at the very begining of reading the track
    if ([self isReadingHeader]) {
        
        // init audiocontroller and pass freq and channels as parameters
        _audio = [[AudioController alloc] initWithSampleRate:sampleRate channels:channels];
        
        _sampleRate = sampleRate;
        _channels = channels;

        self.state = STATE_READY_TO_PLAY;
        
        dispatch_async( dispatch_get_main_queue(), ^{
            [_playerEvents sendEvent:READY_TO_PLAY];
        });
    }
    
    // we get this message for both READINGHEADER and PLAYING player states
    dispatch_async( dispatch_get_main_queue(), ^{
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
    DLog(@"onStop called");
    [self stop];
}


-(void)setState:(PlayerState)state
{
    DLog(@"setState: %d", state);
//    DLog(@"%@",[NSThread callStackSymbols]);
    _state = state;
}

-(PlayerState)state{
    return _state;
}


#pragma mark - Section 4: helper functions  -

// Blocks the current thread
-(void)waitPlay {
    [waitPlayCondition lock];
    
    while (self.state == STATE_READY_TO_PLAY) {
        [waitPlayCondition wait];
    }
    [waitPlayCondition unlock];
}

-(int)convertSamplesToMs:(long)bytes sampleRate:(long)sampleRate channels:(long)channels {
    return (int)(1000L * bytes / (sampleRate * channels));
}

-(int)convertSamplesToMs:(long) bytes {
    return [self convertSamplesToMs:bytes sampleRate:_sampleRate channels:_channels];
}


@end
