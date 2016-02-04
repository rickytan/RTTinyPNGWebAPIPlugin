//
//  RTImageItem.h
//  RTTinyPNGWebAPIPlugin
//
//  Created by benfen on 16/2/4.
//  Copyright © 2016年 Shiqu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RTImageItem : NSObject
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, readonly) NSImage *imageIcon;

/**
 *  @author Ricky, 16-02-04 19:02:56
 *
 *  File size in bytes
 */
@property (nonatomic, assign) NSInteger imageSize;

/**
 *  @author Ricky, 16-02-04 19:02:06
 *
 *  File size after optimization
 */
@property (nonatomic, assign) NSInteger imageSizeOptimized;

@property (nonatomic, strong) NSDate *lastUpdateDate;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
@property (nonatomic, assign, getter=hasOptimized) BOOL optimized;

+ (instancetype)itemWithPath:(NSString *)path;

@end
