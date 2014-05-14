//
//  StatusItemView.m
//  NetBox
//
//  Created by Andy LaVoy on 3/30/13.
//  Copyright (c) 2013 Andy LaVoy. All rights reserved.
//

#import "ORBStatusItemIconView.h"
#import "YRKSpinningProgressIndicator.h"
#import "ORBMenuController.h"
#import "ORBTableView.h"
#import <ADNKit/NSArray+ANKAdditions.h>


@interface ORBStatusItemIconView ()

@property (nonatomic, assign) BOOL isShowingMenu;
@property (nonatomic, assign) BOOL isDropping;
@property (nonatomic, strong) YRKSpinningProgressIndicator *progressIndicator;
@property (nonatomic, assign) id <ORBStatusItemIconViewDelegate> delegate;

@end


@implementation ORBStatusItemIconView

- (id)initWithStatusItem:(NSStatusItem *)statusItem delegate:(id <ORBStatusItemIconViewDelegate>)delegate {
    if (self = [super initWithFrame:NSMakeRect(0.0, 0.0, [statusItem length], [[NSStatusBar systemStatusBar] thickness])]) {
        self.statusItem = statusItem;
        self.statusItem.view = self;
		self.imageOpacity = 1.0;
        
        self.delegate = delegate;
        
        [self registerForDraggedTypes:@[(__bridge NSString *)kUTTypeFileURL]];
    }
    return self;
}


- (NSRect)rect {
    NSRect statusViewRect = [self frame];
    statusViewRect.origin = [self.window convertBaseToScreen:[self frame].origin];
    statusViewRect.origin.y = NSMinY(statusViewRect) - NSHeight(statusViewRect);
    
    return statusViewRect;
}


- (void)mouseDown:(NSEvent *)theEvent {
    if (([theEvent modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) {
        [self.delegate statusItemViewActivatedSecondary:self];
    } else {
        [self.delegate statusItemViewActivatedPrimary:self];
    }
}


- (void)rightMouseDown:(NSEvent *)theEvent {
	if (!self.isHighlighted) {
		[self.delegate statusItemViewActivatedSecondary:self];
	}
}


- (void)showMenu {
	if (self.isShowingMenu) return;
	
	self.isHighlighted = YES;
	self.isShowingMenu = YES;
	NSMenu *menu = [ORBMenuController mainMenu];
	[menu setDelegate:self];
    [self.statusItem popUpStatusItemMenu:menu];
}


- (void)menuDidClose:(NSMenu *)menu {
	self.isHighlighted = NO;
	self.isShowingMenu = NO;
}


- (void)drawRect:(NSRect)dirtyRect {
	[self.statusItem drawStatusBarBackgroundInRect:self.bounds withHighlight:self.isHighlighted];
	
    if (!self.isSpinning) {
        NSImage *icon = self.isHighlighted ? self.highlightedImage : self.image;
        NSSize iconSize = [icon size];
        NSRect bounds = self.bounds;
        CGFloat iconX = roundf((NSWidth(bounds) - iconSize.width) / 2);
        CGFloat iconY = roundf((NSHeight(bounds) - iconSize.height) / 2);
        NSPoint iconPoint = NSMakePoint(iconX, iconY);
		iconPoint.y += 1.0;
        
        [icon drawAtPoint:iconPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:self.imageOpacity];
    }
}


- (void)startSpinning {
    if (!self.isSpinning) {
        self.isSpinning = YES;
        
        NSInteger size = 16;
        CGRect rect = CGRectMake(round(self.bounds.size.width / 2 - size / 2), round(self.bounds.size.height / 2 - size / 2) + 1.0, size, size);
        
		@synchronized (self) {
			if (!self.progressIndicator) {
				self.progressIndicator = [[YRKSpinningProgressIndicator alloc] initWithFrame:rect];
				self.progressIndicator.displayedWhenStopped = NO;
				self.progressIndicator.usesThreadedAnimation = NO;
			}
			
			self.progressIndicator.color = self.isHighlighted ? [NSColor whiteColor] : [NSColor blackColor];
			[self.progressIndicator startAnimation:nil];
			[self addSubview:self.progressIndicator];
		}
        
        [self setNeedsDisplay:YES];
    }
}


- (void)stopSpinning {
    if (self.isSpinning) {
        self.isSpinning = NO;
        
		@synchronized (self) {
			[self.progressIndicator stopAnimation:nil];
			[self.progressIndicator removeFromSuperview];
		}
        
        [self setNeedsDisplay:YES];
    }
}


#pragma mark -
#pragma mark Accessors

- (void)setIsHighlighted:(BOOL)isHighlighted {
    if (_isHighlighted != isHighlighted) {
        _isHighlighted = isHighlighted;
        [self setNeedsDisplay:YES];
		
		if (self.isSpinning) {
			self.progressIndicator.color = isHighlighted ? [NSColor whiteColor] : [NSColor blackColor];
		}
    }
}


#pragma mark -

- (void)setImage:(NSImage *)newImage {
    if (_image != newImage) {
        _image = newImage;
        [self setNeedsDisplay:YES];
    }
}


- (void)setHighlightedImage:(NSImage *)highlightedImage {
    if (_highlightedImage != highlightedImage) {
        _highlightedImage = highlightedImage;
        if (self.isHighlighted) {
            [self setNeedsDisplay:YES];
        }
    }
}


#pragma mark - Drag and Drop

- (NSDragOperation)dragOperationFromInfo:(id <NSDraggingInfo>)info {
	BOOL shouldBlockDrop = YES;
    
	NSArray *files = [[info draggingPasteboard] readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
    shouldBlockDrop = ![[ORBAppDelegate sharedAppDelegate] shouldAllowPathsToUpload:files];
    
    return shouldBlockDrop ? NSDragOperationNone : NSDragOperationCopy;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	return [self dragOperationFromInfo:sender];
}


- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	NSEvent *currentEvent = [[NSApplication sharedApplication] currentEvent];
	 // these must represent either escape or a special 'drag cancelled' mask of some sort
	NSUInteger privateModifierMask1 = 1 << 6;
	NSUInteger privateModifierMask2 = 1 << 8;
	BOOL dragWasCancelled = ((currentEvent.modifierFlags & privateModifierMask1) == privateModifierMask1) || ((currentEvent.modifierFlags & privateModifierMask2) == privateModifierMask2);
	
	// this is a workaround from: http://stackoverflow.com/questions/9534543/weird-behavior-dragging-from-stacks-to-status-item-doesnt-work
    if (NSPointInRect([sender draggingLocation], self.frame) && !dragWasCancelled) {
		if ([self prepareForDragOperation:sender]) {
			// The file was actually dropped on the view so call the performDrag manually
			[self performDragOperation:sender];
		}
    }
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return [self dragOperationFromInfo:sender] != NSDragOperationNone;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSArray *droppedFiles = [[sender draggingPasteboard] readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
    
    if ([droppedFiles count] > 0) {
        [[sender draggingPasteboard] clearContents];
		[self.delegate statusItemView:self didReceiveDropForURLs:droppedFiles];
    }
    
    return YES;
}


@end
