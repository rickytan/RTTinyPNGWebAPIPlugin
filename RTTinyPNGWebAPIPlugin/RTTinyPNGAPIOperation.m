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
    [request setValue:[NSString stringWithFormat:@"Basic %@", [[[NSString stringWithFormat:@"%@:%@", @"api", self.apikey] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn]]
   forHTTPHeaderField:@"Authorization"];
}

@end
