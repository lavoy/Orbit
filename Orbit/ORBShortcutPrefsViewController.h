//
//  ORBShortcutPrefsViewController.h
//  Orbit
//
//  Created by Joel Levin on 5/3/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ORBBasePrefsViewController.h"


@class MASShortcutView;

@interface ORBShortcutPrefsViewController : ORBBasePrefsViewController

@property (nonatomic, assign) IBOutlet MASShortcutView *uploadFilesShortcutView;
@property (nonatomic, assign) IBOutlet MASShortcutView *uploadClipboardShortcutView;
@property (nonatomic, assign) IBOutlet MASShortcutView *toggleOrbitShortcutView;

@end
