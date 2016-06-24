//
//  AWAREPcMouseLocation.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPcMouseLocation.h"
#import "EntityMouseLocation.h"
#import "AWAREUtils.h"

@implementation AWAREPcMouseLocation{
    NSTimer *sensingTimer;
    NSPoint pastMouseLocation;
    double lastUpdateTime;
//    int bufferSize;
//    int currentBufferCount;
}

- (instancetype)initWithSensorName:(NSString *)name
                        entityName:(NSString *)entity
                        awareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:name
                          entityName:NSStringFromClass([EntityMouseLocation class])
                          awareStudy:study];
    if (self) {
        [super setSensorName:name];
        pastMouseLocation = [NSEvent mouseLocation];
//        bufferSize = 100;
//        currentBufferCount = 0;
    }
    return self;
}


- (void)createTable{
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


-(BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start Mouse Location Sensing on Mac OSX !");
    
    [self setFetchLimit:300];
    [self setBufferSize:100];
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
        lastUpdateTime = [self getCurrentUnixtime];
//        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        NSNumber* unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]]; //[NSNumber numberWithDouble:timeStamp];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithFloat:mouseLocation.x] forKey:@"x"];
//        [dic setObject:[NSNumber numberWithFloat:mouseLocation.y] forKey:@"y"];
//        [self saveData:dic];

        [self setLatestValue:[NSString stringWithFormat:
                              @"%f, %f",
                              mouseLocation.x,
                              mouseLocation.y]];
        
        AppDelegate *delegate=(AppDelegate*)[NSApplication sharedApplication].delegate;
        EntityMouseLocation *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityMouseLocation class])
                                                                 inManagedObjectContext:delegate.managedObjectContext];
        entity.timestamp = unixtime;
        entity.device_id = [self getDeviceId];
        entity.x = [NSNumber numberWithFloat:mouseLocation.x];
        entity.y = [NSNumber numberWithFloat:mouseLocation.y];
        
        [self saveDataToDB];
//        if(currentBufferCount > bufferSize){
//            NSError * error = nil;
//            [delegate.managedObjectContext save:&error];
//            if (error != nil) {
//                NSLog(@"Error: %@", error.debugDescription);
//            }
//            currentBufferCount = 0;
//        }
//        currentBufferCount ++;
    }
    pastMouseLocation = mouseLocation;
    return mouseLocation;
}


-(BOOL) stopSensor{
    [sensingTimer invalidate];
    return YES;
}

@end
