//
//  ORBAdvancedPrefsViewController.m
//  Orbit
//
//  Created by Joel Levin on 5/3/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBAdvancedPrefsViewController.h"


@implementation ORBAdvancedPrefsViewController

- (NSString *)identifier {
	return @"advanced";
}


- (NSString *)toolbarItemLabel {
	return @"Advanced";
}


- (NSImage *)toolbarItemImage {
	return [NSImage imageNamed:NSImageNameAdvanced];
}


- (void)awakeFromNib {
	NSString *message = @"We do NOT track any specifics of any data.\n\n"
						@"That means we do NOT track the names of the files you upload, the URLs of the files you upload, or the content of the files you upload.\n\n"
						@"What we do track are simple statistics so that we can understand global usage figures such as uploads-per-day. When this option is enabled, the usage data we will record deals entirely in numbers and has no user information tied to it.\n\n"
						@"Please contact support@orbitapp.net or message us on App.net if you have any questions.";
	
	NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:11.0], NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.2 alpha:1.0]}];
	
	// highlight the email
	NSRange emailRange = [[attributedMessage string] rangeOfString:@"support@orbitapp.net" options:NSLiteralSearch];
	if (emailRange.location != NSNotFound) {
		[attributedMessage addAttributes:@{NSLinkAttributeName: [NSURL URLWithString:@"mailto:support@orbitapp.net"]} range:emailRange];
	}
	
	// highlight the 'message us at...'
	NSRange pmMessageRange = [[attributedMessage string] rangeOfString:@"message us on App.net" options:NSLiteralSearch];
	if (pmMessageRange.location != NSNotFound) {
		[attributedMessage addAttributes:@{NSLinkAttributeName: [NSURL URLWithString:@"https://alpha.app.net/orbit"]} range:pmMessageRange];
	}
	
	// highlight all NOT's
	NSRange notRange = [[attributedMessage string] rangeOfString:@"NOT" options:NSLiteralSearch];
	while (notRange.location != NSNotFound) {
		[attributedMessage addAttributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:11.0]} range:notRange];
		NSUInteger nextOffset = notRange.location + notRange.length;
		notRange = [[attributedMessage string] rangeOfString:@"NOT" options:NSLiteralSearch range:NSMakeRange(nextOffset, [attributedMessage string].length - nextOffset)];
	}
	
	[self.usageMessageView.textStorage setAttributedString:attributedMessage];
}


@end
