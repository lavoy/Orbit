//
//  PanelController.m
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBPanelController.h"
#import "ORBPanelBackgroundView.h"
#import "ORBStatusItemIconView.h"
#import "ORBMenuController.h"
#import "ORBPopUpButton.h"
#import "ORBTableView.h"
#import "ORBImageCellView.h"
#import "ORBTextCellView.h"
#import "ORBPanelFooterView.h"
#import <ADNKit/NSArray+ANKAdditions.h>
#import <mach/mach.h>
#import <mach/mach_time.h>


static NSTimeInterval const kORBPopoverOpenDuration = 0.15;
static NSTimeInterval const kORBPopoverCloseDuration = 0.15;
static NSUInteger const kORBFileRowsVisibleAtOnce = 11;
static CGFloat const kORBPopoverAnimationPositionOffset = 3.0;
static NSString *const kORBHasShownHelpKey = @"hasShownHelp";


@interface ORBPanelController ()

@property (assign) NSUInteger uploadingFilesCount;
@property (assign) BOOL isAllowedToFetchFiles;
@property (assign) BOOL isAllowedToFetchStorageSpace;
@property (assign) BOOL isAnimating;
@property (assign) BOOL isShowingFilterUI;

@property (strong) ORBStorageInfo *storageInfo;

- (IBAction)logIn:(id)sender;
- (IBAction)openFileInBrowser:(id)sender;
- (IBAction)deleteFile:(id)sender;
- (IBAction)copyFileLinkToClipboard:(id)sender;
- (IBAction)toggleFilterUI:(id)sender;
- (IBAction)filter:(id)sender;
- (IBAction)downloadFile:(id)sender;
- (IBAction)showFilesTabAction:(id)sender;
- (IBAction)startRenameForSelectedRow:(id)sender;

- (void)refreshStorageSpace;
- (void)refreshStorageSpaceLabel;

- (void)downloadFile:(ORBFileWrapper *)file toDirectory:(NSString *)directory completion:(void (^)(NSError *error))completion;

@end


@implementation ORBPanelController

- (id)initWithDataSource:(ORBDataSource *)dataSource {
    if (self = [super initWithWindowNibName:@"ORBPanelController"]) {
        self.isAllowedToFetchFiles = YES;
		self.isAllowedToFetchStorageSpace = YES;
		self.dataSource = dataSource;
        self.storageInfo = [[ORBStorageInfo alloc] init];
        [self window];
    }
    return self;
}


- (void)windowDidLoad {
	[[self window] setDelegate:self];
    
    [self.tableView setDoubleAction:@selector(openFileInBrowser:)];
    [self.tableView setTarget:self];
    [self.tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
	self.tableView.selectionPersistenceKeyPath = @"file.fileID";
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[self.tableView superview]];
    
    NSString *versionString = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    [self.versionTextFieldCell setTitle:versionString];
	
	NSMenuItem *topMenuItem = [[self.actionButton.menu itemAtIndex:0] copy];
	[((NSPopUpButtonCell *)self.actionButton.cell) setUsesItemFromMenu:NO];
	[((NSPopUpButtonCell *)self.actionButton.cell) setMenuItem:topMenuItem];
	self.actionButton.willShowMenu = ^(void) {
		return [ORBMenuController mainMenuForPopUpButton];
	};
	
	__weak ORBPanelController *weakSelf = self;
	self.panel.eventDidOccur = ^(NSResponder *responder, NSEvent *event, BOOL *shouldBlock) {
		if (event.type == NSKeyDown && self.dataSource.client.isAuthenticated && responder == weakSelf.tableView) {
			NSString *eventString = [[event charactersIgnoringModifiers] lowercaseString];
			unichar eventChar = [eventString characterAtIndex:0];
			
			if ((eventChar == NSCarriageReturnCharacter || eventChar == NSNewlineCharacter) && !weakSelf.dataSource.isRunningRequest) {
				// return/enter
				[weakSelf startRenameForSelectedRow:nil];
				*shouldBlock = YES;
			} else if ([eventString hasPrefix:@"o"] || [eventString hasPrefix:@"b"]) {
				// o, or b
				[weakSelf openFileInBrowser:nil];
				*shouldBlock = YES;
			} else if ([eventString hasPrefix:@"c"]) {
				// c
				[weakSelf copyFileLinkToClipboard:nil];
				*shouldBlock = YES;
			} else if ((eventChar == NSBackspaceCharacter || eventChar == NSDeleteCharacter) && (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask)) {
				// command-delete
				[weakSelf deleteFile:nil];
				*shouldBlock = YES;
			} else if ([eventString hasPrefix:@"f"] && (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask)) {
				// command-f
				[weakSelf toggleFilterUI:nil];
				*shouldBlock = YES;
			} else if ([eventString hasPrefix:@"v"] && (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask)) {
				// command-v
                NSString *stringFromPasteboard = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
                if (stringFromPasteboard) {
                    [self uploadTextToFile:stringFromPasteboard];
                    *shouldBlock = YES;
                    [[NSPasteboard generalPasteboard] clearContents];
                }
			} else if ([eventString hasPrefix:@" "] || ([eventString hasPrefix:@"y"] && (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask))) {
                // space, command-y
                [self toggleQuickLook];
            }
		} else if (event.type == NSLeftMouseDown && [weakSelf.tabView.selectedTabViewItem.identifier isEqualToString:@"content"]) {
			if (NSPointInRect([event locationInWindow], weakSelf.storageTextField.frame)) {
                [ORBStorageInfo toggleStorageFormat];
				[weakSelf refreshStorageSpaceLabel];
			}
		}
	};
	
	self.searchContainerView.usesLightGradient = YES;
	self.searchContainerView.drawsRoundedCorners = NO;
	self.searchContainerView.borderedEdge = CGRectMaxYEdge;
}


- (void)setDataSource:(ORBDataSource *)dataSource {
	if (self.dataSource != dataSource) {
		if (self.dataSource) {
			[self.dataSource removeObserver:self forKeyPath:@"isRunningRequest" context:nil];
		}
		
		_dataSource = dataSource;
		
		if (self.dataSource) {
			[self.dataSource addObserver:self forKeyPath:@"isRunningRequest" options:NSKeyValueObservingOptionNew context:nil];
		}
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"isRunningRequest"]) {
		self.isLoading = self.dataSource.isRunningRequest;
	}
}


- (IBAction)logIn:(id)sender {
	[self.dataSource authenticateWithUsername:self.usernameTextField.stringValue password:self.passwordTextField.stringValue success:^{
		self.usernameTextField.stringValue = @"";
		self.passwordTextField.stringValue = @"";
		[self showFilesTabAndRefresh];
	} failure:^(NSError *error) {
        NSLog(@"could not authenticate, error: %@", error);
        [[ORBAppDelegate sharedAppDelegate] showAlertWithMessage:@"Authentication Error" informativeText:error.localizedDescription];
    }];
}



- (void)refreshFiles {
	if (self.dataSource.canRefreshFiles && self.tableView.editedRow == -1) {
		[self.dataSource fetchFilesWithSuccess:^{
			[self.tableView reloadData];
		}];
	}
}


- (void)refreshStorageSpace {
    [self.dataSource fetchStorageFreeSpaceForStorageInfo:self.storageInfo completion:^{
		[self refreshStorageSpaceLabel];
    }];
}


- (void)refreshStorageSpaceLabel {
	self.freeSpaceString = [self.storageInfo storageSpaceString];
}


- (IBAction)toggleFilterUI:(id)sender {
	if (self.isAnimating) return;
	
	NSView *superview = self.tableScrollView.superview;
	
	NSRect endSearchFrame = NSMakeRect(0.0, superview.frame.size.height - self.searchContainerView.frame.size.height, self.searchContainerView.frame.size.width, self.searchContainerView.frame.size.height);
	NSRect beginSearchFrame = endSearchFrame;
	beginSearchFrame.origin.y += self.searchContainerView.frame.size.height;
	
	NSRect tableScrollViewFrame = self.tableScrollView.frame;
	
	if (!self.isShowingFilterUI) {
		self.isShowingFilterUI = YES;
		self.isAnimating = YES;
		
		self.searchContainerView.frame = beginSearchFrame;
		[superview addSubview:self.searchContainerView];
		[self.panel makeFirstResponder:self.searchField];
		
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		[[NSAnimationContext currentContext] setDuration:0.1];
		[[NSAnimationContext currentContext] setCompletionHandler:^{
			self.isAnimating = NO;
		}];
		
		tableScrollViewFrame.size.height -= self.searchContainerView.frame.size.height;
		[[self.tableScrollView animator] setFrame:tableScrollViewFrame];
		[[self.searchContainerView animator] setFrame:endSearchFrame];
		
		[NSAnimationContext endGrouping];
	} else {
		[self.dataSource stopFiltering];
		[self.tableView reloadData];
		self.isAnimating = YES;
		
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		[[NSAnimationContext currentContext] setDuration:0.1];
		[[NSAnimationContext currentContext] setCompletionHandler:^{
			self.searchField.stringValue = @"";
			[self.panel makeFirstResponder:self.tableView];
			[self.searchContainerView removeFromSuperview];
			self.isShowingFilterUI = NO;
			self.isAnimating = NO;
		}];
		
		tableScrollViewFrame.size.height += self.searchContainerView.frame.size.height;
		[[self.searchContainerView animator] setFrame:beginSearchFrame];
		[[self.tableScrollView animator] setFrame:tableScrollViewFrame];
		
		[NSAnimationContext endGrouping];
	}
}


- (IBAction)filter:(id)sender {
	if (self.searchField.stringValue.length > 0) {
		[self.dataSource filterForSearchQuery:self.searchField.stringValue];
		[self.tableView reloadData];
	} else {
		[self.dataSource stopFiltering];
		[self.tableView reloadData];
	}
}


- (void)clipViewBoundsDidChange:(NSNotification *)notification {
	NSView *clipView = [notification object];
	CGFloat scrollOffset = clipView.bounds.origin.y;
	NSInteger firstRow = [self.tableView rowAtPoint:CGPointMake(0.0, scrollOffset)];
	NSInteger lastRow = firstRow + kORBFileRowsVisibleAtOnce;
	
	if (lastRow + 1 == [self.dataSource numberOfFiles] &&
        !self.dataSource.isRunningRequest &&
        self.dataSource.canRefreshFiles &&
        self.dataSource.moreFilesAvailable &&
        !self.dataSource.isFiltering) {
        
		[self.dataSource fetchNextFilesBatchWithSuccess:^{
			[self.tableView reloadData];
			[self.tableScrollView flashScrollers];
		}];
	}
}


- (void)possiblyDropPages {
	NSView *clipView = [self.tableView superview];
	CGFloat scrollOffset = clipView.bounds.origin.y;
	NSInteger firstRow = [self.tableView rowAtPoint:CGPointMake(0.0, scrollOffset)];
	NSInteger lastRow = firstRow + kORBFileRowsVisibleAtOnce;
	NSUInteger page = lastRow / kORBFilePageBatchSize;
	
	if (page < self.dataSource.extraPagesLoaded) {
		[self.dataSource dropPagesAfterPage:page];
		[self.tableView reloadData];
	}
}


#pragma mark - Showing and Hiding

- (void)windowWillClose:(NSNotification *)notification {
    [self performClose];
}


- (void)windowDidResignKey:(NSNotification *)notification {
    if ([[self window] isVisible]) {
        [self performClose];
    }
}


- (void)windowDidResize:(NSNotification *)notification {
    NSRect statusRect = [[ORBAppDelegate sharedAppDelegate].statusItemView rect];
    NSRect panelRect = [[self window] frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
}


- (void)popoverWillShow {
	if (self.dataSource.client.isAuthenticated) {
		[self autoFetchFiles];
	}
}


- (void)popoverWillHide {
    self.isVisible = NO;
	[self possiblyDropPages];
}


- (void)cancelOperation:(id)sender {
	self.isShowingFilterUI ? [self toggleFilterUI:nil] : [self performClose];
}


- (void)performOpen {
	if (self.isAnimating) return;
	[self popoverWillShow];
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusItemViewRect = [[ORBAppDelegate sharedAppDelegate].statusItemView rect];
    
    NSRect panelRect = [panel frame];
    panelRect.origin.x = floor(NSMidX(statusItemViewRect) - NSWidth(panelRect) / 2.0);
    panelRect.origin.y = NSMaxY(statusItemViewRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - kArrowHeight))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - kArrowHeight);
    
    [NSApp activateIgnoringOtherApps:YES];
	
	self.isAnimating = YES;
    
    [panel setAlphaValue:0];
    [panel makeKeyAndOrderFront:nil];
	[panel setFrame:statusItemViewRect display:YES];
    [panel setFrame:NSOffsetRect(panelRect, 0.0, kORBPopoverAnimationPositionOffset) display:YES];
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	[[NSAnimationContext currentContext] setDuration:kORBPopoverOpenDuration];
	[[NSAnimationContext currentContext] setCompletionHandler:^{
		self.isAnimating = NO;
	}];
	
    [[panel animator] setAlphaValue:1];
	[[panel animator] setFrame:panelRect display:YES];
	
	[NSAnimationContext endGrouping];
    
    self.isVisible = YES;
}


- (void)performClose {
	if (self.isAnimating) return;
    [self popoverWillHide];
	
	self.isAnimating = YES;
    
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	[[NSAnimationContext currentContext] setDuration:kORBPopoverCloseDuration];
	[[NSAnimationContext currentContext] setCompletionHandler:^{
		[self.window orderOut:nil];
		self.isAnimating = NO;
	}];
	
    [[[self window] animator] setAlphaValue:0];
	[[[self window] animator] setFrame:NSOffsetRect([[self window] frame], 0.0, -kORBPopoverAnimationPositionOffset) display:YES];
	
	[NSAnimationContext endGrouping];
	
	[self.delegate panelControllerPanelDidResignActive:self];
}


- (void)autoFetchFiles {
    if (self.isAllowedToFetchFiles && self.uploadingFilesCount == 0) {
        [self refreshFiles];
        
        self.isAllowedToFetchFiles = NO;
        
        double delayInSeconds = 5.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
            self.isAllowedToFetchFiles = YES;
        });
    }
	
	if (self.isAllowedToFetchStorageSpace && self.uploadingFilesCount == 0) {
		[self refreshStorageSpace];
		self.isAllowedToFetchStorageSpace = NO;
		
		double delayInSeconds = 60.0;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
			self.isAllowedToFetchStorageSpace = YES;
		});
	}
}


- (void)uploadTextToFile:(NSString *)text {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss a"];
    NSString *dateString = [dateFormat stringFromDate:[NSDate date]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    NSString *tmpPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Orbit File %@.txt", dateString]];
    
    NSError *error;
    [text writeToFile:tmpPath
           atomically:NO
             encoding:NSUTF8StringEncoding
                error:&error];
    
    if (error) {
        NSLog(@"Error creating file: %@", [error localizedDescription]);
    } else {
        NSURL *URL = [NSURL fileURLWithPath:tmpPath];
        [self uploadFilesAtURLs:@[URL] withPostflight:ORBPostflightOperationDelete];
    }
}


- (void)uploadFilesAtURLs:(NSArray *)fileURLs {
	[self uploadFilesAtURLs:fileURLs withPostflight:ORBPostflightOperationNone];
}


- (void)uploadFilesAtURLs:(NSArray *)fileURLs withPostflight:(ORBPostflightOperation)postflightOperation {
	if (!self.dataSource.client.isAuthenticated) {
		return;
	}
	
	BOOL isPublic = [ORBPreferences preferences].newFilesArePublicPref;
	self.uploadingFilesCount = fileURLs.count;
	
	for (NSURL *fileURL in fileURLs) {
		[self.delegate panelController:self willBeginUploadForFileAtURL:fileURL];
		
		ORBFileWrapper *fileToUpload = [self.dataSource insertWrapperForCreatingFileFromURL:fileURL isPublic:isPublic];
		[self.tableView reloadData];
		
		[self.dataSource createServerFileFromWrapper:fileToUpload progress:^(CGFloat iProgress) {
			fileToUpload.progress = iProgress;
			[self refreshSizeColumnForFile:fileToUpload];
		} completion:^(ORBFileWrapper *uploadedFile, NSError *error) {
			@synchronized (self) {
				self.uploadingFilesCount--;
			}
			
			if (uploadedFile) {
				[self.delegate panelController:self didFinishUploadForFile:uploadedFile ofFileURLs:fileURLs];
				[self.tableView reloadData];
				
				if (!error) {
					if (postflightOperation == ORBPostflightOperationDelete) {
						NSError *error = nil;
						if (!([[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error])) {
							NSLog(@"%@", error);
						}
					} else if (postflightOperation == ORBPostflightOperationMoveToTrash) {
						[[NSWorkspace sharedWorkspace] recycleURLs:fileURLs completionHandler:^(NSDictionary *newURLs, NSError *recycleError) {
							if (recycleError) {
								NSLog(@"%@", recycleError);
							}
						}];
					}
				}
				
				@synchronized (self) {
					// if we are done uploading stuff, refresh the storage space
					if (self.uploadingFilesCount == 0) {
						[self refreshStorageSpace];
					}
				}
			} else {
				if (fileToUpload.isUploading) {
					NSString *uploadErrorString = error ? [error localizedDescription] : @"Unknown Error";
					[[ORBAppDelegate sharedAppDelegate] showAlertWithMessage:@"Error uploading file" informativeText:uploadErrorString];
				}
				
				[self.dataSource removeFileWrapper:fileToUpload];
				[self.tableView reloadData];
			}
		}];
	}
}


#pragma mark Tabs

- (void)showLoginTab {
	self.shouldHideGearButton = NO;
    [self.tabView selectTabViewItemWithIdentifier:@"login"];
	[self.usernameTextField becomeFirstResponder];
	[self.tableView reloadData];
	self.freeSpaceString = @"";
}


- (void)showFilesTab {
	BOOL hasShownHelp = [[NSUserDefaults standardUserDefaults] boolForKey:kORBHasShownHelpKey]; // if the key isn't there, this will return nil, which will be cast as NO
	
	if (!hasShownHelp) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kORBHasShownHelpKey];
		[self showFirstRunHelpTab];
	} else {
		self.shouldHideGearButton = NO;
		[self.tabView selectTabViewItemWithIdentifier:@"content"];
	}
}


- (void)showFilesTabAndRefresh {
	[self showFilesTab];
	[self refreshFiles];
	[self refreshStorageSpace];
}


- (IBAction)showFilesTabAction:(id)sender {
	[self showFilesTab];
	if ([self.delegate respondsToSelector:@selector(panelController:shouldLaunchAtLoginChanged:)]) {
		[self.delegate panelController:self shouldLaunchAtLoginChanged:(self.firstRunLaunchAtLoginCheckbox.state == NSOnState)];
	}
}


- (IBAction)startRenameForSelectedRow:(id)sender {
	if (self.tableView.selectedRow > -1) {
		[self.tableView editColumn:1 row:self.tableView.selectedRow withEvent:nil select:YES];
	}
}


- (void)showFirstRunHelpTab {
	self.shouldHideGearButton = YES;
	[self.tabView selectTabViewItemWithIdentifier:@"firstRun"];
}


- (void)showNoNetworkTab {
	[self.tabView selectTabViewItemWithIdentifier:@"noNetwork"];
}


#pragma mark Menu Items

- (IBAction)openFileInBrowser:(id)sender {
    ORBFileWrapper *selectedFile = [self selectedFile];
    if (selectedFile) {
        [[NSWorkspace sharedWorkspace] openURL:[selectedFile URL]];
    }
}


- (IBAction)deleteFile:(id)sender {
    [self.dataSource deleteServerFile:[self selectedFile] success:^{
        NSInteger rowToRestoreSelectionTo = self.tableView.selectedRow;
		[self.tableView reloadData];
		[self refreshStorageSpace];
        
        if (rowToRestoreSelectionTo > -1 && [self.tableView numberOfRows] > rowToRestoreSelectionTo) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:rowToRestoreSelectionTo];
            [self.tableView selectRowIndexes:indexSet byExtendingSelection:NO];
        }
	} failure:^(NSError *error) {
        NSLog(@"error deleting file: %@", error);
        [[ORBAppDelegate sharedAppDelegate] showAlertWithMessage:@"Error deleting file" informativeText:error.localizedDescription];
    }];
}


- (IBAction)copyFileLinkToClipboard:(id)sender {
    ORBFileWrapper *selectedFile = [self selectedFile];
    if (selectedFile) {
        [[ORBAppDelegate sharedAppDelegate] copyURLToClipboardAndNotifyForFile:selectedFile];
    }
}


- (IBAction)downloadFile:(id)sender {
	ORBFileWrapper *selectedFile = [self selectedFile];
	if (selectedFile) {
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		savePanel.canCreateDirectories = YES;
		savePanel.nameFieldStringValue = selectedFile.name;
		NSInteger savePanelReturn = [savePanel runModal];
		
		if (savePanelReturn == NSAlertDefaultReturn) {
			[self downloadFile:selectedFile toDirectory:[[savePanel.URL URLByDeletingLastPathComponent] path] completion:^(NSError *error) {
				if (![selectedFile.name isEqualToString:[savePanel.URL lastPathComponent]]) {
					[[NSFileManager defaultManager] moveItemAtPath:[[[savePanel.URL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:selectedFile.name] toPath:[savePanel.URL path] error:nil];
				}
			}];
		}
	}
}


- (void)makeFilePublic {
    [self makeFilePublic:YES];
}


- (void)makeFilePrivate {
    [self makeFilePublic:NO];
}


- (void)makeFilePublic:(BOOL)isPublic {
    [self.dataSource updateServerFile:[self selectedFile] asPublic:isPublic success:^{
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        NSLog(@"error updating file: %@", error);
        [[ORBAppDelegate sharedAppDelegate] showAlertWithMessage:@"Error updating file" informativeText:[error localizedDescription]];
    }];
}


- (void)menuWillOpen:(NSMenu *)menu {
    ORBFileWrapper *file = [self selectedFile];
    [menu removeItemAtIndex:menu.itemArray.count - 1];
	
	NSString *itemTitle = file.isPublic ? @"Make File Private" : @"Make File Public";
	SEL itemAction = file.isPublic ? @selector(makeFilePrivate) : @selector(makeFilePublic);
    NSMenuItem *menuItem = [menu addItemWithTitle:itemTitle action:itemAction keyEquivalent:@""];
	
	menuItem.enabled = [menu itemAtIndex:0].isEnabled;
	
	if (file.isUploading || file.isDownloading) {
		for (NSMenuItem *item in menu.itemArray) {
			item.enabled = NO;
		}
		NSString *title = [NSString stringWithFormat:@"Cancel %@", file.isUploading ? @"Upload" : @"Download"];
		NSMenuItem *cancelMenuItem = [menu insertItemWithTitle:title action:@selector(cancelSelectedUploadOrDownload) keyEquivalent:@"" atIndex:0];
		cancelMenuItem.enabled = YES;
		[menu insertItem:[NSMenuItem separatorItem] atIndex:1];
	}
}


- (void)cancelSelectedUploadOrDownload {
	ORBFileWrapper *file = [self selectedFile];
	[self.dataSource cancelRequestForFile:file];
	[self refreshSizeColumnForFile:file];
}


- (void)refreshSizeColumnForFile:(ORBFileWrapper *)fileWrapper {
	NSUInteger fileIndex = [self.dataSource indexOfFile:fileWrapper];
	if (fileIndex != NSNotFound) {
		[self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:fileIndex] columnIndexes:[NSIndexSet indexSetWithIndex:self.tableView.numberOfColumns - 2]];
	}
}


- (ORBFileWrapper *)selectedFile {
    return self.tableView.selectedRow > -1 ? [self.dataSource fileAtIndex:self.tableView.selectedRow] : nil;
}


- (void)downloadFile:(ORBFileWrapper *)file toDirectory:(NSString *)directory completion:(void (^)(NSError *error))completion {
	file.isDownloading = YES;
	[self.dataSource downloadFile:file toDirectory:directory progress:^(CGFloat iProgress) {
		file.progress = iProgress;
		[self refreshSizeColumnForFile:file];
	} completion:^(NSError *error) {
		BOOL wasCancelled = file.isDownloading == NO;
		file.isDownloading = NO;
		[self refreshSizeColumnForFile:file];
		
		if (error && !wasCancelled) {
			[[ORBAppDelegate sharedAppDelegate] showAlertWithMessage:@"Error downloading file" informativeText:[error localizedDescription]];
		}
		
		if (completion) {
			completion(error);
		}
	}];
}


#pragma mark -
#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.dataSource numberOfFiles];
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	ORBFileWrapper *file = [self.dataSource fileAtIndex:row];
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	cellView.objectValue = file;
	
	if ([tableColumn.identifier hasSuffix:@"Icon"]) {
		if ([tableColumn.identifier isEqualToString:@"fileIcon"]) {
			cellView.imageView.image = file.iconImage;
		} else if ([tableColumn.identifier isEqualToString:@"filePrivateIcon"]) {
			ORBImageCellView *imageCellView = (ORBImageCellView *)cellView;
			imageCellView.imageName = file.privateImageName;
			imageCellView.highlightedImageName = file.privateImageHighlightedName;
		}
	} else {
		if ([tableColumn.identifier isEqualToString:@"fileName"]) {
			ORBTextCellView *textCellView = (ORBTextCellView *)cellView;
			cellView.textField.stringValue = file.name;
			textCellView.target = self;
			textCellView.action = @selector(textCell:didChangeTextValueToString:);
			textCellView.customTextColor = file.isUploading ? [NSColor colorWithCalibratedWhite:0.6 alpha:1.0] : nil;
		} else if ([tableColumn.identifier isEqualToString:@"fileSize"]) {
			ORBTextCellView *textCellView = (ORBTextCellView *)cellView;
			if (file.isUploading || file.isDownloading) {
				[textCellView showProgressForFile:file];
			} else {
				[textCellView hideProgress];
				textCellView.textField.stringValue = file.formattedSize;
				textCellView.customTextColor = [NSColor colorWithCalibratedWhite:0.45 alpha:1.0];
			}
		}
	}
	
	return cellView;
}


- (void)textCell:(ORBTextCellView *)textCell didChangeTextValueToString:(NSString *)string {
	ORBFileWrapper *file = textCell.objectValue;
	NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (![file.name isEqualToString:string] && trimmedString.length > 0) {
		if ([string pathExtension].length == 0) {
			string = [string stringByAppendingPathExtension:[file.name pathExtension]];
			textCell.textField.stringValue = string;
		}
		[self.dataSource renameFile:file toName:string success:nil failure:nil];
	} else {
		textCell.textField.stringValue = file.name;
	}
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	// this is implemented so that ORBTableView can figure out the represented object
	return [self.dataSource fileAtIndex:row];
}


- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pasteboard {
    NSArray *draggedFiles = [self.dataSource draggableFilesAtIndeces:rowIndexes];
	
	BOOL didWriteRows = NO;
	
	if (draggedFiles.count > 0) {
		NSArray *filenameExtensions = [draggedFiles ank_map:^id(ORBFileWrapper *file) {
			NSString *filenameExtension = [file.name pathExtension];
			return [filenameExtension isEqualToString:@""] ? nil : filenameExtension;
		}];
		
		[pasteboard declareTypes:@[NSFilesPromisePboardType] owner:self];
		[pasteboard setPropertyList:filenameExtensions forType:NSFilesPromisePboardType];
		didWriteRows = YES;
	}
    
    return didWriteRows;
}


- (NSArray *)tableView:(NSTableView *)tableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet {
    // iterate the selected files
    NSArray *selectedObjects = [self.dataSource draggableFilesAtIndeces:indexSet];
    
	NSArray *draggedFileNames = [selectedObjects ank_map:^id(ORBFileWrapper *file) {
		[self downloadFile:file toDirectory:[dropDestination path] completion:nil];
        return file.name;
    }];
    
    return draggedFileNames;
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	self.tableView.currentSelectionValue = [self selectedFile].file.fileID;
    
    if ([QLPreviewPanel sharedPreviewPanel].isVisible) {
        [[QLPreviewPanel sharedPreviewPanel] reloadData];
    }
}


#pragma mark - QuickLook

- (void)toggleQuickLook {
    if ([[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [self hideQuickLook];
    } else {
        [self showQuickLook];
    }
}


- (void)showQuickLook {
    QLPreviewPanel *qlPanel = [QLPreviewPanel sharedPreviewPanel];
    [qlPanel center];
    [qlPanel orderFront:self];
}


- (void)hideQuickLook {
    [[QLPreviewPanel sharedPreviewPanel] orderOut:self];
}


#pragma mark - QLPreviewPanelController

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}


- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    panel.dataSource = self;
	panel.delegate = self;
}


- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    panel.dataSource = nil;
	panel.delegate = nil;
}


#pragma mark - QLPreviewPanelDataSource

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return 1;
}


- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    return [self selectedFile];
}


- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
    return YES;
}


#pragma mark - QLPreviewPanelDelegate

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item {
	NSRect cellFrame = [self.tableView rectOfRow:self.tableView.selectedRow];
	
	cellFrame = [self.tableView convertRectToBase:cellFrame];
	cellFrame.origin.x = 9.0;
	cellFrame.origin.y += 4.0;
    
    cellFrame.origin.y = floor(cellFrame.origin.y / [NSScreen mainScreen].backingScaleFactor);
	
	cellFrame = [self.window convertRectToScreen:cellFrame];
	cellFrame.size = [ORBFileWrapper iconSize];
	
	return cellFrame;
}


@end
