//
//  OpusPlayer.h
//  Open Player
//
//  Created by Florin Moisa on 27/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamConnection.h"
#import "INativeInterface.h"

typedef enum player_state{
    STATE_READY_TO_PLAY = 0,    // player is ready to play, this is the state used also for Pause
    STATE_PLAYING = 1,          // player is currently playing
    STATE_STOPPED = 2,          // player is currently stopped (not playing)
    STATE_READING_HEADER = 3    // player is currently reading the header
} PlayerState;

typedef enum player_event{
    PLAYING_FINISHED = 1001,    // Playing finished handler message
    PLAYING_FAILED = 1002,      // Playing failed handler message
    READING_HEADER = 1003,      // Started to read the stream
    READY_TO_PLAY = 1004,       // Header was received, we are ready to play
    PLAY_UPDATE = 1005,         // Progress indicator, sent out periodically when playing
    TRACK_INFO = 1006           // Progress indicator, sent out periodically when playing
} PlayerEvent;

typedef enum decode_status{
    SUCCESS = 0,                // Everything was a success
    NOT_A_HEADER = -1,          // The data is not in the expected header format
    CORRUPT_HEADER = -2,        // The  header is corrupt
    DECODE_ERROR = -3           // Failed to decode
} DecodingStatus;

@protocol IPlayerHandler

-(void)onPlayerEvent:(PlayerEvent) event withParams:(NSDictionary *)params;

@end

@interface OpusPlayer : NSObject <INativeInterface>
{
    id<IPlayerHandler> _playerHandler;
    
    StreamConnection *_streamConnection;
    long _streamSize;
    NSTimeInterval _streamLength;       // seconds
}

-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler;

-(void)setDataSource:(NSURL *)sourceUrl;
-(void)play;
-(void)pause;
-(void)stop;

-(BOOL)isReadyToPlay;
-(BOOL)isPlaying;
-(BOOL)isStopped;
-(BOOL)isReadingHeader;

@property PlayerState state;

@end
