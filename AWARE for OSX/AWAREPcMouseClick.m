//
//  AWAREPcMouse.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcMouseClick.h"

@implementation AWAREPcMouseClick{
    NSTimer *sensingTimer;
    NSTimer *syncTimer;
    NSPoint pastMouseLocation;
    double lastUpdateTime;
}

- (instancetype)initWithSensorName:(NSString *)sensorName awareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName awareStudy:study];
    if (self) {
        [super setSensorName:sensorName];
        pastMouseLocation = [NSEvent mouseLocation];
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
    return self;
}


-(BOOL)startSensor:(double)syncInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Application Sensing on Mac OSX !");
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:syncInterval
                                                 target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    [self startWriteAbleTimer];
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
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:buttonNumber forKey:@"button"];
    [dic setObject:buttonLabel forKey:@"label"];
    [self setLatestValue:[NSString stringWithFormat:
                          @"[%@] %@",
                          [NSDate new], buttonLabel]];
    [self saveData:dic];
}

-(BOOL) stopSensor{
    [syncTimer invalidate];
    [sensingTimer invalidate];
    [NSEvent removeMonitor:monitorLeftMouseDown];
    [NSEvent removeMonitor:monitorRightMouseDown];
    monitorLeftMouseDown = nil;
    monitorRightMouseDown = nil;
    [self stopWriteableTimer];
    return YES;
}

@end
