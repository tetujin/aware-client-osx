
//
//  AWAREPcKeyboard.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcKeyboard.h"
#import "EntityKeyboard.h"
#import "AWAREUtils.h"

@implementation AWAREPcKeyboard{
    NSTimer *sensingTimer;
    NSPoint pastMouseLocation;
//    double lastUpdateTime;
}

- (instancetype)initWithSensorName:(NSString *)name
                        entityName:(NSString *)entity
                        awareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:name entityName:NSStringFromClass([EntityKeyboard class])  awareStudy:study];
    if (self) {
        [super setSensorName:name];
        pastMouseLocation = [NSEvent mouseLocation];
    }
    return self;
}


- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query =
    @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "key_down text default '',"
    "key_code text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


-(BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start Keyboard Sensing on Mac OSX !");
    
    [self startMonitoring];
    return YES;
}

/**
 * start monitoring the mouse and key action
 */
- (void) startMonitoring {
        monitorKeyDown = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSKeyDownMask) handler:^(NSEvent *evt) {
//            lastUpdateTime = [self getCurrentUnixtime];
//            NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//            NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//            [dic setObject:unixtime forKey:@"timestamp"];
//            [dic setObject:[self getDeviceId] forKey:@"device_id"];
//            [dic setObject:[evt characters] forKey:@"key_down"];
//            [dic setObject:[NSString stringWithFormat:@"%d",[evt keyCode]] forKey:@"key_code"];
//            [self saveData:dic];
            
            NSString * latestData = [NSString stringWithFormat:@"Key down: %@ (key code %d)", [evt characters], [evt keyCode]];
            [self setLatestValue:latestData];
            
            AppDelegate *delegate=(AppDelegate*)[NSApplication sharedApplication].delegate;
            EntityKeyboard *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityKeyboard class])
                                                                        inManagedObjectContext:delegate.managedObjectContext];
            entity.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
            entity.device_id = [self getDeviceId];
            NSString * keyCode = [NSString stringWithFormat:@"%d",[evt keyCode]];
            if(keyCode != nil){
                entity.key_code  = keyCode;
            }else{
                entity.key_code = @"";
            }
            
            NSString * keyDown = [evt characters];
            if(keyDown != nil){
                entity.key_down = keyDown;
            }else{
                entity.key_down = @"";
            }
            
            [self saveDataToDB];
//            NSError * error = nil;
//            [delegate.managedObjectContext save:&error];
//            if (error != nil) {
//                NSLog(@"Error: %@", error.debugDescription);
//            }
            
        }];
}



-(BOOL) stopSensor{
    [NSEvent removeMonitor:monitorKeyDown];
    monitorKeyDown = nil;
    return YES;
}

@end
