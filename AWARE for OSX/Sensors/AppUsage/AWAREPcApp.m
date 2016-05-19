//
//  AWAREPcApp.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcApp.h"
#import "AppUsageEntity.h"

@implementation AWAREPcApp{
    NSTimer *sensingTimer;
    NSString *pastActiveApp;
}

- (instancetype) initWithSensorName:(NSString *)name
                         entityName:(NSString*)entity
                         awareStudy:(AWAREStudy *) study{
    self = [super initWithSensorName:name entityName:NSStringFromClass([AppUsageEntity class]) awareStudy:study];
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

//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:currentActiveApp forKey:@"application"];
//        [dic setObject:@"mac app" forKey:@"label"];
//        [self saveData:dic];
        
        [self setLatestValue:[NSString stringWithFormat:
                            @"[%@] %@",
                            [NSDate new],
                            currentActiveApp]];

        NSLog(@"%@", currentActiveApp );
        pastActiveApp = currentActiveApp;

        NSString * name = NSStringFromClass([AppUsageEntity class]);
        AppDelegate *delegate=(AppDelegate*)[NSApplication sharedApplication].delegate;
        AppUsageEntity *appUsage = [NSEntityDescription insertNewObjectForEntityForName:name
                                                                 inManagedObjectContext:delegate.managedObjectContext];
  
        appUsage.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
        appUsage.device_id = [self getDeviceId];
        appUsage.application = currentActiveApp;
        appUsage.label = @"Mac App";
        
        NSError * error = nil;
        [delegate.managedObjectContext save:&error];
        if (error != nil) {
            NSLog(@"Error: %@", error.debugDescription);
        }
    }
}


-(BOOL) stopSensor{
    [sensingTimer invalidate];
    return YES;
}


@end
