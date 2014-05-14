//
//  ORBTableView.m
//  Orbit
//
//  Created by Levin, Joel A on 3/21/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBTableView.h"


@implementation ORBTableView

- (NSMenu *)menuForEvent:(NSEvent *)event {
	NSPoint clickPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	NSInteger row = [self rowAtPoint:clickPoint];
	NSMenu *menu = [super menuForEvent:event];
	
	if (row > -1) {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	} else {
		menu = [menu copy];
		menu.autoenablesItems = NO;
		for (NSMenuItem *menuItem in menu.itemArray) {
			menuItem.enabled = NO;
		}
	}
	
	return [menu copy];
}


- (void)reloadData {
	[super reloadData];
	
	if (!self.currentSelectionValue) return;
	
	NSUInteger rowsCount = [self.dataSource numberOfRowsInTableView:self];
	for (NSUInteger rowIndex = 0; rowIndex < rowsCount; rowIndex++) {
		id objectValue = [self.dataSource tableView:self objectValueForTableColumn:nil row:rowIndex];
		if ([[objectValue valueForKeyPath:self.selectionPersistenceKeyPath] isEqualToString:self.currentSelectionValue]) {
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
			break;
		}
	}
}


@end
