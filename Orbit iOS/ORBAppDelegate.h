//
//  ORBAppDelegate.h
//  Orbit iOS
//
//  Created by Andy LaVoy on 4/25/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBStorageInfo.h"
#import <UIKit/UIKit.h>

#define kORBBarTintColor    (SYSTEM_VERSION_AT_LEAST(@"7.0.3") ? [UIColor colorWithHue:211.0/360.0 saturation:1.0 brightness:0.5 alpha:1.0] : [UIColor colorWithHue:211.0/360.0 saturation:1.0 brightness:1.0 alpha:1.0])
#define kORBTintColor       (SYSTEM_VERSION_AT_LEAST(@"7.0.3") ? [UIColor colorWithR:27 G:82 B:141] : [UIColor colorWithR:65 G:112 B:163])

#define ORBIsPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define ORBIsPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#define ORBIsPortrait UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])
#define ORBIsLandscape UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])

static NSString * const kORBFontRegular     = @"AvenirNext-Regular";
static NSString * const kORBFontMedium      = @"AvenirNext-Medium";
static NSString * const kORBFontBold        = @"AvenirNext-Bold";
static NSString * const kORBFontDemiBold    = @"AvenirNext-DemiBold";
static NSString * const kORBShouldReloadFilesNotification = @"ShouldReloadFiles";

typedef void (^ORBVoidBlock)();

@interface ORBAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) ORBStorageInfo *storageInfo;

+ (ORBAppDelegate *)sharedAppDelegate;
- (void)refreshStorageSpace;
- (IBAction)logout:(id)sender;

@end