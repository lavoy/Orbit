//
//  NBAppDelegate.m
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBAppDelegate.h"
#import "ORBMenuController.h"
#import "LaunchAtLoginController.h"
#import "MASShortcut+UserDefaults.h"
#import "MASPreferencesWindowController.h"
#import "Finder.h"
#import <Sparkle/Sparkle.h>
#import <ADNKit/NSArray+ANKAdditions.h>
#import "ORBGeneralPrefsViewController.h"
#import "ORBShortcutPrefsViewController.h"
#import "ORBAdvancedPrefsViewController.h"
#import "ORBExclusionPrefsViewController.h"
#import <CoreServices/CoreServices.h>


@interface ORBAppDelegate ()

@property (nonatomic, strong) ORBDataSource *dataSource; // TODO: store one per-user instead of just one total
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong) NSDate *latestScreenshotDate;
@property (nonatomic, strong) MASPreferencesWindowController *prefsWindow;
@property (nonatomic, strong) NSArray *postLoginUploadQueue;
@property (assign) NSUInteger currentUploadsCounter;

@end


static ORBAppDelegate *sharedAppDelegate = nil;

@implementation ORBAppDelegate

+ (ORBAppDelegate *)sharedAppDelegate {
    return sharedAppDelegate;
}


- (id)init {
	if ((self = [super init])) {
		sharedAppDelegate = self;
		self.dataSource = [[ORBDataSource alloc] init];
		[self.dataSource addObserver:self forKeyPath:@"isRunningRequest" options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
	[ORBPreferences preferences];
    [self setUpStatusItem];
    [self setUpScreenshotNotifications];
    [self setUpKeyboardShortcuts];
    
	self.panelController = [[ORBPanelController alloc] initWithDataSource:self.dataSource];
	self.panelController.delegate = self;
	
	__weak ORBAppDelegate *weakSelf = self;
	
	[self.dataSource.client setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
		if (status == AFNetworkReachabilityStatusNotReachable) {
			[weakSelf.panelController showNoNetworkTab];
			weakSelf.statusItemView.imageOpacity = 0.5;
			[weakSelf.statusItemView setNeedsDisplay:YES];
		} else {
			weakSelf.statusItemView.imageOpacity = 1.0;
			[weakSelf.statusItemView setNeedsDisplay:YES];
			if (!weakSelf.isLoggedIn) {
				[weakSelf.dataSource logInWithCompletion:^(BOOL isLoggedIn, NSError *error) {
					if (!isLoggedIn) {
						[weakSelf.panelController showLoginTab];
						[weakSelf bringAppToFront];
						weakSelf.statusItemView.isHighlighted = YES;
						[weakSelf.panelController performOpen];
					} else {
						[weakSelf.panelController showFilesTabAndRefresh];
						if (weakSelf.postLoginUploadQueue) {
							[weakSelf.panelController uploadFilesAtURLs:[weakSelf.postLoginUploadQueue copy]];
							weakSelf.postLoginUploadQueue = nil;
						}
					}
				}];
			} else {
				[weakSelf.panelController showFilesTabAndRefresh];
			}
			
			[SUUpdater sharedUpdater];
		}
	}];
	
	[[NSApplication sharedApplication] setServicesProvider:self];
}


- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.metadataQuery stopQuery];
    [self.metadataQuery setDelegate:nil];
}


- (void)applicationDidResignActive:(NSNotification *)notification {
	[self.panelController close];
}


- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	NSArray *fileURLs = [filenames ank_map:^id(NSString *path) {
		return [NSURL fileURLWithPath:path];
	}];
	
	if ([self shouldAllowPathsToUpload:fileURLs]) {
		if (self.isLoggedIn) {
			[self.panelController uploadFilesAtURLs:fileURLs];
		} else {
			self.postLoginUploadQueue = fileURLs;
		}
	}
}


- (void)setUpStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:kORBStatusItemWidth];
    [self.statusItem setHighlightMode:YES];
    
    self.statusItemView = [[ORBStatusItemIconView alloc] initWithStatusItem:self.statusItem delegate:self];
    self.statusItemView.image = [NSImage imageNamed:@"orbit"];
    self.statusItemView.highlightedImage = [NSImage imageNamed:@"orbit-down"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"isRunningRequest"]) {
		if (self.dataSource.isRunningRequest && !self.statusItemView.isSpinning) {
			[self.statusItemView startSpinning];
		} else if (!self.dataSource.isRunningRequest && self.statusItemView.isSpinning) {
			[self.statusItemView stopSpinning];
		}
	}
}


#pragma mark -
#pragma mark ORBStatusItemIconViewDelegate

- (void)statusItemViewActivatedPrimary:(ORBStatusItemIconView *)statusItemView {
    if (self.panelController.isVisible) {
		self.statusItemView.isHighlighted = NO;
        [self.panelController performClose];
    } else {
		self.statusItemView.isHighlighted = YES;
        [self.panelController performOpen];
    }
}


- (void)statusItemViewActivatedSecondary:(ORBStatusItemIconView *)statusItemView {
	if (!self.panelController.isVisible) {
		[statusItemView showMenu];
	}
}


- (void)statusItemView:(ORBStatusItemIconView *)statusItemView didReceiveDropForURLs:(NSArray *)URLs {
    [self.panelController uploadFilesAtURLs:URLs];
}


#pragma mark -
#pragma mark ORBPanelControllerDelegate

- (void)panelController:(ORBPanelController *)panelController willBeginUploadForFileAtURL:(NSURL *)fileURL {
	
}


- (void)panelController:(ORBPanelController *)panelController didFinishUploadForFile:(ORBFileWrapper *)file ofFileURLs:(NSArray *)fileURLs {
	if ([ORBPreferences preferences].autoCopyPublicUploadedURLPref && fileURLs.count == 1) {
        [self copyURLToClipboardAndNotifyForFile:file];
    }
}


- (void)panelControllerPanelDidResignActive:(ORBPanelController *)panelController {
	self.statusItemView.isHighlighted = NO;
    [self.panelController hideQuickLook];
}


- (void)panelController:(ORBPanelController *)panelController shouldLaunchAtLoginChanged:(BOOL)value {
	self.shouldLaunchAtLogin = value;
}


#pragma mark - NSPasteboard 

- (void)copyURLToClipboardAndNotifyForFile:(ORBFileWrapper *)file {
    NSPasteboard *appPasteboard = [NSPasteboard generalPasteboard];
    [appPasteboard clearContents];
    
    NSString *URLString = [[file sharableURL] absoluteString];
    NSString *informativeText = [file isPublic] ? URLString : file.name;
    [appPasteboard writeObjects:@[URLString]];
    
    [self presentNotificationForCopiedFile:file informativeText:informativeText];
}


#pragma mark - NSUserNotificationCenter

- (void)presentNotificationForCopiedFile:(ORBFileWrapper *)file informativeText:(NSString *)informativeText {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = [NSString stringWithFormat:@"%@ link copied to clipboard", file.isPublic ? @"Public" : @"Private"];
    notification.informativeText = informativeText;
	notification.soundName = NSUserNotificationDefaultSoundName;
	notification.userInfo = @{@"fileID": file.file.fileID};
	
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
	center.delegate = self;
    [center deliverNotification:notification];
}


- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
	NSString *fileID = notification.userInfo[@"fileID"];
	ORBFileWrapper *file = [self.dataSource fileWithID:fileID];
	[[NSWorkspace sharedWorkspace] openURL:[file URL]];
}


#pragma mark - Screenshots

- (void)setUpScreenshotNotifications {
    self.metadataQuery = [[NSMetadataQuery alloc] init];
    self.metadataQuery.notificationBatchingInterval = 0.1f;
	self.metadataQuery.searchScopes = @[NSMetadataQueryUserHomeScope];
	self.metadataQuery.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:(__bridge NSString *)kMDItemFSCreationDate ascending:YES]];
	self.metadataQuery.delegate = self;
	self.metadataQuery.predicate = [NSPredicate predicateWithFormat:@"kMDItemIsScreenCapture = 1"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryUpdated:) name:NSMetadataQueryDidUpdateNotification object:self.metadataQuery];
    [self storeLatestScreenshotDate];
	
    [self.metadataQuery startQuery];
}


- (void)queryUpdated:(NSNotification *)notification {
    if ([ORBPreferences preferences].autoUploadScreenshotsPref) {
        NSMetadataItem *latestScreenshot = [self latestScreenshot];
        NSDate *createdDate = [latestScreenshot valueForAttribute:NSMetadataItemFSCreationDateKey];
        
        if ([self.latestScreenshotDate laterDate:createdDate] != self.latestScreenshotDate) {
            NSString *path = [latestScreenshot valueForAttribute:NSMetadataItemPathKey];
			NSArray *files = @[[NSURL fileURLWithPath:path]];
			if ([self shouldAllowPathsToUpload:files]) {
				[self.panelController uploadFilesAtURLs:files withPostflight:([ORBPreferences preferences].deleteScreenshotsAfterUploadPref ? ORBPostflightOperationMoveToTrash : ORBPostflightOperationNone)];
			}
        }
    }
    
    [self storeLatestScreenshotDate];
}


- (void)storeLatestScreenshotDate {
    NSMetadataItem *latestScreenshot = [self latestScreenshot];
    if (latestScreenshot) {
        self.latestScreenshotDate = [latestScreenshot valueForAttribute:NSMetadataItemFSCreationDateKey];
    } else {
        self.latestScreenshotDate = [NSDate date];
    }
}


- (NSMetadataItem *)latestScreenshot {
    NSMetadataItem *metadataItem = nil;
    
    if ([[self.metadataQuery results] count] > 0) {
        metadataItem = [[self.metadataQuery results] lastObject];
    }
    
    return metadataItem;
}


#pragma mark - NSAlerts

- (void)showAlertWithMessage:(NSString *)message informativeText:(NSString *)informativeText {
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", informativeText];
    [self showAlertMovingAppToFront:alert];
}


- (void)showAlertMovingAppToFront:(NSAlert *)alert {
    [self bringAppToFront];
    
    double delayInSeconds = 0.1; // allows for existing stuff to not get stuck
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        [alert runModal];
    });
}


- (void)bringAppToFront {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

#pragma mark - Sparkle

- (void)checkForUpdates:(id)sender {
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
}


#pragma mark - Menu Items and Properties

- (IBAction)aboutMenuItemSelected:(id)sender {
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
    [self bringAppToFront];
}


- (IBAction)shouldLaunchAtLoginChanged:(id)sender {
	self.shouldLaunchAtLogin = !self.shouldLaunchAtLogin;
}


- (IBAction)showPreferencesWindow:(id)sender {
	if (!self.prefsWindow) {
		self.prefsWindow = [[MASPreferencesWindowController alloc] initWithViewControllers:@[[[ORBGeneralPrefsViewController alloc] init], [[ORBShortcutPrefsViewController alloc] init], [[ORBExclusionPrefsViewController alloc] init]] title:@"Orbit Preferences"];
		[self.prefsWindow.window center];
		self.prefsWindow.window.frameAutosaveName = @"PrefsWindow";
	}
	[self bringAppToFront];
	[self.prefsWindow showWindow:nil];
}


- (IBAction)logout:(id)sender {
    if ([self isLoggedIn]) {
        [self.dataSource logOut];
        [self.panelController showLoginTab];
    }
}


- (BOOL)isLoggedIn {
	return [self.dataSource.client isLoggedIn];
}


- (BOOL)canLogOut {
	return self.isLoggedIn && self.dataSource.client.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable;
}


- (BOOL)canCheckForUpdates {
	return self.dataSource.client.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable;
}


- (NSString *)currentLoggedInUsername {
	return self.dataSource.client.authenticatedUser.username;
}


- (void)toggleOrbit {
	if (self.panelController.isVisible) {
		[self.panelController performClose];
		self.statusItemView.isHighlighted = NO;
	} else {
		[self.panelController performOpen];
		self.statusItemView.isHighlighted = YES;
	}
}


#pragma mark - Keyboard Shortcut

- (void)setUpKeyboardShortcuts {
    // shortcut defaults are registered in ORBPreferences along with defaults for all other preferences
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kORBUploadFilesShortcutKey handler:^{
        [self uploadSelectedFilesInFinder];
    }];
	
	[MASShortcut registerGlobalShortcutWithUserDefaultsKey:kORBUploadClipboardShortcutKey handler:^{
		[self uploadClipboardContent];
	}];
	
	[MASShortcut registerGlobalShortcutWithUserDefaultsKey:kORBToggleOrbitWindowShortcutKey handler:^{
		[self toggleOrbit];
	}];
}


#pragma mark - File Upload Common Methods

- (BOOL)shouldAllowPathsToUpload:(NSArray *)paths {
    BOOL shouldAllow = NO;
    
	if ([paths count] > 0) {
		NSArray *directoryPaths = [paths ank_filter:^BOOL(NSURL *fileURL) {
			BOOL isDirectory = NO;
			[[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
			return isDirectory;
		}];
        
		shouldAllow = directoryPaths.count == 0;
	}
    
    return shouldAllow && self.isLoggedIn && self.dataSource.client.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable;
}


- (void)uploadSelectedFilesInFinder {
	FinderApplication *finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.finder"];
	SBElementArray *selection = [[finder selection] get];
	
	NSArray *selectedPaths = [selection ank_map:^id(FinderApplicationFile *file) {
		return [NSURL URLWithString:file.URL];
	}];
	
	if (selectedPaths.count > 0) {
		if ([self shouldAllowPathsToUpload:selectedPaths]) {
			[self.panelController uploadFilesAtURLs:selectedPaths];
		}
	} else if (selectedPaths.count == 0 && [ORBPreferences preferences].uploadClipboardContentPref) {
		[self uploadClipboardContent];
	}
}


- (void)uploadClipboardContent {
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSArray *pasteboardItems = [pasteboard pasteboardItems];
	if (pasteboardItems.count > 0) {
		NSPasteboardItem *copiedItem = pasteboardItems[0];
		
		NSMutableArray *preferredTypes = [NSMutableArray array];
		[preferredTypes addObject:(__bridge NSString *)kUTTypeRTF];
		[preferredTypes addObject:(__bridge NSString *)kUTTypePlainText];
		[preferredTypes addObject:(__bridge NSString *)kUTTypeImage];
		[preferredTypes addObject:(__bridge NSString *)kUTTypeAudiovisualContent];
		[preferredTypes addObject:(__bridge NSString *)kUTTypeData];
		
		NSString *type = [copiedItem availableTypeFromArray:preferredTypes];
		if (type) {
			if (UTTypeConformsTo((__bridge CFStringRef)type, kUTTypeRTF) && [ORBPreferences preferences].uploadRichTextClipboardContentAsPlainPref) {
				type = (__bridge NSString *)kUTTypeUTF8PlainText;
			}
			
			NSString *extension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)type, kUTTagClassFilenameExtension);
			NSString *filename = @"Clipboard";
			
			if (UTTypeConformsTo((__bridge CFStringRef)type, kUTTypeText) && extension.length == 0) {
				extension = @"txt";
			}
			
			if (extension.length > 0) {
				filename = [filename stringByAppendingFormat:@".%@", extension];
			}
			
			NSData *fileData = [copiedItem dataForType:type];
			NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"OrbitClipboardUpload-%@", [[NSUUID UUID] UUIDString]]];
			[[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:nil];
			
			NSURL *fileURL = [NSURL fileURLWithPath:[tempDirectory stringByAppendingPathComponent:filename]];
			NSError *writeError = nil;
			if (![fileData writeToURL:fileURL options:NSDataWritingAtomic error:&writeError]) {
				NSLog(@"%@", writeError);
			} else {
				[self.panelController uploadFilesAtURLs:@[fileURL] withPostflight:ORBPostflightOperationDelete];
			}
		}
	}
}


#pragma mark - Defaults

- (void)setShouldLaunchAtLogin:(BOOL)shouldLaunchAtLogin {
	NSURL *appURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	[[LaunchAtLoginController sharedLoginController] setLaunchAtLogin:shouldLaunchAtLogin forURL:appURL];
}


- (BOOL)shouldLaunchAtLogin {
	return [[LaunchAtLoginController sharedLoginController] willLaunchAtLogin:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}


#pragma mark - Services

- (void)handleUploadFromService:(NSPasteboard *)pasteboard userData:(NSString *)userData error:(NSString **)error {
	NSArray *files = [pasteboard propertyListForType:NSFilenamesPboardType];
	if ([files count] > 0) {
		NSArray *fileURLs = [files ank_map:^id(NSString *path) {
			return [NSURL fileURLWithPath:path];
		}];
		
		if ([self shouldAllowPathsToUpload:fileURLs]) {
			[self.panelController uploadFilesAtURLs:fileURLs];
		}
	}
}


@end
