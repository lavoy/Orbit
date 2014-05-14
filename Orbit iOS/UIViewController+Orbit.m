//
//  UIViewController+Orbit.m
//  Orbit
//
//  Created by Andy LaVoy on 7/11/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "UIViewController+Orbit.h"
#import "ADNActivityCollection.h"

@implementation UIViewController (Orbit)

- (void)shareActivityItem:(id)activityItem {
    if (activityItem) {
        NSArray *applicationActivities = [ADNActivityCollection allActivities];
        NSArray *activityItems = @[activityItem];
        
        UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:applicationActivities];
        
        activityView.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeAssignToContact];
        
		UIViewController *parentVC = self;
		if (self.splitViewController) {
			parentVC = self.splitViewController;
		}
        [parentVC presentViewController:activityView animated:YES completion:nil];
    }
}

@end
