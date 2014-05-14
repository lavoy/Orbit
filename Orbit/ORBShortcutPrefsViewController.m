//
//  ORBShortcutPrefsViewController.m
//  Orbit
//
//  Created by Joel Levin on 5/3/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBShortcutPrefsViewController.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"


@implementation ORBShortcutPrefsViewController

- (NSString *)identifier {
	return @"shortcuts";
}


- (NSString *)toolbarItemLabel {
	return @"Shortcuts";
}


- (NSImage *)toolbarItemImage {
	return [NSImage imageNamed:@"shortcuts"];
}


- (void)awakeFromNib {
	self.uploadFilesShortcutView.associatedUserDefaultsKey = kORBUploadFilesShortcutKey;
	self.uploadClipboardShortcutView.associatedUserDefaultsKey = kORBUploadClipboardShortcutKey;
	self.toggleOrbitShortcutView.associatedUserDefaultsKey = kORBToggleOrbitWindowShortcutKey;
}


@end
