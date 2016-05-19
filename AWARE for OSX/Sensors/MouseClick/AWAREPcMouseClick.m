//
//  AWAREPcMouse.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcMouseClick.h"
#import "MouseClickEntity.h"

@implementation AWAREPcMouseClick{
    NSTimer *sensingTimer;
    NSPoint pastMouseLocation;
    double lastUpdateTime;
}

- (instancetype)initWithSensorName:(NSString *)name
                        entityName:(NSString *)entity
                        awareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:name entityName:NSStringFromClass([MouseClickEntity class]) awareStudy:study];
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
    "button int default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

-(BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start Application Sensing on Mac OSX !");
   [self startMonitoring];
    return YES;
}


/**
 * start monitoring the mouse and key action
 */
- (void) startMonitoring {
    monitorLeftMouseDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^(NSEvent *evt) {
        [self saveMouseClickEventWithButtonNumber:@0];
    }];
    monitorRightMouseDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSRightMouseDownMask handler:^(NSEvent *evt) {
        [self saveMouseClickEventWithButtonNumber:@1];
    }];
}

- (void) saveMouseClickEventWithButtonNumber:(NSNumber *) buttonNumber {
    NSString *buttonLabel = @"";
    if([buttonNumber isEqual:@0]){
        buttonLabel = @"left";
    }else if([buttonNumber isEqual:@1]){
        buttonLabel = @"right";
    }else{
        buttonLabel = @"unkown";
    }
    
    lastUpdateTime = [self getCurrentUnixtime];
//    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//    NSNumber* unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];  //[NSNumber numberWithDouble:timeStamp];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:buttonNumber forKey:@"button"];
//    [dic setObject:buttonLabel forKey:@"label"];
    

    AppDelegate *delegate=(AppDelegate*)[NSApplication sharedApplication].delegate;
    MouseClickEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([MouseClickEntity class])
                                                             inManagedObjectContext:delegate.managedObjectContext];
    
    entity.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
    entity.device_id = [self getDeviceId];
    entity.button = buttonNumber;
    entity.label = buttonLabel;
    
    NSError * error = nil;
    [delegate.managedObjectContext save:&error];
    if (error != nil) {
        NSLog(@"Error: %@", error.debugDescription);
    }
    
    
    [self setLatestValue:[NSString stringWithFormat:
                          @"[%@] %@",
                          [NSDate new], buttonLabel]];
}

-(BOOL) stopSensor{
    [sensingTimer invalidate];
    [NSEvent removeMonitor:monitorLeftMouseDown];
    [NSEvent removeMonitor:monitorRightMouseDown];
    monitorLeftMouseDown = nil;
    monitorRightMouseDown = nil;
    return YES;
}

@end
