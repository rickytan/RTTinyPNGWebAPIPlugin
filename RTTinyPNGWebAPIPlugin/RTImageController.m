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

- (void)drawInteriorWithFrame:(NSRect)cellFrame
                       inView:(NSView *)controlView
{
    NSSize size = [self.checkBox cellSize];
    
    NSRect rect = NSMakeRect(cellFrame.origin.x + (cellFrame.size.width - size.width) / 2,
                             cellFrame.origin.y + (cellFrame.size.height - size.height) / 2,
                             size.width, size.height);
    [self.checkBox drawInteriorWithFrame:rect
                                  inView:controlView];
}

@end

@interface RTImageController () <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *apiKeyField;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSPopUpButton *concurrencyButton;
@property (weak) IBOutlet NSTextField *statsLabel;

@property (strong) RTHeaderCell *selectAllCell;

@property (nonatomic, strong) NSMutableArray *imageItems;
@property (assign) NSUInteger totalBytes, optimizedTotalBytes;
@property (nonatomic, assign, getter=isLoading) BOOL loading;
@property (assign, getter=isProcessing) BOOL processing;
@end

@implementation RTImageController

static NSString *const TINY_PNG_HOST = @"https://api.tinify.com/shrink";
static void *observingContext = &observingContext;
static NSOperationQueue *RTImageCompressingQueue() {
    static NSOperationQueue * _theQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _theQueue = [[NSOperationQueue alloc] init];
        _theQueue.maxConcurrentOperationCount = 2;
    });
    return _theQueue;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    {
        RTHeaderCell *cell = [[RTHeaderCell alloc] init];
        self.selectAllCell = cell;
        self.tableView.tableColumns.firstObject.headerCell = cell;
    }
    
    [self reloadImages];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    
    if (self.isWindowLoaded)
        [self reloadImages];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if (context == observingContext) {
        if ([@"operationCount" isEqualToString:keyPath]) {
            if (RTImageCompressingQueue().operationCount == 0) {
                self.processing = NO;
            }
        }
    }
}

#pragma mark - Actions

- (void)onToggleSelectionAll:(id)sender
{
    if (self.selectAllCell.checkBox.state == NSOffState) {
        [self.imageItems enumerateObjectsUsingBlock:^(RTImageItem *item, NSUInteger idx, BOOL *stop) {
            item.selected = YES;
        }];
        self.selectAllCell.checkBox.state = NSOnState;
    }
    else if (self.selectAllCell.checkBox.state == NSOnState) {
        [self.imageItems enumerateObjectsUsingBlock:^(RTImageItem *item, NSUInteger idx, BOOL *stop) {
            item.selected = NO;
        }];
        self.selectAllCell.checkBox.state = NSOffState;
    }
    // Redraw the cell
    [self.tableView.headerView setNeedsDisplayInRect:[self.tableView.headerView headerRectOfColumn:0]];

    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.imageItems.count)]
                              columnIndexes:[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"Selection"]]];
    
}

- (IBAction)onMarkSelected:(id)sender
{
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        ((RTImageItem *)self.imageItems[idx]).selected = YES;
    }];
    [self.tableView reloadDataForRowIndexes:self.tableView.selectedRowIndexes
                              columnIndexes:[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"Selection"]]];
    [self.tableView deselectAll:sender];
}

- (IBAction)onMarkDeselected:(id)sender
{
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        ((RTImageItem *)self.imageItems[idx]).selected = NO;
    }];
    [self.tableView reloadDataForRowIndexes:self.tableView.selectedRowIndexes
                              columnIndexes:[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"Selection"]]];
    [self.tableView deselectAll:sender];
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
    NSInteger rol = tableView.clickedRow;
    NSInteger column = tableView.clickedColumn;
    if (rol < 0 && column == 0) {
        [self onToggleSelectionAll:self];
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

- (IBAction)onConcurrencyChanged:(id)sender {
    NSInteger value = [self.concurrencyButton.selectedItem.title integerValue];
    RTImageCompressingQueue().maxConcurrentOperationCount = value;
}

- (IBAction)onSelect:(NSButton *)checkBox {
    NSInteger row = [self.tableView rowForView:checkBox];
    if (row >= 0) {
        RTImageItem *item = self.imageItems[row];
        item.selected = !item.isSelected;
    }
}

- (IBAction)onShowHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://tinypng.com/developers"]];
}

- (IBAction)onStart:(id)sender {
    NSString *apiKey = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] stringForKey:@"TINY_PNG_APIKEY"];
    if (apiKey.length <= 0) {
        NSBeginAlertSheet(@"API key required!", @"OK", @"Show me where to find", nil, self.window, self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"Please input your Api key and hit ENTER");
        return;
    }
    
    NSString *base64encodedKey = [[[NSString stringWithFormat:@"api:%@", apiKey] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    NSString *auth = [NSString stringWithFormat:@"Basic %@", base64encodedKey];
    
    self.processing = YES;
    
    [RTImageCompressingQueue() addObserver:self
                                forKeyPath:@"operationCount"
                                   options:NSKeyValueObservingOptionNew
                                   context:observingContext];
    
    [self.imageItems enumerateObjectsUsingBlock:^(RTImageItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.selected) {
            [RTImageCompressingQueue() addOperationWithBlock:^{
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:TINY_PNG_HOST]
                                                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                                   timeoutInterval:8.f];
                request.timeoutInterval = 10.f;
                request.HTTPMethod = @"POST";
                [request setValue:auth
               forHTTPHeaderField:@"Authorization"];
                request.HTTPBodyStream = [NSInputStream inputStreamWithFileAtPath:obj.imagePath];
                
                // Call web api synchronizely
                
                NSHTTPURLResponse *response = nil;
                NSError *error = nil;
                
                NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                     returningResponse:&response
                                                                 error:&error];
                id json = nil;
                if (data) {
                    json = [NSJSONSerialization JSONObjectWithData:data
                                                           options:0
                                                             error:NULL];
                }
                
                
                if (response.statusCode == 201 && json) {
                    obj.imageSizeOptimized = [json[@"output"][@"size"] integerValue];
                    NSURL *compressURL = [NSURL URLWithString:json[@"output"][@"url"]];
                    if (compressURL && [[NSData dataWithContentsOfURL:compressURL] writeToFile:obj.imagePath
                                                                                    atomically:YES]) {
                        obj.state = RTImageOptimizeStateOptimized;
                        obj.selected = NO;
                        self.optimizedTotalBytes -= obj.imageSize - obj.imageSizeOptimized;
                    }
                }
                else {
                    obj.state = RTImageOptimizeStateFailed;
                    
                    if (error) {
                        // Api error, we should stop
                        if (json) {
                            [RTImageCompressingQueue() cancelAllOperations];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSBeginAlertSheet(json[@"error"] ?: error.localizedFailureReason, @"OK", nil, nil, self.window, nil, NULL, NULL, NULL, @"%@", json[@"message"] ?: error.localizedDescription);
                            });
                        }
                        // Network error, skip
                        else {
                            NSLog(@"%@", error);
                        }
                    }
                    // API call limit exceeded, we should stop
                    else if (response.statusCode == 429) {
                        [RTImageCompressingQueue() cancelAllOperations];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSBeginAlertSheet(json[@"error"], @"OK", nil, nil, self.window, nil, NULL, NULL, NULL, @"%@", json[@"message"]);
                        });
                    }
                    else {
                        NSLog(@"%@", response);
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateStats];
                    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:idx]
                                              columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.tableColumns.count)]];
                });
            }];
            
            obj.state = RTImageOptimizeStatePending;
            [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:idx]
                                      columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.tableColumns.count)]];
        }
    }];
}

- (IBAction)onCancel:(id)sender {
    self.processing = NO;
}

#pragma mark - Methods


- (void)sheetDidEnd:(NSWindow *)sheet
         returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertAlternateReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://tinypng.com/developers"]];
    }
}

- (void)setProcessing:(BOOL)processing
{
    _processing = processing;
    if (_processing) {
        self.startButton.enabled = NO;
        self.concurrencyButton.enabled = NO;
        self.tableView.enabled = NO;
        self.progressIndicator.hidden = NO;
        [self.progressIndicator startAnimation:self];
    }
    else {
        self.startButton.enabled = YES;
        self.concurrencyButton.enabled = YES;
        self.tableView.enabled = YES;
        self.progressIndicator.hidden = YES;
        [self.progressIndicator stopAnimation:self];
    }
}

- (NSMutableArray *)imageItems
{
    if (!_imageItems) {
        _imageItems = [NSMutableArray array];
    }
    return _imageItems;
}

- (void)setLoading:(BOOL)loading
{
    _loading = loading;
    if (_loading) {
        self.startButton.enabled = NO;
        self.progressIndicator.hidden = NO;
        [self.progressIndicator startAnimation:self];
    }
    else {
        self.startButton.enabled = YES;
        [self.progressIndicator stopAnimation:self];
        self.progressIndicator.hidden = YES;
    }
}

- (void)updateStats
{
    self.statsLabel.stringValue = [NSString stringWithFormat:@"%lu/%lu, Compress ratio:%.2f", (unsigned long)self.optimizedTotalBytes, (unsigned long)self.totalBytes, (float)1.f * self.optimizedTotalBytes / self.totalBytes];
}

- (void)reloadImages
{
    NSString *path = [RTWorkspace currentWorkspacePath].stringByDeletingLastPathComponent;
    if (!path || self.isLoading || self.isProcessing)
        return;
    
    self.loading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Find all png/jpg/jpeg image files
        NSArray *allowedImageTypes = @[@"png", @"jpg", @"jpeg"];
        
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
        NSString *relaventPath = nil;
        
        [self.imageItems removeAllObjects];
        self.totalBytes = self.optimizedTotalBytes = 0;
        
        BOOL allSelected = YES;
        while (relaventPath = [enumerator nextObject]) {
            if ([allowedImageTypes containsObject:relaventPath.pathExtension.lowercaseString]) {
                RTImageItem *item = [RTImageItem itemWithPath:[path stringByAppendingPathComponent:relaventPath]];
                item.selected = !item.hasOptimized;
                
                self.totalBytes += item.imageSize;
                if (item.imageSizeOptimized)
                    self.optimizedTotalBytes += item.imageSizeOptimized;
                else
                    self.optimizedTotalBytes += item.imageSize;
                
                if (!item.isSelected) {
                    allSelected = NO;
                }
                [self.imageItems addObject:item];
            }
        }
        [self.imageItems sortUsingDescriptors:self.tableView.sortDescriptors];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = NO;
            self.selectAllCell.state = NSOffState;
            if (allSelected)
                [self onToggleSelectionAll:self];
            
            [self updateStats];
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

- (void)clearImageItems
{
    [self.imageItems removeAllObjects];
    [self.tableView reloadData];
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
            cell.textField.objectValue = @(item.imageSizeOptimized);
            break;
        case 5:
            cell.textField.stringValue = [NSString stringWithFormat:@"%dx%d", (int)item.size.width, (int)item.size.height];
            break;
        case 6:
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

- (void)tableView:(NSTableView *)tableView
sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
    [self.imageItems sortUsingDescriptors:tableView.sortDescriptors];
    [tableView reloadData];
}

@end
