//
//  ORBAuthViewController
//  Orbit
//
//  Created by Andy LaVoy on 7/05/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORBAuthViewController : UITableViewController <UITextFieldDelegate>

- (id)initWithClient:(ANKClient *)client clientID:(NSString *)clientID passwordGrantSecret:(NSString *)passwordGrantSecret authScopes:(ANKAuthScope)authScopes completion:(void (^)(ANKClient *authedClient, NSError *error, ORBAuthViewController *controller))completionHandler;
- (void)cancel;

- (void)authDidCompleteExternallyWithAccessToken:(NSString *)accessToken;

// set these blocks if you want to show a loading UI during the request
@property (copy) void (^authRequestDidBegin)(void);
@property (copy) void (^authRequestDidFinish)(BOOL success);

@end
