//
//  ORBFileCell.h
//  Orbit
//
//  Created by Andy LaVoy on 4/28/13.
//  Copyright (c) 2013 Log Cabin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDWebImageOperation.h"

static NSInteger const kFileCellIconSize = 35;

@interface ORBFileCell : UITableViewCell

@property (nonatomic, strong) NSAttributedString *attributedDetailText;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingActivityIndicator;
@property (nonatomic, strong) id <SDWebImageOperation> imageOperation;
@property (nonatomic, copy) ORBVoidBlock imageOperationCleanupBlock;

+ (CGFloat)height;

@end
