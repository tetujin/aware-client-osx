//
//  AppDelegate.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/4/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AWARESensorManager.h"




@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSMenu *statusMenu;
@property (readwrite) BOOL loggingEnabled;
@property (strong) AWARESensorManager *sensorManager;

- (IBAction)pushedSettingButton:(id)sender;

@end

