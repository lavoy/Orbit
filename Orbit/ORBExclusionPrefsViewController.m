//
//  ORBExclusionPrefsViewController.m
//  Orbit
//
//  Created by Joel Levin on 5/13/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBExclusionPrefsViewController.h"
#import "ORBExclusionRule.h"
#import "ORBCheckboxTableCellView.h"
#import "ORBImageCellView.h"


@interface ORBExclusionPrefsViewController ()

@property (nonatomic, strong) IBOutlet NSTableView *rulesTableView;

@end


@implementation ORBExclusionPrefsViewController

- (NSString *)identifier {
	return @"exclusions";
}


- (NSString *)toolbarItemLabel {
	return @"Exclusions";
}


- (NSImage *)toolbarItemImage {
	return [NSImage imageNamed:@"appbadge-prefs"];
}


- (void)viewWillAppear {
	[super viewWillAppear];
	[self.rulesTableView reloadData];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[[ORBPreferences preferences] allExclusionRules] count];
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	ORBExclusionRule *rule = [[ORBPreferences preferences] allExclusionRules][row];
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	cellView.objectValue = rule;
	
	if ([tableColumn.identifier isEqualToString:@"source"]) {
		ORBImageCellView *imageCellView = (ORBImageCellView *)cellView;
        
        imageCellView.imageName = [rule imageString];
        imageCellView.highlightedImageName = [rule highlightedImageString];
	}
	
	return cellView;
}


@end
