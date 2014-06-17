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
    
    NSString *urlString =
//    @"http://ai-radio.org:8000/radio.opus"; //stereo ok
  //  @"http://www.markosoft.ro/opus/02_Archangel.opus";
    @"http://www.pocketmagic.net/tmp3/02_Archangel.opus";
//    @"http://www.markosoft.ro/opus/countdown.opus"
    
   // @"http://repeater.xiph.org:8000/temporalfugue.opus";//mono stream!!
  //  @"http://repeater.xiph.org:8000/clock.opus"; //stereo ok
//    @"http://revolutionradio.ru:8000/live.ogg"; //vorbis
//    @"http://ice01.va.audionow.com:8000/radioamericaopus.ogg"; //stereo opus ok.
//    @"http://icecast.timlradio.co.uk/ar64.opus"; // not ok
//    @"http://icecast.timlradio.co.uk/ac96.opus"; //not ok
    //@"http://opus.ai-radio.org:8000/radio.opus";
    //http://radioserver1.delfa.net:80/256.opus";
    //http://ogg.ai-radio.org:8000/radio.ogg";

    //

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
