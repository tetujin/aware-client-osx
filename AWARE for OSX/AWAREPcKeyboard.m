
//
//  AWAREPcKeyboard.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcKeyboard.h"

@implementation AWAREPcKeyboard{
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
        "key_down text default '',"
        "key_code text default '',"
        "UNIQUE (timestamp,device_id)";
        [super createTable:query];
    }
    return self;
}


-(BOOL)startSensor:(double)syncInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Keyboard Sensing on Mac OSX !");
    
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:syncInterval
                                                 target:self
                                               selector:@selector(syncAwareDB)
                                               userInfo:nil
                                                repeats:YES];
    [self startWriteAbleTimer];
    [self startMonitoring];
    return YES;
}

/**
 * start monitoring the mouse and key action
 */
- (void) startMonitoring {
        monitorKeyDown = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *evt) {
            lastUpdateTime = [self getCurrentUnixtime];
            NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
            NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            [dic setObject:unixtime forKey:@"timestamp"];
            [dic setObject:[self getDeviceId] forKey:@"device_id"];
            [dic setObject:[evt characters] forKey:@"key_down"];
            [dic setObject:[NSString stringWithFormat:@"%d",[evt keyCode]] forKey:@"key_code"];
            [self saveData:dic];
            
            NSString * latestData = [NSString stringWithFormat:@"Key down: %@ (key code %d)", [evt characters], [evt keyCode]];
            [self setLatestValue:latestData];
        }];
}



-(BOOL) stopSensor{
    [syncTimer invalidate];
    [NSEvent removeMonitor:monitorKeyDown];
    monitorKeyDown = nil;
    [self stopWriteableTimer];
    return YES;
}

@end
