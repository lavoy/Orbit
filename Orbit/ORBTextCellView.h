//
//  ORBTextCellView.h
//  Orbit
//
//  Created by Joel Levin on 3/23/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ORBTextCellView : NSTableCellView <NSTextFieldDelegate>

@property (strong) NSColor *customTextColor;
@property (weak) id target;
@property (assign) SEL action;

- (void)showProgressForFile:(ORBFileWrapper *)fileWrapper;
- (void)hideProgress;

@end
