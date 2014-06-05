//
//  StreamConnection.m
//  Open Player
//
//  Created by Catalin BORA on 29/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "StreamConnection.h"

#define kMaxBufferSize 50000
#define kMinBufferSize 1000

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

-(id)initWithURL:(NSURL *)url error:(NSError **)error {

    self = [super init];
    if( self )
    {
        // create a simple GET request from the url
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        
        if(!request){
            NSString *domain = @"com.audio.now.requestError";
            NSString *desc = NSLocalizedString(@"Unable to create GET request", @"");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
            
             *error = [NSError errorWithDomain:domain
                                          code:-101
                                      userInfo:userInfo];
            return nil;
        }
        // init for the internal buffer
        self.responseBuffer = [[NSMutableData alloc] init];
        
        if(!self.responseBuffer) {
            NSString *domain = @"com.audio.now.internalBufferError";
            NSString *desc = NSLocalizedString(@"Unable to create internal buffer", @"");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
            
            *error = [NSError errorWithDomain:domain
                                         code:-102
                                     userInfo:userInfo];
            return nil;
        }
        
        // create an asincron connection from the request
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        if (!self.connection) {
            NSString *domain = @"com.audio.now.connectionError";
            NSString *desc = NSLocalizedString(@"Unable to create connection", @"");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
            
            *error = [NSError errorWithDomain:domain
                                         code:-103
                                     userInfo:userInfo];
            return nil;
        }
        
        // start the queue
        queue = dispatch_queue_create("com.audio.now.streaming", NULL);
        
        // start the connection
        [self.connection start];
        // change the connection terminated flag
        self.connectionTerminated = NO;
        
        // set the podcast size to -1 = not initialized
        self.podcastSize = -1;
        // set the internal error to nil
        self.connectionError = nil;
        // set the download index to 0
        self.downloadIndex = 0;
        
        return self;
        
    } else {
        return nil;
    }
    
    return nil;
}

-(NSData *)readAllBytesWithError:(NSError **)error{
    
    if (self.responseBuffer.length == 0) {
        NSString *domain = @"com.audio.now.emptyBuffer";
        NSString *desc = NSLocalizedString(@"Internal buffer is empty", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        
        *error = [NSError errorWithDomain:domain
                                     code:-104
                                 userInfo:userInfo];
        return nil;
    } else {
        
        __block NSData *returnBytes;
        dispatch_sync(queue, ^{
            // copy the internal buffer
            returnBytes = [self.responseBuffer copy];
            // empty the internal buffer
            self.responseBuffer.length = 0;
        });
       
        // return the copy of the buffer
        return returnBytes;
    }
}

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
    // internal buffer is new or empty and the connection is ok
        // read in the internal buffer
        dispatch_sync(queue, ^{
            // copy the internal buffer
            self.internalBuffer = [self.responseBuffer copy];
            // empty the internal buffer
            self.responseBuffer.length = 0;
        });
        
        //NSLog(@" - read response buffer into internal buffer for %lu bytes",(unsigned long)self.internalBuffer.length);
    }
    
    // create the return buffer
    NSData *returnData;
    
    // if there are enough bytes in the internal buffer
    if (self.internalBuffer.length > length) {
        // fill the return buffer with data
        returnData = [self.internalBuffer subdataWithRange:NSMakeRange(0, length)];
        
        // cut the returned part from the internal buffer
        // TODO: check might duplicate a byte
        self.internalBuffer = [self.internalBuffer subdataWithRange:NSMakeRange(length, self.internalBuffer.length - length)];
    }else {
        // the internal buffer has less than asked for
        // return all it has and empty the buffer
        returnData = [self.internalBuffer copy];
        // empty the internalBuffer
        self.internalBuffer = nil;
    }
    
   // NSLog(@" - read %lu bytes from the internal buffer",(unsigned long)returnData.length);
   // NSLog(@" - internal buffer droped to %lu bytes",(unsigned long) self.internalBuffer.length);
    
    if (self.connectionTerminated == YES) {
        // jump to the position
        [self localJumpToPosition:self.downloadIndex];
        // start the connection
        [self.connection start];
        // change the connection terminated flag
        self.connectionTerminated = NO;
        NSLog(@" - restarted the stream connection");
        
    }
    // return the data
    return returnData;
}

-(BOOL)seekToPosition:(NSUInteger)position error:(NSError **)error{
    
    BOOL seekState =  [self localJumpToPosition:position];
    
    if (seekState == YES) {
        
        // reset the buffer
        [self resetBuffers];
        *error = self.connectionError;
        
        // start the connection
        [self.connection start];
        
        // change the connection terminated flag
        self.connectionTerminated = NO;
        
        return YES;
    } else {
        *error = self.connectionError;
        return NO;
    }
}

-(BOOL)localJumpToPosition:(NSUInteger)position{
    
    // set the error flag to nil
    self.connectionError = nil;
    
    if (self.podcastSize == -1) {
        NSString *domain = @"com.audio.now.noSeekPermittedError";
        NSString *desc = NSLocalizedString(@"Cannot do seek on the current stream", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        
        self.connectionError = [NSError errorWithDomain:domain
                                                   code:-106
                                               userInfo:userInfo];
        return NO;
    }
    
    if (position > self.podcastSize) {
        NSString *domain = @"com.audio.now.wrongSeekPosition";
        NSString *desc = NSLocalizedString(@"Cannot seek to the requested position", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        
        self.connectionError = [NSError errorWithDomain:domain
                                                   code:-107
                                               userInfo:userInfo];
        return NO;
    }
    
    // get the url of the current connection
    NSURL *url = [self.connection.currentRequest URL];
    // create a simple GET request from that url
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    // set the range where to jump to
    NSString *seekValue = [ NSString stringWithFormat:@"bytes=%lu-%lld",(unsigned long)position,self.podcastSize];
    [request addValue:seekValue forHTTPHeaderField:@"Range"];
    
    if(!request){
        NSString *domain = @"com.audio.now.requestError";
        NSString *desc = NSLocalizedString(@"Unable to create GET request", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        
        self.connectionError = [NSError errorWithDomain:domain
                                                   code:-101
                                               userInfo:userInfo];
        return NO;
    }
    
    // create an asincron connection from the request
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    if (!self.connection) {
        NSString *domain = @"com.audio.now.connectionError";
        NSString *desc = NSLocalizedString(@"Unable to create connection", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        
        self.connectionError = [NSError errorWithDomain:domain
                                                   code:-103
                                               userInfo:userInfo];
        return NO;
    }
    
    
    return YES;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    
    // set the download size if it was not set
    if (self.podcastSize == -1) {
        self.podcastSize = [response expectedContentLength];
    }
    // if the podcastSize is -1 at this point
    // it means this is a livestream not a podcast
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // add data to the internal buffer
    // do this in a syncronized queue
    dispatch_sync(queue, ^{
        [self.responseBuffer appendData:data];
    });
    
    // add the data length to the downloadIndex only it it's a stream not a podcast
    if (self.podcastSize != -1) {
        self.downloadIndex += data.length;
    }
    
    // find the size of the combined buffes
    long totalBuffersSize = self.internalBuffer.length + self.responseBuffer.length;
    
    //NSLog(@" - totalBufferSize :%ld",totalBuffersSize);

    // if the total buffer size excedes the defined max buffer size
    
    if ( totalBuffersSize > kMaxBufferSize) {
        
        // it's not a stream
        // and the rest of the download is bigger than the min buffer size
        // or it's a stream
        if( (self.podcastSize != -1 && (self.podcastSize - self.downloadIndex) > kMinBufferSize) ) {
            [self.connection cancel];
            // change the connection terminated flag
            self.connectionTerminated = YES;
            
            NSLog(@" - stopped the connection");
        }
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    // the connection had an error so save the error
    self.connectionError =  error;
    //stop the stream
    [self.connection cancel];
    // change the connection terminated flag
    self.connectionTerminated = YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    // trigger for when the stream finishes either because it finished or it was stoped
    NSString *domain = @"com.audio.now.streamEnded";
    NSString *desc = NSLocalizedString(@"The stream has ended", @"");
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
    
    self.connectionError = [NSError errorWithDomain:domain
                                               code:-105
                                           userInfo:userInfo];
    //stop the stream
    [self.connection cancel];
    // change the connection terminated flag
    self.connectionTerminated = YES;
}

-(void)stopStream{
    //stop the stream
    [self.connection cancel];
    // change the connection terminated flag
    self.connectionTerminated = YES;
    //reset the buffers
    [self resetBuffers];
    // set the podcast size to -1 = not initialized
    self.podcastSize = -1;
    // set the internal error to nil
    self.connectionError = nil;
    // set the download index to 0
    self.downloadIndex = 0;
    
}

-(void)resetBuffers{
    // set the internal error to nil
    self.connectionError = nil;
    // clear all the buffers
    self.internalBuffer = nil;
    
    dispatch_sync(queue, ^{
        self.responseBuffer.length = 0;
    });
}
@end
