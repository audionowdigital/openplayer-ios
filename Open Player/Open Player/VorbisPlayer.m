//
//  VorbisPlayer.m
//  Open Player
//
//  Created by Florin Moisa on 27/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "VorbisPlayer.h"

@interface VorbisPlayer()

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

@implementation VorbisPlayer

-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler
{
    if (self = [super init]) {
        _playerHandler = handler;
    }
    return self;
}

-(void)sendEvent:(PlayerEvent)event
{
    [_playerHandler onPlayerEvent:event withParams:nil];
}

-(void)sendEvent:(PlayerEvent)event withParam:(int)param
{
    NSDictionary *params = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:param] forKey:@"param"];
    [_playerHandler onPlayerEvent:event withParams:params];
}

-(void)sendEvent:(PlayerEvent)event vendor:(NSString *)vendor title:(NSString *)title artist:(NSString *)artist album:(NSString *)album date:(NSString *)date track:(NSString *)track
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"vendor"] = vendor;
    params[@"title"] = title;
    params[@"artist"] = artist;
    params[@"album"] = album;
    params[@"date"] = date;
    params[@"track"] = track;
    [_playerHandler onPlayerEvent:event withParams:params];
}



-(void)setDataSource:(NSURL *)sourceUrl streamSize:(long)byteCount streamLength:(NSTimeInterval)length
{
    if (![self isStopped]) {
        NSLog(@"Player Error: stream must be stopped before setting a data source");
        return;
    }
    
    _inputStream = [NSInputStream inputStreamWithURL:sourceUrl];
    _streamSize = byteCount;
    _streamLength = length;
    
    int result;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        // TODO: call here the native library function to start decoding from inputStream
        // result = OpusDecoder.readDecodeWriteLoop(decodeFeed);
        
        // send events on main thread
        dispatch_async(dispatch_get_main_queue(), ^{

            switch (result) {
                
                case SUCCESS:
                    NSLog(@"Successfully finished decoding");
                    [self sendEvent:PLAYING_FINISHED];
                    break;
                
                case NOT_A_HEADER:
                    NSLog(@"Not a header error received");
                    [self sendEvent:PLAYING_FAILED];
                    break;
                    
                case CORRUPT_HEADER:
                    NSLog(@"Corrupt header error received");
                    [self sendEvent:PLAYING_FAILED];
                    break;
                    
                case DECODE_ERROR:
                    NSLog(@"Decoding error received");
                    [self sendEvent:PLAYING_FAILED];
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
    
}

-(void)onStart
{
    
}

-(void)onStop
{
    
}

-(int)onReadEncodedData:(unsigned char [])buffer ofSize:(int)ammount
{
    return 0;
}

-(void)onWritePCMData:(short [])pcmData ofSize:(int)ammount
{
    
}


@end
