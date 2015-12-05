//
//  AppDelegate.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/4/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Cocoa/Cocoa.h>



static id monitorLeftMouseDown;
static id monitorRightMouseDown;
static id monitorKeyDown;


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSMenu *statusMenu;
@property (readwrite) BOOL loggingEnabled;

- (IBAction)pushedSettingButton:(id)sender;

@end

