
//
//  AWAREPcState.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcState.h"
#import "EntityPcUsage.h"
#import "AWAREUtils.h"

@implementation AWAREPcState{
    NSTimer *sensingTimer;
    NSTimer *mouseLocationTimer;
    bool userActiveState;
    double changeStateInterval;
    double lastUpdateTime;
    NSPoint pastMouseLocation;
}

- (instancetype)initWithSensorName:(NSString *)name
                        entityName:(NSString *)entity
                        awareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:name entityName:NSStringFromClass([EntityPcUsage class]) awareStudy:study];
    if (self) {
        [super setSensorName:name];
        pastMouseLocation = [NSEvent mouseLocation];
        changeStateInterval = 5.0f;
        lastUpdateTime = [self getCurrentUnixtime];
    }
    return self;
}


- (void)createTable {
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "state int default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}



-(BOOL)startSensorWithSettings:(NSArray *)settings {
    NSLog(@"Start PC status Sensing on Mac OSX !");
    
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:changeStateInterval
                                     target:self
                                   selector:@selector(checkUserState)
                                   userInfo:nil
                                    repeats:YES];
    mouseLocationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                    target:self
                                                  selector:@selector(checkMouseLocation)
                                                  userInfo:nil
                                                   repeats:YES];
    
    return YES;
}

- (void) checkUserState {
    double now = [self getCurrentUnixtime];
    double gap = now - lastUpdateTime;
    NSString *label = @"";
    if(gap > changeStateInterval){
        if(userActiveState != NO){
            userActiveState = NO;
            label = @"off";
            NSLog(@"off");
            [self saveState:userActiveState withLabel:label];
        }
    }else{
        if(userActiveState != YES){
            userActiveState = YES;
            label = @"on";
            NSLog(@"on");
            [self saveState:userActiveState withLabel:label];
        }
    }
}

/**
 * start monitoring the mouse and key action
 */
- (void) startMonitoring {
    monitorKeyDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *evt) {
        lastUpdateTime = [self getCurrentUnixtime];
    }];
    monitorLeftMouseDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^(NSEvent *evt) {
        lastUpdateTime = [self getCurrentUnixtime];
    }];
    monitorRightMouseDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSRightMouseDownMask handler:^(NSEvent *evt) {
        lastUpdateTime = [self getCurrentUnixtime];
    }];
}

- (void) checkMouseLocation
{
    NSPoint mouseLocation = [NSEvent mouseLocation];
    if (!NSEqualPoints(pastMouseLocation, mouseLocation)) {
        lastUpdateTime = [self getCurrentUnixtime];
        pastMouseLocation = mouseLocation;
    }
}

- (void) saveState:(bool)state withLabel:(NSString*)label{
//    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:[NSNumber numberWithBool:state] forKey:@"state"];
//    [dic setObject:label forKey:@"label"];
    
    AppDelegate *delegate=(AppDelegate*)[NSApplication sharedApplication].delegate;
    EntityPcUsage *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityPcUsage class])
                                                           inManagedObjectContext:delegate.managedObjectContext];
    entity.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
    entity.device_id = [self getDeviceId];
    entity.state = [NSNumber numberWithBool:state];
    entity.label = label;
    
    [self saveDataToDB];
    
//    NSError * error = nil;
//    [delegate.managedObjectContext save:&error];
//    if (error != nil) {
//        NSLog(@"Error: %@", error.debugDescription);
//    }

    
    [self setLatestValue:[NSString stringWithFormat:@"[%@] %@",[NSDate new], label]];
}


-(BOOL) stopSensor{
    [sensingTimer invalidate];
    [mouseLocationTimer invalidate];
    return YES;
}

@end
