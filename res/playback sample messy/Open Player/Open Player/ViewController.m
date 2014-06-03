//
//  ViewController.m
//  Open Player
//
//  Created by Catalin BORA on 27/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//
#import <CoreFoundation/CoreFoundation.h> 
#include <sys/socket.h> 
#include <netinet/in.h>

#import "ViewController.h"
#import "NSStreamAdditions.h"
//#define kStreamURL @"http://www.markosoft.ro/opus/02_Archangel.opus"
//#define kStreamURL @"http://icecast1.pulsradio.com:80/mxHD.ogg"

#define kStreamURL @"http://ice01.va.audionow.com:8000/SagalRadioServiceMed.mp3"

#define BUFFER_LEN 100

@interface ViewController ()
@property NSInputStream *iStream;
@property (atomic,strong) NSMutableData *response;
@end

@implementation ViewController

CFReadStreamRef readStream;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

void AcceptCallBack(
                    CFSocketRef socket,
                    CFSocketCallBackType type,
                    CFDataRef address,
                    const void *data,
                    void *info)
{
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    CFIndex bytes;
    UInt8 buffer[128];
    UInt8 recv_len = 0, send_len = 0;
    
    /* The native socket, used for various operations */
    CFSocketNativeHandle sock = *(CFSocketNativeHandle *) data;
    
    /* The punch line we stored in the socket context */
    char *punchline = info;
    
    /* Create the read and write streams for the socket */
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, sock,
                                 &readStream, &writeStream);
    
    if (!readStream || !writeStream) {
        close(sock);
        fprintf(stderr, "CFStreamCreatePairWithSocket() failed\n");
        return;
    }
    
    CFReadStreamOpen(readStream);
    CFWriteStreamOpen(writeStream);
    
    /* Wait for the client to finish sending the joke; wait for newline */
    memset(buffer, 0, sizeof(buffer));
    while (!strchr((char *) buffer, '\n') && recv_len < sizeof(buffer)) {
        bytes = CFReadStreamRead(readStream, buffer + recv_len,
                                 sizeof(buffer) - recv_len);
        if (bytes < 0) {
            fprintf(stderr, "CFReadStreamRead() failed: %ld\n", bytes);
            close(sock);
            return;
        }
        recv_len += bytes;
    }
    
    /* Send the punchline */
    while (send_len < (strlen(punchline+1))) {
        if (CFWriteStreamCanAcceptBytes(writeStream)) {
            bytes = CFWriteStreamWrite(writeStream,
                                       (unsigned char *) punchline + send_len,
                                       (strlen((punchline)+1) - send_len) );
            if (bytes < 0) {
                fprintf(stderr, "CFWriteStreamWrite() failed\n");
                close(sock);
                return;
            }
            send_len += bytes;
        }
        close(sock);
        CFReadStreamClose(readStream);
        CFWriteStreamClose(writeStream);
        return;
    }
}

- (IBAction)connectToSocket:(id)sender {
    CFSocketContext socketContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    CFSocketRef listeningSocket = CFSocketCreate(
                                                 kCFAllocatorDefault,
                                                 PF_INET,        // The protocol family for the socket
                                                 SOCK_DGRAM,    // The socket type to create
                                                 IPPROTO_UDP,    // The protocol for the socket. TCP vs UDP.
                                                 kCFSocketAcceptCallBack, //kCFSocketAcceptCallBack,  // New connections will be automatically accepted and the callback is called with the data argument being a pointer to a CFSocketNativeHandle of the child socket.
                                                 (CFSocketCallBack)AcceptCallBack, //(CFSocketCallBack)&serverAcceptCallback,
                                                 &socketContext );
    
    if (listeningSocket == NULL) {
        NSLog(@" error creating socket");
    }
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(80);
    //inet_pton(AF_INET, "88.191.226.56", &addr.sin_addr.s_addr);
    //CFDataRef connectAddr = CFDataCreate(NULL, (unsigned char *)&addr, sizeof(addr));
    //CFSocketError error = CFSocketConnectToAddress(listeningSocket, connectAddr, -1);
    
    NSData *address = [ NSData dataWithBytes: &addr length: sizeof(addr) ];
    if (CFSocketSetAddress(listeningSocket, (__bridge CFDataRef) address) != kCFSocketSuccess) {
        fprintf(stderr, "CFSocketSetAddress() failed\n");
        CFRelease(listeningSocket);
    }
    
    CFRunLoopSourceRef sourceRef =
    CFSocketCreateRunLoopSource(kCFAllocatorDefault, listeningSocket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
    CFRelease(sourceRef);
    
    printf("Socket listening on port %d\n", 80);
    
    CFRunLoopRun();
}

void clientCB(CFReadStreamRef stream, CFStreamEventType event, void *myPtr)
{
    switch(event) {
        case kCFStreamEventHasBytesAvailable:{
            UInt8 buf[BUFFER_LEN];
            CFIndex bytesRead = CFReadStreamRead(stream, buf, BUFFER_LEN);
            if (bytesRead > 0) {
                NSLog(@"Server has data to read!");
            }
            break;
        }
        case kCFStreamEventErrorOccurred:
            NSLog(@"A Read Stream Error Has Occurred!, %@",CFReadStreamCopyError(stream));
        case kCFStreamEventEndEncountered:
            NSLog(@"A Read Stream Event End!");
        default:
            break;
    }
}

- (IBAction)getData:(id)sender {
   
    CFWriteStreamRef writeStream;
    CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)kStreamURL);
    CFStreamCreatePairWithSocketToCFHost(kCFAllocatorDefault, host, 8000, &readStream, &writeStream);
    
    CFStreamClientContext myContext = {
        0,
        (__bridge void *)(self),
        (void *(*)(void *info))CFRetain,
        (void (*)(void *info))CFRelease,
        (CFStringRef (*)(void *info))CFCopyDescription
    };
    
    CFOptionFlags registeredEvents = kCFStreamEventHasBytesAvailable |
    kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered;
    
    if(CFReadStreamSetClient(readStream, registeredEvents, clientCB, &myContext))
    {
        CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    }
    
    if (!CFReadStreamOpen(readStream)) {
        NSLog(@"ERROR opening");
    }
}

- (IBAction)startStream:(id)sender {
    
    //input stream
    NSURL *url = [[NSURL alloc] initWithString:kStreamURL];
    
    NSLog(@" host: %@",[url host]);
    
    CFReadStreamRef readStream;
    
    NSLog(@" link the CFReadStream status:");
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)[url host], 8000, &readStream, nil);
    NSInputStream *inputStream = (__bridge_transfer NSInputStream *)readStream;
  
    [inputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
}

- (void)stream:(NSInputStream *)iStream handleEvent:(NSStreamEvent)event {
    BOOL shouldClose = NO;
    NSString *str = nil;
    switch(event) {
        case  NSStreamEventEndEncountered:
            NSLog(@"stream has ended");
            shouldClose = YES;
            // If all data hasn't been read, fall through to the "has bytes" event
            if(![self.iStream hasBytesAvailable]) break;
        case NSStreamEventHasBytesAvailable: ; // We need a semicolon here before we can declare local variables
            NSLog(@"stream got data ");
            uint8_t *buffer;
            NSUInteger length;
            BOOL freeBuffer = NO;
            // The stream has data. Try to get its internal buffer instead of creating one
            if(![iStream getBuffer:&buffer length:&length]) {
                // The stream couldn't provide its internal buffer. We have to make one ourselves
                buffer = malloc(BUFFER_LEN * sizeof(uint8_t));
                freeBuffer = YES;
                NSInteger result = [iStream read:buffer maxLength:BUFFER_LEN];
                if(result < 0) {
                    // error copying to buffer
                    break;
                }
                length = result;
            }
            
            str=[[NSString alloc] initWithBytes:buffer
                                                    length:length
                                                  encoding:NSUTF8StringEncoding];
            NSLog(@"The buffer contains :%@ of length:%d", str, length);
            
            // length bytes of data in buffer
            if(freeBuffer) free(buffer);
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"stream errors:%@",[iStream streamError]);
            // some other error
            shouldClose = YES;
            break;
        case NSStreamEventOpenCompleted:
            // initialization OK
            NSLog(@"initialization OK");
            break;
        case NSStreamEventHasSpaceAvailable:
            // There is space
            NSLog(@"there is space");
            break;
        case NSStreamEventNone:
            NSLog(@"there was an evet none");
            break;
    }
    if(shouldClose) [iStream close];
}

- (IBAction)connectToSocketTutorial:(id)sender {
    
    NSInputStream *iStream;
    NSOutputStream *oStream;
    uint portNo = 80;
    
    [NSStream getStreamsToHostNamed:kStreamURL
                               port:portNo
                        inputStream:&iStream
                       outputStream:&oStream];

}

- (IBAction)readNormalData:(id)sender {
    
    NSURL *url = [NSURL URLWithString:kStreamURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    self.response = [[NSMutableData alloc] init];
    
    NSURLConnection *conncetion = [NSURLConnection connectionWithRequest:request delegate:self];
    
    [conncetion start];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.response appendData:data];
}

- (IBAction)clearData:(id)sender {
    
    NSLog(@" current size of response: %u", self.response.length);
    NSLog(@" clear buffer");
    
    [self.response setLength:0];
    
}



@end
