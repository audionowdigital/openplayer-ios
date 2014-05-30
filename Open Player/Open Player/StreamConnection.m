//
//  StreamConnection.m
//  Open Player
//
//  Created by Catalin BORA on 29/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import "StreamConnection.h"

@interface StreamConnection()
@property (atomic,strong) NSMutableData *responseBuffer;
@property (atomic,strong) NSData *internalBuffer;
@property (nonatomic,strong) NSURLConnection *connection;
@property (nonatomic,strong) NSError *connectionError;
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
        
        // set the podcast size to -1 = not initialized
        self.podcastSize = -1;
        // set the internal error to nil
        self.connectionError = nil;
        
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
        
        NSLog(@" - read response buffer into internal buffer for %d bytes",self.internalBuffer.length);
    }
    
    // create the return buffer
    NSData *returnData;
    
    // if there are enough bytes in the internal buffer
    if (self.internalBuffer.length > length) {
        // fill the return buffer with data
        returnData = [self.internalBuffer subdataWithRange:NSMakeRange(0, length)];
        
        // cut the returned part from the internal buffer
        // TODO: check might duplicate a byte
        self.internalBuffer = [self.internalBuffer subdataWithRange:NSMakeRange(length, self.internalBuffer.length)];
    }else {
        // the internal buffer has less than asked for
        // return all it has and empty the buffer
        returnData = [self.internalBuffer copy];
        // empty the internalBuffer
        self.internalBuffer = nil;
    }
    
    NSLog(@" - read %d bytes from the internal buffer",returnData.length);
    NSLog(@" - internal buffer droped to %d bytes",self.internalBuffer.length);
    
    // return the data
    return returnData;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    self.podcastSize = [response expectedContentLength];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // add data to the internal buffer
    // do this in a syncronized queue
    dispatch_sync(queue, ^{
        [self.responseBuffer appendData:data];
    });
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    // the connection had an error so save the error
    self.connectionError =  error;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    // trigger for when the stream finishes either because it finished or it was stoped
    NSString *domain = @"com.audio.now.streamEnded";
    NSString *desc = NSLocalizedString(@"The stream has ended", @"");
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
    
    self.connectionError = [NSError errorWithDomain:domain
                                               code:-105
                                           userInfo:userInfo];
}

-(void)stopStream{
    //stop the stream
    [self.connection cancel];
}

@end
