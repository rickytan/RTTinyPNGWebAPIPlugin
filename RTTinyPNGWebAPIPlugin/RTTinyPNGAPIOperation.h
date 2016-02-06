//
//  RTTinyPNGAPIOperation.h
//  RTTinyPNGWebAPIPlugin
//
//  Created by benfen on 16/2/5.
//  Copyright © 2016年 Shiqu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RTTinyPNGAPIOperation : NSOperation

- (instancetype)initWithAPIKey:(NSString *)apikey
                     imagePath:(NSString *)imagePath;
- (instancetype)initWithAPIKey:(NSString *)apikey
                     imagePath:(NSString *)imagePath
                      savePath:(NSString *)savePath;
@end
