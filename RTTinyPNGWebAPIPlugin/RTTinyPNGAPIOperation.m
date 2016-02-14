//
//  RTTinyPNGAPIOperation.m
//  RTTinyPNGWebAPIPlugin
//
//  Created by benfen on 16/2/5.
//  Copyright © 2016年 Shiqu. All rights reserved.
//

#import "RTTinyPNGAPIOperation.h"

static NSString *const TINY_PNG_HOST = @"https://api.tinify.com/shrink";


@interface RTTinyPNGAPIOperation () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSString *apikey;
@property (nonatomic, copy) NSString *imagePath;
@property (nonatomic, copy) NSString *savePath;
@property (nonatomic, strong) NSOutputStream *writeStream;
@end

@implementation RTTinyPNGAPIOperation

- (instancetype)initWithAPIKey:(NSString *)apikey imagePath:(NSString *)imagePath
{
    return [self initWithAPIKey:apikey imagePath:imagePath savePath:imagePath];
}

- (instancetype)initWithAPIKey:(NSString *)apikey
                     imagePath:(NSString *)imagePath
                      savePath:(NSString *)savePath
{
    self = [super init];
    if (self) {
        self.apikey = apikey;
        self.imagePath = imagePath;
        self.savePath = savePath;
    }
    return self;
}

- (void)main
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:TINY_PNG_HOST]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:8.f];
    request.HTTPMethod = @"POST";
    request.HTTPBodyStream = [[NSInputStream alloc] initWithFileAtPath:self.imagePath];
    
    NSString *base64encodedKey = [[[NSString stringWithFormat:@"api:%@", self.apikey] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    NSString *auth = [NSString stringWithFormat:@"Basic %@", base64encodedKey];
    [request setValue:auth
   forHTTPHeaderField:@"Authorization"];
    request.HTTPBodyStream = [NSInputStream inputStreamWithFileAtPath:self.imagePath];

    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request
                                                                delegate:self];
    [connection start];
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"%@", response);
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
    NSLog(@"%@", data);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Finished!");
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

@end
