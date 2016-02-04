//
//  RTTinyPNGWebAPIPlugin.h
//  RTTinyPNGWebAPIPlugin
//
//  Created by benfen on 16/2/4.
//  Copyright © 2016年 Shiqu. All rights reserved.
//

#import <AppKit/AppKit.h>

@class RTTinyPNGWebAPIPlugin;

static RTTinyPNGWebAPIPlugin *sharedPlugin;

@interface RTTinyPNGWebAPIPlugin : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end