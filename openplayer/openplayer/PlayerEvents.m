//
//  PlayerEvents.m
//  openplayer
//
//  Created by Radu Motisan on 03/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import "PlayerEvents.h"

@implementation PlayerEvents

-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler {
    if (self = [super init]) {
        _playerHandler = handler;
    }
    return self;
}

-(void)sendEvent:(PlayerEvent)event {
    [_playerHandler onPlayerEvent:event withParams:nil];
}

-(void)sendEvent:(PlayerEvent)event withArrayPointer:(short *)barArrayPointer {
    NSDictionary *params = [NSDictionary dictionaryWithObject:[NSValue valueWithPointer:barArrayPointer] forKey:@"barStartPointers"];
    [_playerHandler onPlayerEvent:event withParams:params];
}

-(void)sendEvent:(PlayerEvent)event withParam:(int)param {
    NSDictionary *params = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:param] forKey:@"param"];
    [_playerHandler onPlayerEvent:event withParams:params];
}

-(void)sendEvent:(PlayerEvent)event vendor:(NSString *)vendor title:(NSString *)title artist:(NSString *)artist album:(NSString *)album date:(NSString *)date track:(NSString *)track {

    NSMutableDictionary *params = [NSMutableDictionary new];
    
    if (vendor != nil) {
        params[@"vendor"] = vendor;
    }
    if (title != nil) {
        params[@"title"] = title;
    }
    if (artist != nil) {
        params[@"artist"] = artist;
    }
    if (album != nil) {
        params[@"album"] = album;
    }
    if (date != nil) {
        params[@"date"] = date;
    }
    if (track != nil) {
        params[@"track"] = track;
    }
    [_playerHandler onPlayerEvent:event withParams:params];
}

@end
