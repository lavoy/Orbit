//
//  ADNRiposteActivity.m
//  ADNActivityCollection
//
//  Created by Brennan Stehling on 3/14/13.
//  Copyright (c) 2013 SmallSharptools LLC. All rights reserved.
//

#import "ADNRiposteActivity.h"

// Riposte docs for URL Scheme
// http://riposteapp.net/release-notes.html
// riposte://x-callback-url/createNewPost?text=blahblahblah&accountID=5952

@implementation ADNRiposteActivity

#pragma mark - Public Implementation
#pragma mark -

- (NSString *)clientURLScheme {
    return @"riposte://";
}

#pragma mark - UIActivity Override Methods
#pragma mark -

- (NSString *)activityTitle {
    return @"Riposte";
}

- (UIImage *)activityImage {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [UIImage imageNamed:@"activity-riposte"];
    });
    return image;
}

- (NSURL *)clientOpenURL {
    if (self.clientURLScheme != nil) {
        // Note: Adding another slash fixes the sharing option with Netbot
        // https://alpha.app.net/edmundtay/post/3828992
        NSString *urlString = [NSString stringWithFormat:@"%@x-callback-url/createNewPost?text=%@", self.clientURLScheme, self.encodedText];
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
