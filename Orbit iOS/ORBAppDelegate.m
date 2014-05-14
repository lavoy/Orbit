//
//  ORBAppDelegate.m
//  Orbit iOS
//
//  Created by Andy LaVoy on 4/25/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBAppDelegate.h"
#import "ORBFilesViewController.h"
#import "ORBAuthViewController.h"
#import "ADNLogin.h"
#import "ORBNoSelectionViewController.h"
#import "ORBNavigationBar.h"
#import "ORBToolbar.h"

static NSString *const kIsRunningRequest = @"isRunningRequest";
static ORBAppDelegate *sharedAppDelegate = nil;

@interface ORBAppDelegate () <ADNLoginDelegate>

@property (nonatomic, strong) ORBDataSource *dataSource;
@property (nonatomic, strong) UISplitViewController *splitViewController;
@property (nonatomic, strong) ORBFilesViewController *filesController;
@property (nonatomic, strong) ORBAuthViewController *authController;

@end

@implementation ORBAppDelegate

+ (ORBAppDelegate *)sharedAppDelegate {
    return sharedAppDelegate;
}


- (id)init {
	if ((self = [super init])) {
		sharedAppDelegate = self;
		self.dataSource = [[ORBDataSource alloc] init];
        self.storageInfo = [[ORBStorageInfo alloc] init];
		
        [self setUpAppearance];
        
		[self.dataSource addObserver:self forKeyPath:kIsRunningRequest options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
    self.window.tintColor = [UIColor whiteColor];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    ADNLogin *adn = [ADNLogin sharedInstance];
    adn.delegate = self;
    adn.scopes = @[@"basic", @"files"];
	
    self.filesController = [[ORBFilesViewController alloc] initWithDataSource:self.dataSource];
    self.filesController.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.filesController.title image:[UIImage imageNamed:@"orbit"] tag:0];
    UIViewController *rootController = [[ORBNavigationController alloc] initWithRootViewController:self.filesController];
	
	if (ORBIsPad) {
		self.splitViewController = [[UISplitViewController alloc] init];
		self.splitViewController.viewControllers = @[self.filesController.navigationController, [[ORBNavigationController alloc] initWithRootViewController:[[ORBNoSelectionViewController alloc] init]]];
		self.splitViewController.delegate = self.filesController;
		rootController = self.splitViewController;
	}
    
    self.window.rootViewController = rootController;
    [self.window makeKeyAndVisible];
    
    [self handleLoginProcessWithCompletion:nil];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    if (url) {
        
        // handle url scheme separately in the future
        if (![[url absoluteString] hasPrefix:@"orbitappnet://"]) {
            
            // let ADNLogin try and open the url, if it doesn't want to, it may be a file we want to upload
            if (![[ADNLogin sharedInstance] openURL:url sourceApplication:sourceApplication annotation:annotation]) {
                ORBVoidBlock uploadBlock = ^() {
                    [self.filesController uploadFileFromURL:url completion:nil];
                };
                
                if (self.dataSource.client.authenticatedUser) {
                    uploadBlock();
                } else {
                    [self handleLoginProcessWithCompletion:uploadBlock];
                }
            }
        }
        
        return YES;
    } else {
        return NO;
    }
}

- (void)handleLoginProcessWithCompletion:(ORBVoidBlock)completion {
    ORBVoidBlock loginBlock = ^() {
        [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeClear];
        [self.dataSource logInWithCompletion:^(BOOL isLoggedIn, NSError *error) {
            if (!isLoggedIn) {
                [SVProgressHUD dismiss];
                [self authenticateAnimated:NO];
                NSLog(@"Auth error: %@", error);
            } else {
                [self.filesController fetchFilesWithCompletion:^{
                    [SVProgressHUD dismiss];
                    
                    [self showPadFilesListIfNecessary];
                    
                    if (completion) {
                        completion();
                    }
                }];
            }
        }];
    };
    
    __weak ORBAppDelegate *wSelf = self;
    switch (self.dataSource.client.networkReachabilityStatus)
    {
        case AFNetworkReachabilityStatusNotReachable:
        {
            [SVProgressHUD showWithStatus:@"Waiting for network..." maskType:SVProgressHUDMaskTypeBlack];
            [self.dataSource.client setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
                switch (status) {
                    case AFNetworkReachabilityStatusReachableViaWiFi:
                    case AFNetworkReachabilityStatusReachableViaWWAN:
                        [SVProgressHUD dismiss];
                        loginBlock();
                        [wSelf.dataSource.client setReachabilityStatusChangeBlock:nil];
                        break;
                        
                    default:
                        break;
                }
            }];
        }
            break;
            
        default:
            loginBlock();
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:kIsRunningRequest]) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = self.dataSource.isRunningRequest;
	}
}

- (void)refreshStorageSpace {
    [self.dataSource fetchStorageFreeSpaceForStorageInfo:self.storageInfo completion:nil];
}

- (void)showPadFilesListIfNecessary {
    if (ORBIsPad && ORBIsPortrait) {
        ORBNavigationController *navController = [self.splitViewController.viewControllers safeObjectAtIndex:1];
        ORBNoSelectionViewController *noSelectionController = [navController.viewControllers safeObjectAtIndex:0];
        
        if ([noSelectionController isKindOfClass:[noSelectionController class]]) {
            [noSelectionController sendLeftBarButtonActionToTarget];
        }
    }
}

- (void)authenticateAnimated:(BOOL)animated {
    __weak ORBAppDelegate *wAppDelegate = self;
    self.authController = [self.dataSource authControllerWithSuccess:^{
        [SVProgressHUD showWithStatus:@"Loading your files..."];
        [wAppDelegate.filesController fetchFilesWithCompletion:^{
            [SVProgressHUD dismiss];
        }];
        [wAppDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:^{
            wAppDelegate.authController = nil;
        }];
    }];
    self.authController.authRequestDidBegin = ^{
        [SVProgressHUD show];
    };
    self.authController.authRequestDidFinish = ^(BOOL success) {
        if (success) {
            [SVProgressHUD showAutodismissingSuccessWithStatus:@"Success"];
            
            [wAppDelegate showPadFilesListIfNecessary];
        } else {
            [SVProgressHUD dismiss];
        }
    };
	
	ORBNavigationController *navController = [[ORBNavigationController alloc] initWithRootViewController:self.authController];
	
	if (ORBIsPad) {
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		animated = YES;
	}
	
	[self.window.rootViewController presentViewController:navController animated:animated completion:nil];
}

- (void)logout:(id)sender {
    [self.dataSource logOut];
    [self.filesController dismissViewControllerAnimated:ORBIsPad completion:^{
		if (self.splitViewController) {
			self.splitViewController.viewControllers = @[self.filesController.navigationController, [[ORBNavigationController alloc] initWithRootViewController:[[ORBNoSelectionViewController alloc] init]]];
		}
		
        [self.filesController reloadData];
        [self authenticateAnimated:YES];
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.filesController possiblyDropPages];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if (self.dataSource.canRefreshFiles) {
        [self.filesController fetchFilesWithCompletion:nil];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - ADNLoginDelegate

- (void)adnLoginDidSucceedForUserWithID:(NSString *)userID
                               username:(NSString *)username
                                  token:(NSString *)accessToken {
    // Stash token in Keychain, make client request with ADNKit, etc.
    if (self.authController) {
        [self.authController authDidCompleteExternallyWithAccessToken:accessToken];
    }
}

- (void)adnLoginDidFailWithError:(NSError *)error {
    // Report error to user.
    // App.net Passport 1.0.474 does not currently call this method, but newer versions will.
    [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
}

#pragma mark - UIAppearance

- (void)setUpAppearance {
    [UINavigationBar appearance].tintColor = kORBTintColor;
    
    ORBNavigationBar *navBarStyle = [ORBNavigationBar appearance];
    navBarStyle.barTintColor = kORBBarTintColor;
    navBarStyle.tintColor = [UIColor whiteColor];
    navBarStyle.titleTextAttributes = @{NSFontAttributeName: [UIFont fontWithName:kORBFontMedium size:20.0], NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    [navBarStyle setTitleVerticalPositionAdjustment:-1.0 forBarMetrics:UIBarMetricsDefault];
    
    ORBToolbar *toolBarStyle = [ORBToolbar appearance];
    toolBarStyle.barTintColor = kORBBarTintColor;
    
    UISwitch *switchStyle = [UISwitch appearance];
    switchStyle.onTintColor = kORBTintColor;
    
    UIBarButtonItem *barButtonItemStyle = [UIBarButtonItem appearance];
    [barButtonItemStyle setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:kORBFontRegular size:16.0], NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    
    UITextField *searchTextFieldStyle = [UITextField appearanceWhenContainedIn:[UISearchBar class], nil];
    searchTextFieldStyle.font = [UIFont fontWithName:kORBFontRegular size:12.0];
    
    SVProgressHUD *progressHUDStyle = [SVProgressHUD appearance];
    [progressHUDStyle setHudFont:[UIFont fontWithName:kORBFontRegular size:16.0]];
    
    if (SYSTEM_VERSION_AT_LEAST(@"7.0.3")) {
        progressHUDStyle.hudBackgroundColor = [UIColor darkGrayColor];
    } else {
        progressHUDStyle.hudBackgroundColor = [UIColor blackColor];
    }
    progressHUDStyle.hudForegroundColor = [UIColor whiteColor];
}

@end
