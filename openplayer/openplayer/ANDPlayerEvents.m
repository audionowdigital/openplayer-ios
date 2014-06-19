//
//  PlayerEvents.m
//  openplayer
//
//  Created by Radu Motisan on 03/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import "ANDPlayerEvents.h"

@implementation ANDPlayerEvents

-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler {
    if (self = [super init]) {
        _playerHandler = handler;
    }
    return self;
}

-(void)sendEvent:(PlayerEvent)event {
    [_playerHandler onPlayerEvent:event withParams:nil];
}

-(void)sendEvent:(PlayerEvent)event withParam:(int)param {
    NSDictionary *params = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:param] forKey:@"param"];
    [_playerHandler onPlayerEvent:event withParams:params];
}

-(void)sendEvent:(PlayerEvent)event vendor:(NSString *)vendor title:(NSString *)title artist:(NSString *)artist album:(NSString *)album date:(NSString *)date track:(NSString *)track {
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"vendor"] = vendor;
    params[@"title"] = title;
    params[@"artist"] = artist;
    params[@"album"] = album;
    params[@"date"] = date;
    params[@"track"] = track;
    [_playerHandler onPlayerEvent:event withParams:params];
}

@end
