//
//  ORBPhotoBrowser.m
//  Orbit
//
//  Created by Joel Levin on 8/10/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBPhotoBrowser.h"


@interface MWPhotoBrowser (PrivateAPI)

- (void)performLayout;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;

@end


@interface ORBPhotoBrowser ()

@property (nonatomic, strong) UIBarButtonItem *actionButton;
@property (nonatomic, strong) UIActionSheet *sharingActionSheet;

@end


@implementation ORBPhotoBrowser

- (BOOL)wantsFullScreenLayout {
	return ORBIsPhone;
}


- (void)performLayout {
	[super performLayout];
	
	if (ORBIsPad) {
		__weak ORBPhotoBrowser *weakSelf = self;
		self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction block:^(id weakSender) {
			if (!weakSelf.sharingActionSheet) {
				weakSelf.sharingActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Share URL", @"Share Image", nil];
				[weakSelf.sharingActionSheet showFromBarButtonItem:weakSelf.navigationItem.rightBarButtonItem animated:YES];
			} else {
				[weakSelf.sharingActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
			}
		}];
		self.navigationItem.rightBarButtonItem = self.actionButton;
	}
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
	if (ORBIsPhone) {
		[super setControlsHidden:hidden animated:animated permanent:permanent];
	}
}

@end
