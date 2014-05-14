//
//  ORBBasePrefsViewController.h
//  Orbit
//
//  Created by Joel Levin on 5/4/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"


@interface ORBBasePrefsViewController : NSViewController <MASPreferencesViewController>

@property (nonatomic, weak) ORBPreferences *preferences;
@property (nonatomic, weak) ORBAppDelegate *appDelegate;

@end
