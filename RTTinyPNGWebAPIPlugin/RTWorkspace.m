//
//  IAWorkspace.m
//  RTImageAssets
//
//  Created by ricky on 14-12-10.
//  Copyright (c) 2014年 rickytan. All rights reserved.
//

#import "XcodeIDE.h"
#import "RTWorkspace.h"

@implementation RTWorkspace

+ (IDEWorkspaceWindowController *)keyWindowController
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    for (IDEWorkspaceWindowController *controller in workspaceWindowControllers) {
        if (controller.window.isKeyWindow) {
            return controller;
        }
    }
    return workspaceWindowControllers.firstObject;
}

+ (IDEWorkspace *)workspaceForKeyWindow
{
    return [[self keyWindowController] valueForKey:@"_workspace"];
}

+ (NSString *)currentWorkspacePath
{
    return [self workspaceForKeyWindow].representingFilePath.pathString;
}

@end
