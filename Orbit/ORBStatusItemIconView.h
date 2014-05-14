//
//  StatusItemView.h
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

@class ORBStatusItemIconView;

@protocol ORBStatusItemIconViewDelegate <NSObject>

- (void)statusItemViewActivatedPrimary:(ORBStatusItemIconView *)statusItemView;
- (void)statusItemViewActivatedSecondary:(ORBStatusItemIconView *)statusItemView;
- (void)statusItemView:(ORBStatusItemIconView *)statusItemView didReceiveDropForURLs:(NSArray *)URLs;

@end

@interface ORBStatusItemIconView : NSView <NSMenuDelegate, NSDraggingDestination>

- (id)initWithStatusItem:(NSStatusItem *)statusItem delegate:(id <ORBStatusItemIconViewDelegate>)delegate;

@property (nonatomic, weak) NSStatusItem *statusItem;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSImage *highlightedImage;
@property (nonatomic, assign) CGFloat imageOpacity;

@property (nonatomic, assign) BOOL isHighlighted;
@property (nonatomic, assign) BOOL isSpinning;
@property (nonatomic, assign) SEL action;
@property (nonatomic, weak) id target;

- (void)showMenu;
- (void)startSpinning;
- (void)stopSpinning;

- (NSRect)rect;

@end
