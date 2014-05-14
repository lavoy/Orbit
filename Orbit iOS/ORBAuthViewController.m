//
//  ORBAuthViewController
//  Orbit
//
//  Created by Andy LaVoy on 7/05/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBAuthViewController.h"
#import "ADNKit/ANKTextFieldCell.h"
#import "RPSTPasswordManagementAppService.h"
#import "ADNLogin.h"
#import "ORBPassportLaunchView.h"

#define ADN_PASSPORT 1

typedef NS_ENUM(NSInteger, ANKCellType) {
	ANKCellTypeUsername = 0,
	ANKCellTypePassword,
	ANKTotalCellsCount
};

#if ADN_PASSPORT
@interface ORBAuthViewController () <ADNPassportLaunchViewDelegate>
#else
@interface ORBAuthViewController ()
#endif

@property (strong) ANKClient *client;
@property (strong) NSString *clientID;
@property (strong) NSString *passwordGrantSecret;
@property (assign) ANKAuthScope authScopes;
@property (copy) void (^authDidFinishHandler)(ANKClient *authedClient, NSError *error, ORBAuthViewController *controller);
@property (weak) UIButton *authButton;

#if ADN_PASSPORT
@property (strong) UIView *passportContainerView;
@property (strong) ORBPassportLaunchView *passportLaunchView;
@property (assign) BOOL passportLaunchViewShown;
#endif

- (void)tryAuth:(id)sender;

@end


@implementation ORBAuthViewController

- (id)initWithClient:(ANKClient *)client
            clientID:(NSString *)clientID
 passwordGrantSecret:(NSString *)passwordGrantSecret
          authScopes:(ANKAuthScope)authScopes
          completion:(void (^)(ANKClient *authedClient, NSError *error, ORBAuthViewController *controller))completionHandler {
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.authDidFinishHandler = completionHandler;
		self.client = client;
		self.title = @"Log in to App.net";
		
		self.clientID = clientID;
		self.passwordGrantSecret = passwordGrantSecret;
		self.authScopes = authScopes;
        self.view.tintColor = kORBTintColor;
	}
	return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
	CGFloat buttonLeftOffset = ORBIsPhone ? 10.0 : 30.0;
	CGFloat buttonTopOffset = ORBIsPhone ? 0.0 : 10.0;
	CGFloat footerHeight = ORBIsPhone ? 54.0 : 64.0;
	
	UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frameWidth, footerHeight)];
	footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.authButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[self.authButton setTitle:@"Log in" forState:UIControlStateNormal];
	[self.authButton sizeToFit];
	self.authButton.frame = CGRectMake(buttonLeftOffset, buttonTopOffset, self.view.frameWidth - (buttonLeftOffset * 2.0), self.authButton.frameHeight);
	self.authButton.titleLabel.font = [UIFont fontWithName:kORBFontDemiBold size:18];
	[self.authButton addTarget:self action:@selector(tryAuth:) forControlEvents:UIControlEventTouchUpInside];
	self.authButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[footerView addSubview:self.authButton];
	
	self.tableView.tableFooterView = footerView;
    
#if ADN_PASSPORT
    self.passportLaunchView = [[ORBPassportLaunchView alloc] init];
    self.passportLaunchView.backgroundColor = [UIColor clearColor];
    self.passportLaunchView.button.titleLabel.font = [UIFont fontWithName:kORBFontDemiBold size:16];
    self.passportLaunchView.signupLabel.font = [UIFont fontWithName:kORBFontRegular size:14];
    self.passportLaunchView.signupLabel.textColor = [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1.0];
    self.passportLaunchView.waitingLabel.font = self.passportLaunchView.signupLabel.font;
    self.passportLaunchView.waitingLabel.textColor = self.passportLaunchView.signupLabel.textColor;
    self.passportLaunchView.delegate = self;
	[self.view addSubview:self.passportLaunchView];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adnLoginDidEndPolling:) name:kADNLoginDidEndPollingNotification object:nil];
#endif
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
    
#if ADN_PASSPORT
	if (!self.passportLaunchViewShown) {
		self.passportLaunchViewShown = YES;
		
		if (ORBIsPad) {
			self.passportLaunchView.button.frameX = floor((self.view.boundsWidth / 2.0) - (self.passportLaunchView.button.boundsWidth / 2.0));
			self.passportLaunchView.signupLabel.frameX = floor((self.view.boundsWidth / 2.0) - (self.passportLaunchView.signupLabel.boundsWidth / 2.0));
			self.passportLaunchView.waitingLabel.frameX = floor((self.view.boundsWidth / 2.0) - (self.passportLaunchView.waitingLabel.boundsWidth / 2.0)) + self.passportLaunchView.activityIndicator.boundsWidth;
			self.passportLaunchView.waitingLabel.textAlignment = NSTextAlignmentCenter;
			self.passportLaunchView.activityIndicator.frameX = self.passportLaunchView.waitingLabel.frameX;
		}
		
		[self.passportLaunchView animateToVisibleStateWithCompletion:nil];
	}
#endif
}

- (void)viewDidUnload {
	[super viewDidUnload];
    
#if ADN_PASSPORT
	self.passportLaunchViewShown = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
}


- (void)tryAuth:(id)sender {
	ANKTextFieldCell *usernameFieldCell = [self usernameFieldCell];
	ANKTextFieldCell *passwordFieldCell = [self passwordFieldCell];
    
    if ([usernameFieldCell.textField.text length] > 0 && [passwordFieldCell.textField.text length] > 0) {
        self.authButton.enabled = NO;
        usernameFieldCell.textField.enabled = NO;
        passwordFieldCell.textField.enabled = NO;
        
        if (self.authRequestDidBegin) {
            self.authRequestDidBegin();
        }
        
        [self.client authenticateUsername:usernameFieldCell.textField.text
                                 password:passwordFieldCell.textField.text
                                 clientID:self.clientID
                      passwordGrantSecret:self.passwordGrantSecret
                               authScopes:self.authScopes
                        completionHandler:^(BOOL success, NSError *error) {
                            if (success) {
                                self.authDidFinishHandler(self.client, nil, self);
                            } else {
                                self.authDidFinishHandler(nil, error, self);
                                self.authButton.enabled = YES;
                                
                                usernameFieldCell.textField.enabled = YES;
                                passwordFieldCell.textField.enabled = YES;
                            }
                            
                            if (self.authRequestDidFinish) {
                                self.authRequestDidFinish(success);
                            }
                        }];
    }
}


- (void)cancel {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)authDidCompleteExternallyWithAccessToken:(NSString *)accessToken {
    if (self.authDidFinishHandler) {
        if (self.authRequestDidBegin) {
            self.authRequestDidBegin();
        }
        
        [self.client logInWithAccessToken:accessToken completion:^(BOOL succeeded, ANKAPIResponseMeta *meta, NSError *error) {
            if (succeeded) {
                self.authDidFinishHandler(self.client, nil, self);
            } else {
                self.authDidFinishHandler(nil, error, self);
                self.authButton.enabled = YES;
                
                [self usernameFieldCell].textField.enabled = YES;
                [self usernameFieldCell].textField.enabled = YES;
            }
            
            if (self.authRequestDidFinish) {
                self.authRequestDidFinish(succeeded);
            }
        }];
    }
}


#pragma mark - UITableViewDataSourc


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ANKTotalCellsCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *const cellIdentifier = @"Cell";
	ANKTextFieldCell *cell = (ANKTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[ANKTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.textField.delegate = self;
        cell.textField.font = [UIFont fontWithName:kORBFontMedium size:18];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	if (indexPath.row == ANKCellTypeUsername) {
		cell.textField.placeholder = @"Username";
		cell.textField.returnKeyType = UIReturnKeyNext;
        cell.accessoryView = nil;
	} else if (indexPath.row == ANKCellTypePassword) {
		cell.textField.placeholder = @"Password";
		cell.textField.secureTextEntry = YES;
		cell.textField.returnKeyType = UIReturnKeyGo;
        
        if ([RPSTPasswordManagementAppService passwordManagementAppIsAvailable]) {
            UIButton *onePassButton = [UIButton buttonWithType:UIButtonTypeCustom];
            UIImage *onePassImage = [UIImage imageNamed:@"one-password-text-field"];
            onePassButton.frameSize = onePassImage.size;
            onePassButton.accessibilityLabel = @"1Password";
            [onePassButton setImage:onePassImage forState:UIControlStateNormal];
            cell.accessoryView = onePassButton;
            
            [onePassButton handleControlEvents:UIControlEventTouchUpInside withBlock:^(id weakSender) {
                NSURL *URL = [RPSTPasswordManagementAppService passwordManagementAppCompleteURLForSearchQuery:@"app.net"];
                [[UIApplication sharedApplication] openURL:URL];
            }];
        } else {
            cell.accessoryView = nil;
        }
	}
	
	return cell;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	ANKTextFieldCell *usernameFieldCell = [self usernameFieldCell];
	ANKTextFieldCell *passwordField = [self passwordFieldCell];
	
	if (textField == usernameFieldCell.textField) {
		[passwordField.textField becomeFirstResponder];
	} else if (textField == passwordField.textField) {
		[self tryAuth:nil];
	}
	
	return NO;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	BOOL shouldChange = textField.isSecureTextEntry;
	
	if (!shouldChange) {
		NSMutableString *mutableString = [textField.text mutableCopy];
		[mutableString replaceCharactersInRange:range withString:string];
		shouldChange = ![mutableString hasPrefix:@"@"] && ([mutableString rangeOfString:@" "].location == NSNotFound);
	}
	
	return shouldChange;
}

#pragma mark - TextField Convenience

- (ANKTextFieldCell *)usernameFieldCell {
    return (ANKTextFieldCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:ANKCellTypeUsername inSection:0]];
}

- (ANKTextFieldCell *)passwordFieldCell {
    return (ANKTextFieldCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:ANKCellTypePassword inSection:0]];
}

#pragma mark - UIScrollViewDelegate 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {    
    [[self usernameFieldCell].textField resignFirstResponder];
    [[self passwordFieldCell].textField resignFirstResponder];
}

#if ADN_PASSPORT

#pragma mark - ADNPassportLaunchView Observers

- (void)adnLoginDidEndPolling:(NSNotification *)notification {
	[self.passportLaunchView animateToVisibleStateWithCompletion:nil];
}

#pragma mark - ADNPassportLaunchViewDelegate

- (void)adnPassportLaunchViewDidRequestInstall:(ADNPassportLaunchView *)passportLaunchView {
	[self.passportLaunchView animateToPollingStateWithCompletion:nil];
    
	[[ADNLogin sharedInstance] passportProductViewControllerWithCompletionBlock:^(SKStoreProductViewController *storeViewController, BOOL result, NSError *error) {
        
		if (error == nil) {
			[self presentViewController:storeViewController animated:YES completion:nil];
		} else {
			NSLog(@"Error loading store: %@", error);
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
		}
	}];
}

- (void)adnPassportLaunchViewDidRequestLogin:(ADNPassportLaunchView *)passportLaunchView {
	[[ADNLogin sharedInstance] login];
}

#endif

@end
