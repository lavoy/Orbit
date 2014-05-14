//
//  ADNActivity.m
//  ADNActivityCollection
//
//  Created by Brennan Stehling on 3/2/13.
//  Copyright (c) 2013 SmallSharptools LLC. All rights reserved.
//

#import "ADNActivity.h"

@implementation ADNActivity

#pragma mark - Public Implementation
#pragma mark -

- (NSString *)encodedText {
    return [self encodeText:self.text];
}

- (NSString *)clientURLScheme {
    // override with Client URL Scheme
    return nil;
}

- (BOOL)isClientInstalled {
#if TARGET_IPHONE_SIMULATOR
    // provide an option for testing in the simulator where third party apps will not be installed
    return YES;
#else
    if (self.clientURLScheme != nil) {
        NSURL *url = [NSURL URLWithString:self.clientURLScheme];
        return [[UIApplication sharedApplication] canOpenURL:url];
    }
    
    return NO;
#endif
}

- (NSURL *)clientOpenURL {
    // reference only for implementing class
    if (self.clientURLScheme != nil) {
        NSString *urlString = [NSString stringWithFormat:@"%@/?post=%@", self.clientURLScheme, self.encodedText];
        NSString *appURLScheme = [self appURLScheme];
        if (appURLScheme != nil) {
            urlString = [NSString stringWithFormat:@"%@&returnURLScheme=%@", urlString, [self encodeText:appURLScheme]];
        }
#ifndef NDEBUG
        NSLog(@"clientOpenURL: %@", urlString);
#endif
        NSURL *openURL = [NSURL URLWithString:urlString];
        return openURL;
    }
    
    return nil;
}

- (NSString *)appURLScheme {
    NSArray *urlTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    if (urlTypes.count > 0) {
        NSDictionary *urlType = [urlTypes objectAtIndex:0];
        NSArray *urlSchemes = [urlType objectForKey:@"CFBundleURLSchemes"];
        if (urlSchemes.count > 0) {
            NSString *urlScheme = [urlSchemes objectAtIndex:0];
            NSLog(@"URL Scheme: %@", urlScheme);
            return [NSString stringWithFormat:@"%@://", urlScheme];
        }
    }
    
    return nil;
}

- (NSString *)encodeText:(NSString *)text {
    if (text == nil) {
        return nil;
    }
    
    CFStringRef ref = CFURLCreateStringByAddingPercentEscapes( NULL,
                                                              (CFStringRef)text,
                                                              NULL,
                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8 );
    
    NSString *encoded = [NSString stringWithString: (__bridge NSString *)ref];
    
    CFRelease( ref );
    
    return encoded;
}

#pragma mark - UIActivity Override Methods
#pragma mark -

- (NSString *)activityType {
    return [NSString stringWithFormat:@"UIActivityTypePostTo%@", [self activityTitle]];
}

- (NSString *)activityTitle {
    NSLog(@"override this");
    return nil;
}

- (UIImage *)activityImage {
    NSLog(@"override this");
    return nil;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    if (![self isClientInstalled]) {
        return NO;
    }
    
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSString class]] || [activityItem isKindOfClass:[NSURL class]]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    NSString *content = nil;
    NSString *link = nil;
    
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSString class]]) {
            NSString *text = activityItem;
            if ([text hasPrefix:@"http://"] || [text hasPrefix:@"https://"]) {
                link = text;
            }
            else {
                content = text;
            }
        }
        else if ([activityItem isKindOfClass:[NSURL class]]) {
            NSURL *url = activityItem;
            link = [url absoluteString];
        }
    }
    
    if (content != nil && link != nil) {
        self.text = [NSString stringWithFormat:@"%@ %@", content, link];
    }
    else if (content != nil && link == nil) {
        self.text = content;
    }
    else if (content == nil && link != nil) {
        self.text = link;
    }
    else {
        // a default just in case but should never be reached
        NSAssert(NO, @"This option should never be reached since canPerformWithActivityItems should return NO for this condition.");
        self.text = @"POST!";
    }
}

- (UIViewController *)activityViewController {
    return nil;
}

- (void)performActivity {
#ifndef NDEBUG
    NSLog(@"Sharing: %@", self.encodedText);
#endif

#if TARGET_IPHONE_SIMULATOR
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"ADNActivity"
                                                    message: @"Sharing does not function in the iPhone Simulator."
                                                   delegate: nil
                                          cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                          otherButtonTitles: nil];
    
    [alert show];
    [self activityDidFinish:YES];
#else
    [self activityDidFinish:YES];
    [[UIApplication sharedApplication] openURL:self.clientOpenURL];
#endif
}

@end
