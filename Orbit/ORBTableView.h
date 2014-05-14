//
//  ORBTableView.h
//  Orbit
//
//  Created by Levin, Joel A on 3/21/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ORBTableView : NSTableView

@property (strong) NSString *selectionPersistenceKeyPath;
@property (strong) NSString *currentSelectionValue;

@end
