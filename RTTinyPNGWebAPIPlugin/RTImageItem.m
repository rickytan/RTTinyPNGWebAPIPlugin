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
static const char *RT_IMAGE_ORIGIN_SIZE_KEY = "com.tinypng.originSize";

@implementation RTImageItem
@synthesize optimized = _optimized;

+ (instancetype)itemWithPath:(NSString *)path
{
    RTImageItem *item = [[RTImageItem alloc] initWithPath:path];

    return item;
}

- (instancetype)initWithPath:(NSString *)filePath
{
    self = [super init];
    if (self) {
        self.imagePath = filePath;
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                                              error:NULL];
        if (attr) {
            self.lastUpdateDate = [attr fileModificationDate];
            
            if (self.hasOptimized) {
                NSInteger size = 0;
                getxattr(self.imagePath.UTF8String, RT_IMAGE_ORIGIN_SIZE_KEY, &size, sizeof(size), 0, 0);
                self.imageSize = size;
                self.imageSizeOptimized = [attr fileSize];
                
                // If fail to get origin size, use optimized size instead
                if (!size)
                    self.imageSize = self.imageSizeOptimized;
                _state = RTImageOptimizeStateOptimized;
            }
            else {
                self.imageSize = [attr fileSize];
                _state = RTImageOptimizeStateNormal;
            }
        }
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
        NSImageRep *rep = image.representations.firstObject;
        self.size = NSMakeSize(rep.pixelsWide, rep.pixelsHigh);
    }
    return self;
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

- (void)refreshState
{
    if (self.imagePath) {
        BOOL optimized = NO;
        setxattr(self.imagePath.UTF8String, RT_IMAGE_OPTIMIZED_KEY, &optimized, sizeof(optimized), 0, 0);
        
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:self.imagePath
                                                                              error:NULL];
        if (attr) {
            self.lastUpdateDate = [attr fileModificationDate];
            self.imageSize = [attr fileSize];
        }
    }
}

- (void)setState:(RTImageOptimizeState)state
{
    if (_state == state)
        return;
    
    _state = state;
    switch (_state) {
        case RTImageOptimizeStateOptimized:
        {
            if (self.imagePath) {
                BOOL optimized = YES;
                setxattr(self.imagePath.UTF8String, RT_IMAGE_OPTIMIZED_KEY, &optimized, sizeof(optimized), 0, 0);
                NSInteger size = self.imageSize;
                setxattr(self.imagePath.UTF8String, RT_IMAGE_ORIGIN_SIZE_KEY, &size, sizeof(size), 0, 0);
                
                NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:self.imagePath
                                                                                      error:NULL];
                if (attr) {
                    self.lastUpdateDate = [attr fileModificationDate];
                    self.imageSizeOptimized = [attr fileSize];
                }
            }
        }
            break;
            
        default:
            break;
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
