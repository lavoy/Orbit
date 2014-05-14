//
//  JJGWebView.h
//
//  Created by Jeff Geerling on 2/11/11.
//  Copyright 2011 Midwestern Mac, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JJGWebViewController : UIViewController {}

+ (JJGWebViewController *)webViewControllerWithURL:(NSURL *)URL title:(NSString *)title;

@end
