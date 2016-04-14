//
//  AppDelegate.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/4/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AppDelegate.h"
#import "PreferencesWindow.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"

@interface AppDelegate ()

@end

@implementation AppDelegate{
    NSStatusItem *_statusItem;
    PreferencesWindow *window;
//    NSStatusItem *statusItem;
//    NSWindowController *windowController;
//    SettingWindow *window;
    
    /** File name of PC's ON/OFF state history */
    NSString *logFile;
    
    /** File name of current active application's history */
    NSString *activeAppLogFile;
    
    /** File name of keybord action history */
    NSString *keybordActionLogFile;
    
    /** File name of mouse action history */
    NSString *mouseActionLogFile;
    
    /** Server URL for uploading each hitory */
    NSString *serverURL;
    
    /** Local storage key (UUID) */
    NSString *uuidKey;
    
    /** Local storage key (User Name) */
    NSString *userNameKey;
    
    /** Previous application name */
    NSString *pastActiveApp;
    
    /** Previous mouse location */
    NSPoint pastMouseLocation;
    
    /** Interval (sec.) of PC's state (Active or Unactive) */
    double changeStateInterval;
    
    /** Interval (sec.) for uploading each history */
    double sendActionLogInterval;
    
    /** Latest active timestamp（unixtime） */
    double lastUpdateTime;
    
    /** current PC's statement（boolean） */
    bool userActiveState;

    AWAREStudy *study;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self enableLoginItem];
        /**
         * initialization
         */
        userActiveState = true;
//        lastUpdateTime = [self getCurrentUnixtime];
        uuidKey = @"uuid";
        userNameKey = @"username";
        changeStateInterval = 5.0f;
        sendActionLogInterval = 1.0f * 10.0f;
        logFile = @"mal-pcstate.csv";
        activeAppLogFile = @"mal-app.csv";
        keybordActionLogFile = @"mal-key.csv";
        mouseActionLogFile = @"mal-mouse.csv";
        //    mouseActionLogFile = @"mal-mouse-location.csv";
        serverURL = @"http://www.hoge.com";
        pastActiveApp = @"";
        pastMouseLocation = [NSEvent mouseLocation];
        
        // Add sensors to the SensorManager
        _sensorManager = [[AWARESensorManager alloc] init];
        double syncInterval = 60.0f;
        study = [[AWAREStudy alloc] init];
        if ([study isAvailable]) {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString *syncInt = [userDefaults objectForKey:SETTING_SYNC_INT];
            if (syncInt != nil) {
                syncInterval = [syncInt doubleValue] * 60.0f;
            }
            [_sensorManager startAllSensorsWithSyncInterval:syncInterval awareStudy:study];
        } else {
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"Please join a AWARE study";
            alert.informativeText = [NSString stringWithFormat:@"Do you open a preference window?"];
            [alert addButtonWithTitle:@"YES"];
            [alert addButtonWithTitle:@"NO"];
            if ([alert runModal] == NSAlertFirstButtonReturn) {
                [self pushedSettingButton:nil];
            }
        }
    }
    return self;
}


- (void)setupStatusItem
{
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
    _statusItem = [systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setHighlightMode:YES];
//    [_statusItem setTitle:@"StatusBarApp"];
    [_statusItem setImage:[NSImage imageNamed:@"aware_icon"]];
    [_statusItem setMenu:_statusMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self setupStatusItem];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)pushedSettingButton:(id)sender {
    NSLog(@"%@", [_sensorManager getLatestSensorData:SENSOR_PC_MOUSE_LOCATION]);
    if(!window){
        window = [[PreferencesWindow alloc] initWithSensorManager:_sensorManager awareStudy:study];
        [window showWindow:self];
    }else{
        [window showWindow:self];
    }
}

/**
 * Auto Login
 */
- (void)enableLoginItem{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath: [[NSBundle mainBundle] bundlePath]];
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
    if (item) {
        CFRelease(item);
    }
    CFRelease(loginItems);
}




@end
