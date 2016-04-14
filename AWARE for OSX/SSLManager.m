//
//  SSLManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "SSLManager.h"
#import <AppKit/AppKit.h>

@implementation SSLManager

- (bool)installCRTWithTextOfQRCode:(NSString *)text {
    NSLog(@"%@", text);
    // https://api.awareframework.com/index.php/webservice/index/502/Fuvl8P6Atay0
    
    NSArray *elements = [text componentsSeparatedByString:@"/"];
    if (elements.count > 2) {
        if ([[elements objectAtIndex:0] isEqualToString:@"https:"] || [[elements objectAtIndex:0] isEqualToString:@"http:"]) {
            [self installCRTWithAwareHostURL:[elements objectAtIndex:2]];
        }
    }
    return NO;
}

- (bool)installCRTWithAwareHostURL:(NSString *)urlStr {
    if ([urlStr isEqualToString:@"api.awareframework.com"]) {
        urlStr = @"awareframework.com";
    }
    NSString * awareCrtUrl = [NSString stringWithFormat:@"http://%@/public/server.crt", urlStr];
    
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentDir stringByAppendingPathComponent:@"server.crt"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:awareCrtUrl]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Download Error:%@",error.description);
        }
        if (data) {
            [data writeToFile:filePath atomically:YES];
            NSLog(@"File is saved to %@",filePath);
        }
    }];
    
//    NSURL *url = [NSURL URLWithString:awareCrtUrl];
//    if( ![[NSWorkspace sharedWorkspace] openURL:url] )
//        NSLog(@"Failed to open url: %@",[url description]);
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:awareCrtUrl]];
    return NO;
}

@end
