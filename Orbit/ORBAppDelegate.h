//
//  NBAppDelegate.h
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ORBPanelController.h"
#import "ORBStatusItemIconView.h"
#import "ORBFileWrapper.h"


static CGFloat const kORBStatusItemWidth = 27;
static NSString *const kORBUploadFilesShortcutKey = @"UploadFilesShortcutKey";
static NSString *const kORBUploadClipboardShortcutKey = @"UploadClipboardShortcutKey";
static NSString *const kORBToggleOrbitWindowShortcutKey = @"ToggleOrbitShortcutKey";


@interface ORBAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, NSUserNotificationCenterDelegate, NSMetadataQueryDelegate, ORBStatusItemIconViewDelegate, ORBPanelControllerDelegate>

@property (nonatomic, strong) ORBPanelController *panelController;
@property (nonatomic, strong) ORBStatusItemIconView *statusItemView;

@property (nonatomic, assign) BOOL shouldLaunchAtLogin;

+ (ORBAppDelegate *)sharedAppDelegate;

- (void)copyURLToClipboardAndNotifyForFile:(ORBFileWrapper *)file;
- (BOOL)shouldAllowPathsToUpload:(NSArray *)paths;
- (void)showAlertWithMessage:(NSString *)message informativeText:(NSString *)informativeText;
- (void)uploadSelectedFilesInFinder;
- (void)uploadClipboardContent;

- (IBAction)aboutMenuItemSelected:(id)sender;
- (IBAction)checkForUpdates:(id)sender;
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)logout:(id)sender;

- (void)toggleOrbit;
- (BOOL)isLoggedIn;
- (BOOL)canLogOut;
- (BOOL)canCheckForUpdates;
- (NSString *)currentLoggedInUsername;

@end
