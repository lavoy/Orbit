//
//  ADNNetbotActivity.m
//  ADNActivityCollection
//
//  Created by Brennan Stehling on 3/2/13.
//  Copyright (c) 2013 SmallSharptools LLC. All rights reserved.
//

#import "ADNNetbotActivity.h"

// User docs for Tweetbot URL Scheme
// http://tapbots.com/blog/development/tweetbot-url-scheme
// netbot:///post?text=abc

@implementation ADNNetbotActivity

#pragma mark - Public Implementation
#pragma mark -

- (NSString *)clientURLScheme {
    return @"netbot://";
}

#pragma mark - UIActivity Override Methods
#pragma mark -

- (NSString *)activityTitle {
    return @"Netbot";
}

- (UIImage *)activityImage {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [UIImage imageNamed:@"activity-tapbots"];
    });
    return image;
}


- (NSURL *)clientOpenURL {
    if (self.clientURLScheme != nil) {
        // Note: Adding another slash fixes the sharing option with Netbot
        // https://alpha.app.net/edmundtay/post/3828992
        NSString *urlString = [NSString stringWithFormat:@"%@/post?text=%@", self.clientURLScheme, self.encodedText];
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

@end
