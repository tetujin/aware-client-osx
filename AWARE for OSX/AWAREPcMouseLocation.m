//
//  AWAREPcMouseLocation.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcMouseLocation.h"

@implementation AWAREPcMouseLocation{
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
        "x real default 0,"
        "y real default 0,"
        "UNIQUE (timestamp,device_id)";
        [super createTable:query];
    }
    return self;
}


-(BOOL)startSensor:(double)syncInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Mouse Location Sensing on Mac OSX !");
    
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:syncInterval
                                                 target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    [self startWriteAbleTimer];
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                 target:self
                                               selector:@selector(getMouseLocation)
                                               userInfo:nil
                                                repeats:YES];
    
    return YES;
}

- (NSPoint) getMouseLocation
{
    NSPoint mouseLocation = [NSEvent mouseLocation];
    if (!NSEqualPoints(pastMouseLocation, mouseLocation)) {
//        double now = [self getCurrentUnixtime];
//        NSLog(@"%d, %d", (int)mouseLocation.x, (int)mouseLocation.y);
//        [self saveLogToFile:[NSString stringWithFormat:@"%f,%d,%d \n", now, (int)mouseLocation.x, (int)mouseLocation.y]
//                 targetFile:mouseActionLogFile];
            lastUpdateTime = [self getCurrentUnixtime];
            NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
            NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            [dic setObject:unixtime forKey:@"timestamp"];
            [dic setObject:[self getDeviceId] forKey:@"device_id"];
            [dic setObject:[NSNumber numberWithFloat:mouseLocation.x] forKey:@"x"];
            [dic setObject:[NSNumber numberWithFloat:mouseLocation.y] forKey:@"y"];
            [self setLatestValue:[NSString stringWithFormat:
                                  @"%f, %f",
                                  mouseLocation.x,
                                  mouseLocation.y]];
            [self saveData:dic];
    }
    pastMouseLocation = mouseLocation;
    return mouseLocation;
}


-(BOOL) stopSensor{
    [syncTimer invalidate];
    [sensingTimer invalidate];
    [self stopWriteableTimer];
    return YES;
}

@end
