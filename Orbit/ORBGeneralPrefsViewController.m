//
//  ORBGeneralPrefsViewController.m
//  Orbit
//
//  Created by Levin, Joel A on 4/25/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBGeneralPrefsViewController.h"


@implementation ORBGeneralPrefsViewController

- (NSString *)identifier {
	return @"general";
}


- (NSString *)toolbarItemLabel {
	return @"General";
}


- (NSImage *)toolbarItemImage {
	return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}


- (void)awakeFromNib {
	self.launchAtLoginButton.target = [ORBAppDelegate sharedAppDelegate];
	self.launchAtLoginButton.action = @selector(shouldLaunchAtLoginChanged:);
}


- (void)viewWillAppear {
	self.launchAtLoginButton.state = [ORBAppDelegate sharedAppDelegate].shouldLaunchAtLogin ? NSOnState : NSOffState;
}


@end
