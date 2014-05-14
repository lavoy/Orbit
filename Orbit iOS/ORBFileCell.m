//
//  ORBFileCell.m
//  Orbit
//
//  Created by Andy LaVoy on 4/28/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import "ORBFileCell.h"

static CGFloat const kLeftEdge      = 48.0;
static CGFloat const kProgressTop   = 33.0;
static CGFloat const kIconOrigin    = 6.0;

@interface ORBFileCell ()

@end

@implementation ORBFileCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {        
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.progressView.frame = CGRectMake(kLeftEdge, kProgressTop, self.contentView.frameWidth - (kLeftEdge * 2), 0);
        self.progressView.hidden = YES;
        self.progressView.tintColor = kORBTintColor;
        [self.contentView addSubview:self.progressView];
        
        self.loadingActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.loadingActivityIndicator.autoresizingMask = UIViewAutoresizingFlexibleAllMargins;
        [self.contentView addSubview:self.loadingActivityIndicator];
        [self.loadingActivityIndicator centerInSuperview];
        
        self.textLabel.backgroundColor = [UIColor clearColor];
		self.textLabel.font = [UIFont fontWithName:kORBFontMedium size:16.0];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
		
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}


- (void)layoutSubviews {
	[super layoutSubviews];
    
	self.imageView.frame = CGRectMake(kIconOrigin, kIconOrigin, kFileCellIconSize, kFileCellIconSize);
    self.textLabel.frame = CGRectMake(kLeftEdge, 7.0, self.contentView.frameWidth - kLeftEdge - 4.0, 18.0);
    self.detailTextLabel.frame = CGRectMake(kLeftEdge, self.textLabel.frameBottom + 2.0, self.contentView.frameWidth - kLeftEdge, 15.0);
}


- (void)setAttributedDetailText:(NSAttributedString *)attributedDetailText {
    _attributedDetailText = attributedDetailText;
    self.detailTextLabel.attributedText = attributedDetailText;
}


+ (CGFloat)height {
    return kIconOrigin * 2 + kFileCellIconSize;
}


@end
