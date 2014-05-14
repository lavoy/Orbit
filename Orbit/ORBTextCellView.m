//
//  ORBTextCellView.m
//  Orbit
//
//  Created by Joel Levin on 3/23/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBTextCellView.h"
#import "ORBWhiteProgressIndicator.h"


@interface ORBTextCellView ()

@property (strong) ORBWhiteProgressIndicator *progressIndicator;

@end


@implementation ORBTextCellView


- (void)textFieldTextDidChange:(NSTextField *)textField {
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	if (self.target && self.action) {
		if ([self.target respondsToSelector:self.action]) {
			[self.target performSelector:self.action withObject:self withObject:textField.stringValue];
		}
	}
	#pragma clang diagnostic pop
}


- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
	BOOL isSelected = (backgroundStyle == NSBackgroundStyleDark);
	if (self.customTextColor) {
		self.textField.textColor = isSelected ? [NSColor whiteColor] : self.customTextColor;
	} else {
		self.textField.textColor = [NSColor blackColor];
	}
	
	if (self.progressIndicator) {
		self.progressIndicator.style = isSelected ? ORBWhiteProgressIndicatorStyleForDarkBackground : ORBWhiteProgressIndicatorStyleForLightBackground;
		[self.progressIndicator setNeedsDisplay:YES];
	}
	
	self.textField.target = self;
	self.textField.action = @selector(textFieldTextDidChange:);
	[super setBackgroundStyle:backgroundStyle];
}


- (void)showProgressForFile:(ORBFileWrapper *)fileWrapper {
	self.textField.stringValue = @"";
	
	if (!self.progressIndicator) {
		self.progressIndicator = [[ORBWhiteProgressIndicator alloc] initWithFrame:NSMakeRect(0.0, 6.0, 58.0, 7.0)];
		self.progressIndicator.indeterminate = NO;
		self.progressIndicator.maxValue = 1.0;
		self.progressIndicator.minValue = 0.0;
		[self addSubview:self.progressIndicator];
	}
	
	self.progressIndicator.doubleValue = fileWrapper.progress;
	[self.progressIndicator setNeedsDisplay:YES];
}


- (void)hideProgress {
	if (self.progressIndicator) {
		[self.progressIndicator removeFromSuperview];
		self.progressIndicator = nil;
	}
}


@end
