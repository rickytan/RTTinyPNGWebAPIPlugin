//
//  RTImageController.m
//  RTTinyPNGWebAPIPlugin
//
//  Created by benfen on 16/2/4.
//  Copyright © 2016年 Shiqu. All rights reserved.
//

#import "RTImageController.h"

#import "RTWorkspace.h"
#import "RTImageItem.h"

@interface RTImageController () <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *apiKeyField;

@property (nonatomic, strong) NSMutableArray *imageItems;
@end

@implementation RTImageController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [self reloadImages];
}

#pragma mark - Methods

- (NSMutableArray *)imageItems
{
    if (!_imageItems) {
        _imageItems = [NSMutableArray array];
    }
    return _imageItems;
}

- (void)reloadImages
{
    NSString *path = [RTWorkspace currentWorkspacePath].stringByDeletingLastPathComponent;
    
    // Find all png/jpg/jpeg image files
    NSArray *allowedImageTypes = @[@"png", @"jpg", @"jpeg"];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
    NSString *relaventPath = nil;
    
    [self.imageItems removeAllObjects];
    while (relaventPath = [enumerator nextObject]) {
        if ([allowedImageTypes containsObject:relaventPath.pathExtension.lowercaseString]) {
            [self.imageItems addObject:[RTImageItem itemWithPath:[path stringByAppendingPathComponent:relaventPath]]];
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - NSTableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.imageItems.count;
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (nullable id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(nullable NSTableColumn *)tableColumn
                     row:(NSInteger)row
{
    NSInteger col = [tableView.tableColumns indexOfObject:tableColumn];
    switch (col) {
        case 0:
            return @YES;
            break;
        case 1:
            return @"Image.png";
            break;
        case 2:
            return @"Image/Path";
            break;
        case 3:
            return @NO;
            break;
        default:
            break;
    }
    return nil;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSInteger col = [tableView.tableColumns indexOfObject:tableColumn];
    RTImageItem *item = self.imageItems[row];
    NSTableCellView *cell = nil;
    switch (col) {
        case 0:
        {
            cell = [tableView makeViewWithIdentifier:@"Selection" owner:self];
            NSButton *checkBox = [cell viewWithTag:111];
            checkBox.state = !item.hasOptimized ? NSOnState : NSOffState;
        }
            break;
        case 1:
            cell = [tableView makeViewWithIdentifier:@"ImageName" owner:self];
            cell.imageView.image = item.imageIcon;
            cell.textField.stringValue = item.imageName;
            break;
        case 2:
            cell = [tableView makeViewWithIdentifier:@"ImagePath" owner:self];
            cell.textField.stringValue = item.imagePath;
            break;
        case 3:
        {
            cell = [tableView makeViewWithIdentifier:@"Optimized" owner:self];
            cell.textField.stringValue = item.hasOptimized ? @"√" : @"x";
            cell.textField.textColor = item.hasOptimized ? [NSColor greenColor] : [NSColor redColor];
        }
            break;
        default:
            break;
    }
    return cell;
}

#pragma mark -
#pragma mark ***** Optional Methods *****

/* NOTE: This method is not called for the View Based TableView.
 */
- (void)tableView:(NSTableView *)tableView
   setObjectValue:(nullable id)object
   forTableColumn:(nullable NSTableColumn *)tableColumn
              row:(NSInteger)row
{
    
}

/* Sorting support
 This is the indication that sorting needs to be done.  Typically the data source will sort its data, reload, and adjust selections.
 */
- (void)tableView:(NSTableView *)tableView
sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
    
}

- (NSString *)tableView:(NSTableView *)tableView
         toolTipForCell:(NSCell *)cell
                   rect:(NSRectPointer)rect
            tableColumn:(nullable NSTableColumn *)tableColumn
                    row:(NSInteger)row
          mouseLocation:(NSPoint)mouseLocation
{
    return tableColumn.title;
}



@end
