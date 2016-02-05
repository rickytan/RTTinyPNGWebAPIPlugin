//
//  RTImageController.m
//  RTTinyPNGWebAPIPlugin
//
//  Created by benfen on 16/2/4.
//  Copyright © 2016年 Shiqu. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "RTImageController.h"

#import "RTWorkspace.h"
#import "RTImageItem.h"

@interface RTHeaderCell : NSTableHeaderCell
@property (strong) NSButtonCell *checkBox;
@end

@implementation RTHeaderCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.checkBox = [[NSButtonCell alloc] init];
        self.checkBox.title = @"";
        self.checkBox.controlSize = NSRegularControlSize;
        self.checkBox.buttonType = NSSwitchButton;
    }
    return self;
}

- (void)setTarget:(id)target
{
    [super setTarget:target];
    self.checkBox.target = target;
}

- (void)setAction:(SEL)action
{
    [super setAction:action];
    self.checkBox.action = action;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSSize size = [self.checkBox cellSize];
    
    NSRect rect = NSMakeRect(cellFrame.origin.x + (cellFrame.size.width - size.width) / 2, cellFrame.origin.y + (cellFrame.size.height - size.height) / 2, size.width, size.height);
    [self.checkBox drawInteriorWithFrame:rect
                                  inView:controlView];
}

- (void)drawSortIndicatorWithFrame:(NSRect)cellFrame
                            inView:(NSView *)controlView
                         ascending:(BOOL)ascending
                          priority:(NSInteger)priority
{
    
}

@end

@interface RTImageController () <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *apiKeyField;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (strong) RTHeaderCell *selectAllCell;

@property (nonatomic, strong) NSMutableArray *imageItems;
@property (nonatomic, strong) NSOperationQueue *imageCompressingQueue;
@property (nonatomic, assign, getter=isLoading) BOOL loading;
@end

@implementation RTImageController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    {
        RTHeaderCell *cell = [[RTHeaderCell alloc] init];
        cell.target = self;
        cell.action = @selector(onToggleSelectionAll:);
        self.selectAllCell = cell;
        
        self.tableView.tableColumns.firstObject.headerCell = cell;
    }
    
    [self reloadImages];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    
    if (self.windowLoaded)
        [self reloadImages];
}

#pragma mark - Actions

- (void)onToggleSelectionAll:(id)sender
{
    if (self.selectAllCell.state == NSOffState) {
        [self.imageItems enumerateObjectsUsingBlock:^(RTImageItem *item, NSUInteger idx, BOOL * _Nonnull stop) {
            item.selected = YES;
        }];
        self.selectAllCell.state = NSOnState;
    }
    else if (self.selectAllCell.state == NSOnState) {
        [self.imageItems enumerateObjectsUsingBlock:^(RTImageItem *item, NSUInteger idx, BOOL * _Nonnull stop) {
            item.selected = NO;
        }];
        self.selectAllCell.state = NSOffState;
    }
    [self.tableView.headerView setNeedsDisplay:YES];
    if (self.imageItems.count) {
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.imageItems.count - 1)]
                                  columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}

- (IBAction)onMarkSelected:(id)sender
{
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        ((RTImageItem *)self.imageItems[idx]).selected = YES;
    }];
}

- (IBAction)onMarkDeselected:(id)sender
{
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        ((RTImageItem *)self.imageItems[idx]).selected = NO;
    }];
}

- (IBAction)onViewInFinder:(id)sender
{
    NSInteger row = [self.tableView rowForView:sender];
    if (row >= 0) {
        RTImageItem *item = self.imageItems[row];
        [[NSWorkspace sharedWorkspace] selectFile:item.imagePath
                         inFileViewerRootedAtPath:item.imagePath.stringByDeletingLastPathComponent];
    }
}

- (IBAction)onClickHeader:(NSTableView *)tableView {
    NSPoint point = [tableView.headerView convertPoint:[NSEvent mouseLocation]
                                              fromView:nil];
    NSInteger column = [tableView.headerView columnAtPoint:point];
    if (column == 0) {
        id target = self.selectAllCell.target;
        SEL action = self.selectAllCell.action;
        if (target && action && [target respondsToSelector:action]) {
            [target performSelector:action
                         withObject:self.selectAllCell];
        }
    }
}

- (IBAction)onDoubleClickRow:(NSTableView *)tableView {
    if ([tableView selectedRow] >= 0) {
        RTImageItem *item = self.imageItems[tableView.selectedRow];
        item.selected = !item.isSelected;
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tableView.selectedRow]
                                  columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}

- (IBAction)onSelect:(NSButton *)checkBox {
    NSInteger row = [self.tableView rowForView:checkBox];
    if (row >= 0) {
        RTImageItem *item = self.imageItems[row];
        item.selected = !item.isSelected;
    }
}

#pragma mark - Methods

- (NSMutableArray *)imageItems
{
    if (!_imageItems) {
        _imageItems = [NSMutableArray array];
    }
    return _imageItems;
}

- (NSOperationQueue *)imageCompressingQueue
{
    if (!_imageCompressingQueue) {
        _imageCompressingQueue = [[NSOperationQueue alloc] init];
    }
    return _imageCompressingQueue;
}

- (void)setLoading:(BOOL)loading
{
    _loading = loading;
    if (_loading) {
        self.progressIndicator.hidden = NO;
        [self.progressIndicator startAnimation:self];
    }
    else {
        [self.progressIndicator stopAnimation:self];
        self.progressIndicator.hidden = YES;
    }
}

- (void)reloadImages
{
    NSString *path = [RTWorkspace currentWorkspacePath].stringByDeletingLastPathComponent;
    if (!path || self.isLoading)
        return;
    
    self.loading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
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
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            self.selectAllCell.state = NSOffState;
            [self onToggleSelectionAll:self];
            
            [self.tableView reloadData];
        });
    });
}

- (NSImage *)makeImageForState:(RTImageOptimizeState)state
{
    NSString *imageNames[] = {
        @"NSStatusNone",
        @"NSStatusPartiallyAvailable",
        @"NSStatusAvailable",
        @"NSStatusUnavailable",
    };
    return [NSImage imageNamed:imageNames[state]];
}

#pragma mark - NSTableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.imageItems.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSInteger col = [tableView.tableColumns indexOfObject:tableColumn];
    RTImageItem *item = self.imageItems[row];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier
                                                        owner:self];
    cell.wantsLayer = YES;
    switch (col) {
        case 0:
        {
            ((NSButton *)cell).state = item.isSelected ? NSOnState : NSOffState;
        }
            break;
        case 1:
            cell.imageView.image = item.imageIcon;
            cell.textField.stringValue = item.imageName;
            cell.toolTip = item.imageName;
            break;
        case 2:
            cell.textField.stringValue = item.imagePath;
            cell.toolTip = item.imagePath;
            break;
        case 3:
            cell.textField.objectValue = @(item.imageSize);
            break;
        case 4:
            cell.textField.stringValue = [NSString stringWithFormat:@"%dx%d", (int)item.size.width, (int)item.size.height];
            break;
        case 5:
        {
            // cell.textField.stringValue = item.hasOptimized ? @"✔︎" : @"✘";
            cell.imageView.image = [self makeImageForState:item.state];
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
    [self.imageItems sortUsingDescriptors:tableView.sortDescriptors];
    [tableView reloadData];
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
