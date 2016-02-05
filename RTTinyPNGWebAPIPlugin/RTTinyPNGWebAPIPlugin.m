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
@property (nonatomic, strong) NSMenuItem *actionMenuItem;
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onLaunch:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onProjectChanged:)
                                                     name:@"PBXProjectDidChangeNotification"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onProjectOpen:)
                                                     name:@"PBXProjectDidOpenNotification"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onProjectClose:)
                                                     name:@"PBXProjectWillCloseNotification"
                                                   object:nil];
    }
    return self;
}

- (RTImageController *)imageController
{
    if (!_imageController) {
        _imageController = [[RTImageController alloc] initWithWindowNibName:NSStringFromClass([RTImageController class])];
    }
    return _imageController;
}

- (NSMenuItem *)actionMenuItem
{
    if (!_actionMenuItem) {
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"File"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Tiny PNG"
                                                                    action:@selector(showWindow:)
                                                             keyEquivalent:@"T"];
            [actionMenuItem setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
            [actionMenuItem setTarget:self.imageController];
            [[menuItem submenu] addItem:actionMenuItem];
            
            _actionMenuItem = actionMenuItem;
        }
    }
    return _actionMenuItem;
}

- (void)onLaunch:(NSNotification*)notif
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    self.actionMenuItem.enabled = NO;
}

- (void)onProjectOpen:(NSNotification *)notif
{
    self.actionMenuItem.enabled = YES;
}

- (void)onProjectChanged:(NSNotification *)notif
{
    [self.imageController close];
    self.imageController = nil;
    
    self.actionMenuItem.enabled = YES;
}

- (void)onProjectClose:(NSNotification *)notif
{
    [self.imageController close];
    self.imageController = nil;
    
    self.actionMenuItem.enabled = NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
