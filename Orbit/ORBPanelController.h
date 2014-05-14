//
//  PanelController.h
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBPanelBackgroundView.h"
#import "ORBStatusItemIconView.h"
#import "ORBPanel.h"
#import "ORBFileWrapper.h"
#import <Quartz/Quartz.h>


typedef NS_ENUM(NSUInteger, ORBPostflightOperation) {
	ORBPostflightOperationNone = 0,
	ORBPostflightOperationDelete,
	ORBPostflightOperationMoveToTrash
};


@class ORBPanelController;
@protocol ORBPanelControllerDelegate <NSObject>

- (void)panelController:(ORBPanelController *)panelController willBeginUploadForFileAtURL:(NSURL *)fileURL;
- (void)panelController:(ORBPanelController *)panelController didFinishUploadForFile:(ORBFileWrapper *)file ofFileURLs:(NSArray *)fileURLs;
- (void)panelController:(ORBPanelController *)panelController shouldLaunchAtLoginChanged:(BOOL)value;
- (void)panelControllerPanelDidResignActive:(ORBPanelController *)panelController;

@end


@class ORBPopUpButton, ORBTableView, ORBDataSource, ORBPanelFooterView;

@interface ORBPanelController : NSWindowController <NSWindowDelegate, NSMenuDelegate, NSTableViewDataSource, NSTableViewDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate>

@property (nonatomic, weak) id <ORBPanelControllerDelegate> delegate;
@property (nonatomic, weak) ORBDataSource *dataSource;
@property (nonatomic, weak) IBOutlet ORBPanel *panel;
@property (nonatomic, weak) IBOutlet ORBPanelBackgroundView *backgroundView;
@property (nonatomic, weak) IBOutlet NSScrollView *tableScrollView;
@property (nonatomic, strong) IBOutlet ORBTableView *tableView;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;
@property (nonatomic, weak) IBOutlet NSTextField *usernameTextField;
@property (nonatomic, weak) IBOutlet NSSecureTextField *passwordTextField;
@property (nonatomic, weak) IBOutlet ORBPopUpButton *actionButton;
@property (nonatomic, weak) IBOutlet NSTextFieldCell *versionTextFieldCell;
@property (nonatomic, weak) IBOutlet ORBPanelFooterView *searchContainerView;
@property (nonatomic, weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, weak) IBOutlet NSTextField *storageTextField;
@property (nonatomic, weak) IBOutlet NSButton *firstRunLaunchAtLoginCheckbox;

@property (nonatomic, copy) NSString *freeSpaceString;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL shouldHideGearButton;

- (id)initWithDataSource:(ORBDataSource *)dataSource;

- (void)uploadFilesAtURLs:(NSArray *)fileURLs;
- (void)uploadFilesAtURLs:(NSArray *)fileURLs withPostflight:(ORBPostflightOperation)postflightOperation;

- (void)popoverWillShow;
- (void)popoverWillHide;

- (void)performOpen;
- (void)performClose;

- (void)showLoginTab;
- (void)showFilesTab;
- (void)showFilesTabAndRefresh;
- (void)showFirstRunHelpTab;
- (void)showNoNetworkTab;

- (void)hideQuickLook;

@end
