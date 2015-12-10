//
//  AWAREPcApp.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcApp.h"

@implementation AWAREPcApp{
    NSTimer *sensingTimer;
    NSTimer *syncTimer;
    /** Previous application name */
    NSString *pastActiveApp;
}

- (instancetype)initWithSensorName:(NSString *)sensorName awareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName awareStudy:study];
    if (self) {
        [super setSensorName:sensorName];
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
    return self;
}


-(BOOL)startSensor:(double)syncInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Application Sensing on Mac OSX !");
    
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:syncInterval
                                             target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    [self startWriteAbleTimer];
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
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:currentActiveApp forKey:@"application"];
        [dic setObject:@"mac app" forKey:@"label"];
        [self setLatestValue:[NSString stringWithFormat:
                            @"[%@] %@",
                            [NSDate new],
                            currentActiveApp]];
        [self saveData:dic];
        NSLog(@"%@", currentActiveApp );
        pastActiveApp = currentActiveApp;
    }
}


-(BOOL) stopSensor{
    [syncTimer invalidate];
    [sensingTimer invalidate];
    [self stopWriteableTimer];
    return YES;
}


@end
