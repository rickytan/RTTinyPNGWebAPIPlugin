//
//  RTImageItem.m
//  RTTinyPNGWebAPIPlugin
//
//  Created by benfen on 16/2/4.
//  Copyright © 2016年 Shiqu. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sys/xattr.h>

#import "RTImageItem.h"

static const char *RT_IMAGE_OPTIMIZED_KEY = "com.tinypng.hasOptimized";

@implementation RTImageItem
@synthesize optimized = _optimized;

+ (instancetype)itemWithPath:(NSString *)path
{
    RTImageItem *item = [RTImageItem new];
    item.imagePath = path;
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                          error:NULL];
    if (attr) {
        item.lastUpdateDate = [attr fileModificationDate];
        
        if (item.hasOptimized)
            item.imageSizeOptimized = [attr fileSize];
        else
            item.imageSize = [attr fileSize];
    }
    return item;
}

- (NSImage *)imageIcon
{
    return [[NSWorkspace sharedWorkspace] iconForFile:self.imagePath];
}

- (BOOL)hasOptimized
{
    if (self.imagePath) {
        BOOL optimized = NO;
        getxattr(self.imagePath.UTF8String, RT_IMAGE_OPTIMIZED_KEY, &optimized, sizeof(optimized), 0, 0);
        _optimized = optimized;
    }
    return _optimized;
}

- (void)setOptimized:(BOOL)optimized
{
    if (_optimized != optimized) {
        _optimized = optimized;
        
        if (self.imagePath) {
            setxattr(self.imagePath.UTF8String, RT_IMAGE_OPTIMIZED_KEY, &optimized, sizeof(optimized), 0, 0);
            
            NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:self.imagePath
                                                                                  error:NULL];
            if (attr) {
                self.lastUpdateDate = [attr fileModificationDate];
                self.imageSizeOptimized = [attr fileSize];
            }
        }
    }
}

- (void)setImagePath:(NSString *)imagePath
{
    _imagePath = imagePath;
    if (!_imageName) {
        self.imageName = imagePath.pathComponents.lastObject;
    }
}

@end
