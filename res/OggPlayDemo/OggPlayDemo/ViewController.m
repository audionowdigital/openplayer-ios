//
//  ViewController.m
//  OggPlayDemo
//
//  Created by Danila Shikulin on 16/4/12.
//  Copyright (c) 2012 COS. All rights reserved.
//

#import "ViewController.h"
#import "PASoundMgr.h"
#import "PASoundListener.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize audioSource;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //init
    [PASoundMgr sharedSoundManager];
    [[[PASoundMgr sharedSoundManager] listener] setPosition:CGPointMake(0, 0)];
    self.audioSource = [[PASoundMgr sharedSoundManager] addSound:@"trance-loop" withExtension:@"ogg" position:CGPointMake(0, 0) looped:YES];
    
    // lower music track volume and play it
    [self.audioSource setGain:0.5f];
}
- (IBAction)play:(id)sender {
    [self.audioSource playAtListenerPosition];   
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
