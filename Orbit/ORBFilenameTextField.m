//
//  ORBFilenameTextField.m
//  Orbit
//
//  Created by Joel Levin on 5/5/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBFilenameTextField.h"


@implementation ORBFilenameTextField

- (void)textViewDidChangeSelection:(NSNotification *)notification {
	NSTextView *textView = [notification object];
	if (textView.string.pathExtension.length > 0 && [textView.string substringWithRange:textView.selectedRange].length == textView.string.length) {
		NSString *pathExtension = textView.string.pathExtension;
		[textView setSelectedRange:NSMakeRange(0, textView.string.length - pathExtension.length - 1)]; // minus one for the dot
	}
}


@end
