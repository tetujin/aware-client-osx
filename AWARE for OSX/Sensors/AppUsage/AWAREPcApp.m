//
//  AWAREPcApp.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcApp.h"
#import "AWAREUtils.h"
#import "EntityAppUsage.h"

@implementation AWAREPcApp{
    NSTimer *sensingTimer;
    NSString *pastActiveApp;
}

- (instancetype) initWithSensorName:(NSString *)name
                         entityName:(NSString*)entity
                         awareStudy:(AWAREStudy *) study{
    self = [super initWithSensorName:name
                          entityName:NSStringFromClass([EntityAppUsage class])
                          awareStudy:study];
    if (self) {
        [super setSensorName:name];
    }
    return self;
}


-(void)createTable{
    NSString *query = [[NSString alloc] init];
    query =
    @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "application text default '',"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

-(BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start Application Sensing on Mac OSX !");
    
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                    target:self
                                                  selector:@selector(checkActiveApplication)
                                                  userInfo:nil
                                                   repeats:YES];
    return YES;
}


- (void) checkActiveApplication {
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSString *currentActiveApp = [[ws activeApplication] objectForKey:@"NSApplicationName"];
    if (![currentActiveApp isEqualToString:pastActiveApp]) {
        [self setLatestValue:[NSString stringWithFormat:
                            @"[%@] %@",
                            [NSDate new],
                            currentActiveApp]];

        NSLog(@"%@", currentActiveApp );
        pastActiveApp = currentActiveApp;

        AppDelegate *delegate=(AppDelegate*)[NSApplication sharedApplication].delegate;
        EntityAppUsage *appUsage = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([EntityAppUsage class])
                                                                 inManagedObjectContext:delegate.managedObjectContext];
        appUsage.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
        appUsage.device_id = [self getDeviceId];
        appUsage.application = currentActiveApp;
        appUsage.label = @"Mac App";
        
        // [delegate.managedObjectContext save:nil];
        
        [self saveDataToDB];
    }
}


-(BOOL) stopSensor{
    [sensingTimer invalidate];
    return YES;
}


@end
