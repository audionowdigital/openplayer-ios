//
//  AudioEngine.h
//  Open Player
//
//  Created by Catalin BORA on 03/06/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AudioEngine : NSObject
//@property (nonatomic) AudioStreamBasicDescription streamFormat;
@property (nonatomic, strong) NSMutableData *buffer;

-(id)initWithSampleRate:(int)sampleRate channels:(int)channels error:(NSError **)error;
-(BOOL)play;
//-(BOOL)pause;
-(BOOL)stop;

@end
