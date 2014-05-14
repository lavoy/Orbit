//
//  JJGWebView.m
//
//  Created by Jeff Geerling on 2/11/11.
//  Copyright 2011 Midwestern Mac, LLC. All rights reserved.
//

#import "JJGWebViewController.h"
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import "ORBToolbar.h"

@interface JJGWebViewController () <UIActionSheetDelegate, UITextFieldDelegate, UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIToolbar *webViewToolbar;
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *refreshButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *forwardButton;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIActionSheet *sharingActionSheet;

@property (nonatomic, strong) NSURL *webViewURL;

- (IBAction)actionButtonSelected:(id)sender;

@end

@implementation JJGWebViewController

#pragma mark Regular controller methods

+ (JJGWebViewController *)webViewControllerWithURL:(NSURL *)URL title:(NSString *)title {
    JJGWebViewController *webVC = [[JJGWebViewController alloc] init];
    if (webVC) {
        webVC.webViewURL = URL;
        webVC.title = title;
        webVC.hidesBottomBarWhenPushed = YES;
    }
    
    return webVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	if (self.webViewURL) {
		// webViewURL gets passed in from other views - form URL request with it
		NSURLRequest *requestObj = [NSURLRequest requestWithURL:self.webViewURL];
		// Load URL in UIWebView
		[self.webView loadRequest:requestObj];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	// We allow rotation.
    return YES;
}

#pragma mark Web View methods

- (void)webViewDidStartLoad:(UIWebView *)wv {
	[self.activityIndicator startAnimating];

	// Disable Action bar button item...
	self.actionButton.enabled = self.refreshButton.enabled = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
	[self.activityIndicator stopAnimating];

	// Enable Action bar button item...
	self.actionButton.enabled = self.refreshButton.enabled = YES;

	[self.backButton setEnabled:[self.webView canGoBack]]; // Enable or disable back
	[self.forwardButton setEnabled:[self.webView canGoForward]]; // Enable or disable forward
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error {
	[self.activityIndicator stopAnimating];

    NSLog(@"web view loading error: %@", error);
}

#pragma mark IBAction outlets

- (IBAction)actionButtonSelected:(id)sender {
    [self shareActivityItem:self.webViewURL];
}

@end
