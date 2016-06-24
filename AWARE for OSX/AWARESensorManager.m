
//
//  AWARESensorManager.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensorManager.h"
#import "AWAREPcApp.h"
#import "AWAREPcMouseClick.h"
#import "AWAREPcMouseLocation.h"
#import "AWAREPcState.h"
#import "AWAREPcKeyboard.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"

@implementation AWARESensorManager {
    NSMutableArray* awareSensors;
    AWAREStudy* awareStudy;
    NSTimer *syncTimer;
}

- (instancetype)initWithAWAREStudy:(AWAREStudy *)study {
    self = [super init];
    if (self != nil) {
        awareSensors = [[NSMutableArray alloc] init];
        awareStudy = study;
    }
    return self;
}


- (void) startAllSensors{
    [self startAllSensorsWithStudy:awareStudy];
}


- (void)startAllSensorsWithStudy:(AWAREStudy *) study {
    awareStudy = study;
    if(awareSensors.count > 0){
        [self stopAllSensors];
    }
    [self addNewSensorWithName:SENSOR_PC_APP];
    [self addNewSensorWithName:SENSOR_PC_STATE];
    [self addNewSensorWithName:SENSOR_PC_MOUSE_CLICK];
    [self addNewSensorWithName:SENSOR_PC_MOUSE_LOCATION];
    [self addNewSensorWithName:SENSOR_PC_KEYBOARD];
}

-(void)addNewSensorWithName:(NSString *)sensorName{
    AWARESensor * sensor = nil;
    if([sensorName isEqualToString:SENSOR_PC_APP]){
        sensor = [[AWAREPcApp alloc] initWithSensorName:SENSOR_PC_APP entityName:nil awareStudy:awareStudy];
        [sensor startSensorWithSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_STATE]){
        sensor = [[AWAREPcState alloc] initWithSensorName:SENSOR_PC_STATE entityName:nil  awareStudy:awareStudy];
        [sensor startSensorWithSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_KEYBOARD]){
        sensor = [[AWAREPcKeyboard alloc] initWithSensorName:SENSOR_PC_KEYBOARD entityName:nil awareStudy:awareStudy];
        [sensor startSensorWithSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_MOUSE_CLICK]){
        sensor = [[AWAREPcMouseClick alloc] initWithSensorName:SENSOR_PC_MOUSE_CLICK entityName:nil awareStudy:awareStudy];
        [sensor startSensorWithSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_MOUSE_LOCATION]){
        sensor = [[AWAREPcMouseLocation alloc] initWithSensorName:SENSOR_PC_MOUSE_LOCATION entityName:nil awareStudy:awareStudy];
        [sensor startSensorWithSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_KEYBOARD]){
        sensor = [[AWAREPcKeyboard alloc] initWithSensorName:SENSOR_PC_KEYBOARD entityName:nil awareStudy:awareStudy];
        [sensor startSensorWithSettings:nil];
    }else{
        NSLog(@"Seletected sensor is not supported on this platform.");
    }
    
    if(sensor){
        [awareSensors addObject:sensor];
    }
}


- (void)addNewSensor:(AWARESensor *)sensor{
    [awareSensors addObject:sensor];
}


/**
 * stop sensors
 */
- (void)stopAllSensors{
    for (AWARESensor* sensor in awareSensors) {
        [sensor stopSensor];
    }
    awareSensors = [[NSMutableArray alloc] init];
}

- (void)stopASensor:(NSString *)sensorName{
    for (AWARESensor* sensor in awareSensors) {
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            [sensor stopSensor];
        }
    }
}


- (BOOL)createAllTables{
    for(AWARESensor * sensor in awareSensors){
        [sensor createTable];
    }
    return YES;
}


- (void)stopAndRemoveAllSensors{
    NSString * message = nil;
    @autoreleasepool {
        for (AWARESensor* sensor in awareSensors) {
            message = [NSString stringWithFormat:@"[%@] Stop %@ sensor",[sensor getSensorName], [sensor getSensorName]];
            NSLog(@"%@", message);
            [sensor stopSensor];
        }
        [awareSensors removeAllObjects];
    }
}


- (NSString*)getLatestSensorData:(NSString *)sensorName{
//    NSLog(@"%ld",awareSensors.count);
    for (AWARESensor* sensor in awareSensors) {
//        NSLog(@"%@ <---> %@", sensor.getSensorName, sensorName);
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            NSString *sensorValue = [sensor getLatestValue];
            if(sensorValue != nil){
                return sensorValue;
            }
        }
    }
    return @"";
}


- (bool)syncAllSensorsWithDBInBackground{
    for (AWARESensor* sensor in awareSensors) {
        [sensor syncAwareDBInBackground];
    }
    return NO;
}


- (bool)syncAllSensorsWithDBInForeground{
    for (AWARESensor* sensor in awareSensors) {
        [sensor syncAwareDBInForeground];
    }
    return NO;
}


- (void)startSyncTimer:(double)interval{
    if (syncTimer != nil) {
        [syncTimer invalidate];
        syncTimer = nil;
    }
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(syncAllSensorsWithDBInBackground)
                                               userInfo:nil
                                                repeats:YES];
}

- (void)stopSyncTimer{
    if (syncTimer != nil) {
        [syncTimer invalidate];
        syncTimer = nil;
    }
}

@end
