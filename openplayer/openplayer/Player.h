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
#import "PlayerEvents.h"
#import "AudioController.h"
#import "CircularBuffer.h"

typedef enum player_state{
    STATE_READY_TO_PLAY = 0,    // player is ready to play, this is the state used also for Pause
    STATE_PLAYING = 1,          // player is currently playing
    STATE_STOPPED = 2,          // player is currently stopped (not playing)
    STATE_READING_HEADER = 3    // player is currently reading the header
} PlayerState;

typedef enum player_types {
    PLAYER_OPUS = 1,
    PLAYER_VORBIS = 2
} PlayerType;

typedef enum decode_status{
    SUCCESS = 0,                // Everything was a success
    NOT_A_HEADER = -1,          // The data is not in the expected header format
    CORRUPT_HEADER = -2,        // The  header is corrupt
    DECODE_ERROR = -3           // Failed to decode
} DecodingStatus;

@interface Player : NSObject <INativeInterface>
{
    //id<IPlayerHandler> _playerHandler;

    int _type, _sampleRate, _channels;
    CircularBuffer buffer;
    PlayerEvents *_playerEvents;
    StreamConnection *_streamConnection;
    NSCondition *waitPlayCondition;
    NSCondition *waitBufferCondition;
    
    long _streamSize;
    NSTimeInterval _streamLength;       // seconds
}

-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler typeOfPlayer:(int)type ;

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
