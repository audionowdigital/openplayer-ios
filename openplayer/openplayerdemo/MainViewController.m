//
//  MainViewController.m
//  openplayer
//
//  Created by Florin Moisa on 03/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import "MainViewController.h"


@interface MainViewController ()

@end

@implementation MainViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    player = [[Player alloc] initWithPlayerHandler:self typeOfPlayer:PLAYER_OPUS];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    @"http://ai-radio.org:8000/radio.opus";
//    @"http://www.markosoft.ro/opus/02_Archangel.opus"
//    @"http://www.markosoft.ro/opus/countdown.opus"
    
    NSString *urlString = @"http://ai-radio.org:8000/radio.opus";//http://www.markosoft.ro/opus/02_Archangel.opus";//

    self.urlLabel.text = urlString;
    self.infoLabel.text = @"Waiting for info";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)initBtnPressed:(id)sender {

    [player setDataSource:[NSURL URLWithString:self.urlLabel.text]];
}

- (IBAction)playBtnPressed:(id)sender {
    
    [player play];
}

- (IBAction)pauseBtnPressed:(id)sender {
    
    [player pause];
}

- (IBAction)stopBtnPressed:(id)sender {
    
    [player stop];
}

// We just got the track info
-(void)onPlayerEvent:(PlayerEvent)event withParams:(NSDictionary *)params {
    NSLog(@"Player event received in client. %d", event);
    if (event == TRACK_INFO) {
        NSString *vendor =  (NSString *)[params objectForKey:@"vendor"];
        NSString *title = (NSString *)[params objectForKey:@"title"];
        NSString *artist = (NSString *)[params objectForKey:@"artist"];
        NSString *album = (NSString *)[params objectForKey:@"album"];
        NSString *date = (NSString *)[params objectForKey:@"date"];
        NSString *track = (NSString *)[params objectForKey:@"track"];
    
        NSLog(@"Track info: vendor:%@ title:%@ artist:%@ album:%@ date:%@ track:%@",
                                vendor, title, artist, album, date, track);
        // only the main thread can make changes to the User Interface
        dispatch_async(dispatch_get_main_queue(), ^{
            //        _infoLabel.text = @"ok";        self.infoLabel.text= @"ok";        [self infoLabel].text = @"ok";
            // self.infoLabel =   
            
            self.infoLabel.text =
            [NSString stringWithFormat:@"vendor:%@ title:%@ artist:%@ album:%@ date:%@ track:%@", vendor , title , artist , album , date , track];
        });

        
    }
    
}



@end
