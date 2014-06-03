//
//  INativeInterface.h
//  libopus
//
//  Created by Florin Moisa on 02/06/14.
//  Copyright (c) 2014 Xiph.org/Sudeium. All rights reserved.
//

@protocol INativeInterface

-(long)onReadEncodedData:(const char *[])buffer ofSize:(long)ammount;
-(void)onWritePCMData:(short [])pcmData ofSize:(int)ammount;
-(void)onStartReadingHeader;
-(void)onStart;
-(void)onStop;

@end

