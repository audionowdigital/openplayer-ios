//
//  PlayerEvents.h
//  openplayer
//
//  Created by Radu Motisan on 03/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum player_event{
    PLAYING_FINISHED = 1001,    // Playing finished handler message
    PLAYING_FAILED = 1002,      // Playing failed handler message
    READING_HEADER = 1003,      // Started to read the stream
    READY_TO_PLAY = 1004,       // Header was received, we are ready to play
    PLAY_UPDATE = 1005,         // Progress indicator, sent out periodically when playing
    TRACK_INFO = 1006           // Progress indicator, sent out periodically when playing
} PlayerEvent;

@protocol IPlayerHandler

//-(void)onPlayerEvent:(PlayerEvent) event;
//-(void)onPlayerEvent:(PlayerEvent) event withParam:(int)param;
-(void)onPlayerEvent:(PlayerEvent) event withParams:(NSDictionary *)params;

@end

@interface PlayerEvents : NSObject
{
    id<IPlayerHandler> _playerHandler;
}

    -(id)initWithPlayerHandler:(id<IPlayerHandler>)handler;
    -(void)sendEvent:(PlayerEvent)event;
    -(void)sendEvent:(PlayerEvent)event withParam:(int)param;
    -(void)sendEvent:(PlayerEvent)event
          vendor:(NSString *)vendor
           title:(NSString *)title
          artist:(NSString *)artist
           album:(NSString *)album
            date:(NSString *)date
           track:(NSString *)track;
@end
