//
//  StreamConnection.m
//  Open Player
//
//  Created by Catalin BORA on 29/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "StreamConnection.h"

#define kMaxBufferSize 65535    //64KB
#define kMinBufferSize 2048     //1KB

@interface StreamConnection()
@property (atomic,strong) NSMutableData *responseBuffer;
@property (atomic,strong) NSData *internalBuffer;
@property (nonatomic,strong) NSURLConnection *connection;
@property long downloadIndex;
@end

@implementation StreamConnection

-(void)podcastSize:(long long)value{
    if (_podcastSize == -1) {
        _podcastSize = value;
    }
}
// the queue
dispatch_queue_t queue;
dispatch_queue_t queue2;


-(id)initWithURL:(NSURL *)url error:(NSError **)error {

    self = [super init];
    if( self )
    {
        // start the queue
        queue = dispatch_queue_create("com.audio.now.streaming", NULL);
        queue2 = dispatch_queue_create("com.audio.now.streaming.queue", NULL);

        // init for the internal buffer
        self.responseBuffer = [[NSMutableData alloc] init];

        [self resetBuffers];

        streamUrl = url;

        [self startConnectionFromPosition:0];

        return self;

    } else {
        return nil;
    }

    return nil;
}

//-(NSData *)readAllBytesWithError:(NSError **)error{
//
//    if (self.responseBuffer.length == 0) {
//        NSString *domain = @"com.audio.now.emptyBuffer";
//        NSString *desc = NSLocalizedString(@"Internal buffer is empty", @"");
//        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
//
//        *error = [NSError errorWithDomain:domain
//                                     code:-104
//                                 userInfo:userInfo];
//        return nil;
//    } else {
//
//        __block NSData *returnBytes;
//        dispatch_sync(queue, ^{
//            // copy the internal buffer
//            returnBytes = [self.responseBuffer copy];
//            // empty the internal buffer
//            self.responseBuffer.length = 0;
//        });
//
//        // return the copy of the buffer
//        return returnBytes;
//    }
//}

-(NSData *)readBytesForLength:(NSUInteger)length error:(NSError **)error{

    // if there was an error and there is no data in the internal buffer or response buffer
    if (self.connectionError && self.internalBuffer == nil && self.responseBuffer.length == 0) {
    //there was an error with the connection
        // set the error
        *error = self.connectionError;
        // return an empty buffer;
        return [[NSData alloc] init];
    }

    // if the internal buffer is empty put stuff in it
    if (self.internalBuffer == nil) {

        // read in the internal buffer
        dispatch_sync(queue, ^{
            // copy the internal buffer
            self.internalBuffer = [self.responseBuffer copy];
            // empty the internal buffer
            self.responseBuffer.length = 0;
        });

    }

    // create the return buffer
    NSData *returnData;

    // if there are enough bytes in the internal buffer
    if (self.internalBuffer.length > length) {
        // fill the return buffer with data
        returnData = [self.internalBuffer subdataWithRange:NSMakeRange(0, length)];

        // cut the returned part from the internal buffer
        self.internalBuffer = [self.internalBuffer subdataWithRange:NSMakeRange(length, self.internalBuffer.length - length)];
    }else {
        // the internal buffer has less than asked for
        // return all it has and empty the buffer
        returnData = [self.internalBuffer copy];
        // empty the internalBuffer
        self.internalBuffer = nil;
    }

    if (self.connectionTerminated == YES && self.internalBuffer.length < kMaxBufferSize / 2)
    {
        [self startConnectionFromPosition:self.downloadIndex];
    }

    return returnData;
}

-(BOOL)seekToPosition:(NSUInteger)position error:(NSError **)error{

    if (self.podcastSize == -1) {

        NSString *domain = @"com.audio.now.noSeekPermittedError";
        NSString *desc = NSLocalizedString(@"Cannot do seek on the current stream", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };

        self.connectionError = [NSError errorWithDomain:domain
                                                   code:-106
                                               userInfo:userInfo];
        return NO;
    } else {

        [self resetBuffers];

        self.downloadIndex = position;

        BOOL seekState = [self startConnectionFromPosition:position];

         *error = self.connectionError;

        return seekState;

    }

}

-(BOOL)startConnectionFromPosition:(NSUInteger)position
{
    // change the connection terminated flag
    self.connectionTerminated = NO;
    // set the error flag to nil
    self.connectionError = nil;

    NSLog(@"Start connection form position: %d", position);

    if (position > self.podcastSize && self.podcastSize >= 0) {
        NSString *domain = @"com.audio.now.wrongSeekPosition";
        NSString *desc = NSLocalizedString(@"Cannot seek to the requested position", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };

        self.connectionError = [NSError errorWithDomain:domain
                                                   code:-107
                                               userInfo:userInfo];
        return NO;
    }

    // create a simple GET request from that url
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:streamUrl];
    [request setHTTPMethod:@"GET"];

    if(!request){
        NSString *domain = @"com.audio.now.requestError";
        NSString *desc = NSLocalizedString(@"Unable to create GET request", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };

        self.connectionError = [NSError errorWithDomain:domain
                                                   code:-101
                                               userInfo:userInfo];
        return NO;
    }

    // set the range where to jump to
    NSString *seekValue = [ NSString stringWithFormat:@"bytes=%lu-%lld",(unsigned long)position,self.podcastSize];
    [request addValue:seekValue forHTTPHeaderField:@"Range"];
    
    dispatch_async(queue2, ^{
        
        // create an asincron connection from the request
        self.connection = [[NSURLConnection alloc]
                           initWithRequest:request
                           delegate:self
                           startImmediately:NO];
        
        if (!self.connection) {
            NSString *domain = @"com.audio.now.connectionError";
            NSString *desc = NSLocalizedString(@"Unable to create connection", @"");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
            
            self.connectionError = [NSError errorWithDomain:domain
                                                       code:-103
                                                   userInfo:userInfo];
            return;
        }
        
        // need the runLoop here
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop]; // Get the runloop
        [self.connection scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];

        [self.connection start];

        NSLog(@" ****** REStarted connection on main thread:%@", [NSThread isMainThread] ? @"YES" : @" NO");

        [runLoop run];
    });

    return YES;
}


-(void)pauseConnection
{
    [self cancelConnection];
}

-(void)resumeConnection
{
    // this is called at every Play button pressed - not needed the first time
    
    [self startConnectionFromPosition:self.downloadIndex];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{

    // set the download size if it was not set
    if (self.podcastSize == -1) {
        self.podcastSize = [response expectedContentLength];

        if (self.podcastSize == -1) {
            NSLog(@"Stream appears to be LIVE from the returned size (-1)");
        } else {
            NSLog(@"Stream appears to be RECORDED from the returned size (%lld)", self.podcastSize);
        }
    }
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
     NSLog(@"didReceiveData: %lu Bytes", (unsigned long)data.length);

    // add data to the internal buffer
    // do this in a syncronized queue
    dispatch_sync(queue, ^{
        [self.responseBuffer appendData:data];

        // add the data length to the downloadIndex only it it's a stream not a podcast
        if (self.podcastSize != -1) {
            self.downloadIndex += data.length;
        }

        // if the total buffer size excedes the defined max buffer size
        if (self.responseBuffer.length > kMaxBufferSize) {

            if (self.podcastSize == -1) {
                NSLog(@"!!! Download rate for live stream is too high, cancel connection !!!");
            }

            [self cancelConnection];
        }
    });
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    // the connection had an error so save the error
    self.connectionError =  error;

    [self cancelConnection];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    // trigger for when the stream finishes either because it finished or it was stoped
    NSString *domain = @"com.audio.now.streamEnded";
    NSString *desc = NSLocalizedString(@"The stream has ended", @"");
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };

    self.connectionError = [NSError errorWithDomain:domain
                                               code:-105
                                           userInfo:userInfo];
    [self cancelConnection];
}

-(void)cancelConnection
{
    [self.connection cancel];
    self.connectionTerminated = YES;
}

-(void)stopStream{

    [self cancelConnection];
    [self resetBuffers];
}

-(void)resetBuffers{

    self.connectionError = nil;
    self.internalBuffer = nil;
    self.podcastSize = -1;
    self.downloadIndex = 0;

    dispatch_sync(queue, ^{
        self.responseBuffer.length = 0;
    });
}
@end
