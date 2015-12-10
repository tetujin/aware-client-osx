//
//  AWARESensorManager.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWARESensor.h"

@interface AWARESensorManager : NSObject{
    NSMutableArray* awareSensors;
}

- (void) startAllSensorsWithSyncInterval:(double) interval awareStudy:(AWAREStudy *)study;
- (void) stopAllSensors;
- (void) stopASensor:(NSString *) sensorName;
- (void) addNewSensor:(AWARESensor *) sensor;
- (bool)addNewSensor:(NSString *)sensorName withSyncInterval:(double)interval awareStudy:(AWAREStudy *)study;
//- (bool) addNewSensorWithSensorName:(NSString *)sensorName
//                           settings:(NSArray*)settings
//                            plugins:(NSArray*)plugins
//                     uploadInterval:(double) uploadTime;
- (NSString*)getLatestSensorData:(NSString *)sensorName;

@end