//
//  ORBMenuController.m
//  Orbit
//
//  Created by Joel Levin on 3/22/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBMenuController.h"
#import "ORBAppDelegate.h"
#import "NSMenuItem+Orbit.h"


typedef NS_ENUM(NSUInteger, ORBMenuItem) {
	ORBMenuItemPreferences = 0,
	// -------------------------
	ORBMenuItemLogOut = 2,
	// -------------------------
	ORBMenuItemCheckForUpdates = 4,
	ORBMenuItemAboutOrbit = 5,
	ORBMenuItemQuitOrbit = 6
};


@interface ORBMenuController ()

+ (NSDictionary *)menuItems;
+ (NSDictionary *)stateKeyPaths;
+ (NSDictionary *)enabledKeyPaths;

@end


@implementation ORBMenuController

+ (NSDictionary *)menuItems {
	return @{
		@(ORBMenuItemPreferences): [NSMenuItem itemWithTitle:@"Preferences..." target:[ORBAppDelegate sharedAppDelegate] action:@selector(showPreferencesWindow:) keyEquivalent:@"," tag:ORBMenuItemPreferences],
		@(ORBMenuItemLogOut): [NSMenuItem itemWithTitle:[NSString stringWithFormat:@"Log Out %@", [ORBAppDelegate sharedAppDelegate].isLoggedIn ? [ORBAppDelegate sharedAppDelegate].currentLoggedInUsername : @""] target:[ORBAppDelegate sharedAppDelegate] action:@selector(logout:) keyEquivalent:@"" tag:ORBMenuItemLogOut],
        @(ORBMenuItemCheckForUpdates): [NSMenuItem itemWithTitle:@"Check for Updates..." target:[ORBAppDelegate sharedAppDelegate] action:@selector(checkForUpdates:) keyEquivalent:@"" tag:ORBMenuItemCheckForUpdates],
		@(ORBMenuItemAboutOrbit): [NSMenuItem itemWithTitle:@"About Orbit" target:[ORBAppDelegate sharedAppDelegate] action:@selector(aboutMenuItemSelected:) keyEquivalent:@"" tag:ORBMenuItemAboutOrbit],
		@(ORBMenuItemQuitOrbit): [NSMenuItem itemWithTitle:@"Quit Orbit" target:[NSApplication sharedApplication] action:@selector(terminate:) keyEquivalent:@"q" tag:ORBMenuItemQuitOrbit]
	};
}


+ (NSDictionary *)stateKeyPaths {
	return @{};
}


+ (NSDictionary *)enabledKeyPaths {
	return @{
		@(ORBMenuItemLogOut): @"canLogOut",
		@(ORBMenuItemCheckForUpdates): @"canCheckForUpdates"
	};
}


+ (NSMenu *)mainMenu {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"mainMenu"];
	[menu setAutoenablesItems:NO];
	
	NSDictionary *stateDictionary = [self stateKeyPaths];
	NSDictionary *enabledDictionary = [self enabledKeyPaths];
	
	NSArray *items = [[self menuItems] allValues];
	items = [items sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"tag" ascending:YES]]];
	
	NSInteger lastItemTag = 0;
	
	for (NSMenuItem *item in items) {
		if (item.tag - lastItemTag > 1) {
			[menu addItem:[NSMenuItem separatorItem]];
		}
		
		[menu addItem:item];
		
		if (stateDictionary[@(item.tag)]) {
			item.state = [[item.target valueForKey:stateDictionary[@(item.tag)]] boolValue] ? NSOnState : NSOffState;
		}
		
		if (enabledDictionary[@(item.tag)]) {
			[item setEnabled:[[item.target valueForKeyPath:enabledDictionary[@(item.tag)]] boolValue]];
		}
		
		lastItemTag = item.tag;
	}
	
	return menu;
}


+ (NSMenu *)mainMenuForPopUpButton {
	NSMenu *mainMenu = [self mainMenu];
	[mainMenu insertItem:[[NSMenuItem alloc] initWithTitle:@"(not shown)" action:NULL keyEquivalent:@""] atIndex:0];
	return mainMenu;
}


@end
