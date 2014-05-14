//
//  ORBBasePrefsViewController.m
//  Orbit
//
//  Created by Joel Levin on 5/4/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBBasePrefsViewController.h"


@implementation ORBBasePrefsViewController

- (id)init {
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		self.preferences = [ORBPreferences preferences];
		self.appDelegate = [ORBAppDelegate sharedAppDelegate];
	}
	return self;
}


- (NSString *)identifier {
	return nil;
}


- (NSString *)toolbarItemLabel {
	return nil;
}


- (NSImage *)toolbarItemImage {
	return nil;
}


- (void)viewWillAppear {
	
}


- (void)viewDidDisappear {
	
}


@end
