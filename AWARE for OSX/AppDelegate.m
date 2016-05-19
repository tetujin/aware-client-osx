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
        
        [self createDirectory];
        
        [self enableLoginItem];
        /**
         * initialization
         */
        userActiveState = true;
        uuidKey = @"uuid";
        userNameKey = @"username";
        changeStateInterval = 5.0f;
        sendActionLogInterval = 1.0f * 10.0f;
        serverURL = @"http://www.hoge.com";
        pastActiveApp = @"";
        pastMouseLocation = [NSEvent mouseLocation];
        
        // Add sensors to the SensorManager
        
        study = [[AWAREStudy alloc] init];
        _sharedSensorManager = [[AWARESensorManager alloc] initWithAWAREStudy:study];
        double syncInterval = 60.0f;
        if ([study isAvailable]) {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString *syncInt = [userDefaults objectForKey:SETTING_SYNC_INT];
            if (syncInt != nil) {
                syncInterval = [syncInt doubleValue] * 60.0f;
            }
            [_sharedSensorManager startAllSensors];
            [_sharedSensorManager startSyncTimer:syncInterval];
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
    NSLog(@"%@", [_sharedSensorManager getLatestSensorData:SENSOR_PC_MOUSE_LOCATION]);
    if(!window){
        window = [[PreferencesWindow alloc] initWithSensorManager:_sharedSensorManager awareStudy:study];
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



@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void) createDirectory {
    // Insert code here to initialize your application
    // 初回起動用にDataStore用のDirectoryを作成する
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    if(![[NSFileManager defaultManager] createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error]){
        NSLog(@"Couldn't create the data store directory.[%@, %@]", error, [error userInfo]);
        abort();
    }
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named hoge" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"CoreData"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AWARE" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"AWARE.sqlite"];
    NSLog(@"%@", [url absoluteString]);
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSDictionary *options = @{NSInferMappingModelAutomaticallyOption:@YES,
                              NSMigratePersistentStoresAutomaticallyOption:@YES};
    
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    _persistentStoreCoordinator = coordinator;
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }
    return NSTerminateNow;
}


@end
