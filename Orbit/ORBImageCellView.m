//
//  ORBFileCellView.m
//  Orbit
//
//  Created by Joel Levin on 3/23/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBImageCellView.h"


@implementation ORBImageCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
	self.imageView.image = [NSImage imageNamed:(backgroundStyle == NSBackgroundStyleDark ? self.highlightedImageName : self.imageName)];
	[super setBackgroundStyle:backgroundStyle];
}

@end
