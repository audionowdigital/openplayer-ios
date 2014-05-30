//
//  ToneGen.h
//  openplayer
//
//  Created by Florin Moisa on 30/05/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ToneGen : NSObject
@property (nonatomic) id delegate;
@property (nonatomic) double frequency;
@property (nonatomic) double sampleRate;
@property (nonatomic) double theta;
- (void)play:(float)ms;
- (void)play;
- (void)stop;
@end
