
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

@implementation AWARESensorManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        awareSensors = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void) startAllSensorsWithSyncInterval:(double)interval{
    if(awareSensors.count > 0){
        [self stopAllSensors];
    }
    [self addNewSensor:SENSOR_PC_APP withSyncInterval:interval];
    [self addNewSensor:SENSOR_PC_STATE withSyncInterval:interval];
    [self addNewSensor:SENSOR_PC_MOUSE_CLICK withSyncInterval:interval];
    [self addNewSensor:SENSOR_PC_MOUSE_LOCATION withSyncInterval:interval];
    [self addNewSensor:SENSOR_PC_KEYBOARD withSyncInterval:interval];
}

-(bool)addNewSensor:(NSString *)sensorName withSyncInterval:(double)interval{
    AWARESensor * sensor = nil;
    if([sensorName isEqualToString:SENSOR_PC_APP]){
        sensor = [[AWAREPcApp alloc] initWithSensorName:SENSOR_PC_APP];
        [sensor startSensor:interval withSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_STATE]){
        sensor = [[AWAREPcState alloc] initWithSensorName:SENSOR_PC_STATE];
        [sensor startSensor:interval withSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_KEYBOARD]){
        sensor = [[AWAREPcKeyboard alloc] initWithSensorName:SENSOR_PC_KEYBOARD];
        [sensor startSensor:interval withSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_MOUSE_CLICK]){
        sensor = [[AWAREPcMouseClick alloc] initWithSensorName:SENSOR_PC_MOUSE_CLICK];
        [sensor startSensor:interval withSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_MOUSE_LOCATION]){
        sensor = [[AWAREPcMouseLocation alloc] initWithSensorName:SENSOR_PC_MOUSE_LOCATION];
        [sensor startSensor:interval withSettings:nil];
    }else if([sensorName isEqualToString:SENSOR_PC_KEYBOARD]){
        sensor = [[AWAREPcKeyboard alloc] initWithSensorName:SENSOR_PC_KEYBOARD];
        [sensor startSensor:interval withSettings:nil];
    }else{
        NSLog(@"Seletected sensor is not supported on this platform.");
    }
    
    if(sensor){
        [awareSensors addObject:sensor];
    }
//    NSLog(@"Count of sensors:%ld",awareSensors.count);
    return NO;
}


- (void)addNewSensor:(AWARESensor *)sensor{
    [awareSensors addObject:sensor];
}

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
        [sensor stopSensor];
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

@end