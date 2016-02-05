//
//  RTTinyPNGWebAPIPlugin.m
//  RTTinyPNGWebAPIPlugin
//
//  Created by benfen on 16/2/4.
//  Copyright © 2016年 Shiqu. All rights reserved.
//

#import "RTTinyPNGWebAPIPlugin.h"

#import "RTImageController.h"

@interface RTTinyPNGWebAPIPlugin()
@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, strong) RTImageController *imageController;
@end

@implementation RTTinyPNGWebAPIPlugin

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        
        self.imageController = [[RTImageController alloc] initWithWindowNibName:NSStringFromClass([RTImageController class])];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onLaunch:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onClose:)
                                                     name:NSApplicationWillResignActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)onLaunch:(NSNotification*)notif
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"File"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Tiny PNG"
                                                                action:@selector(showWindow:)
                                                         keyEquivalent:@"T"];
        [actionMenuItem setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
        [actionMenuItem setTarget:self.imageController];
        [[menuItem submenu] addItem:actionMenuItem];
    }
}

- (void)onClose:(NSNotification *)notif
{
    [self.imageController close];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
