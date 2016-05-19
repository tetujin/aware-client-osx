//
//  AWARESensorManager.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWAREStudy.h"

@interface AWARESensorManager : NSObject

/** Initializer */
- (instancetype)initWithAWAREStudy:(AWAREStudy *) study;

- (void) stopASensor:(NSString *) sensorName;
//- (void) addNewSensor:(AWARESensor *) sensor;
//- (bool) addNewSensor:(NSString *)sensorName withSyncInterval:(double)interval awareStudy:(AWAREStudy *)study;
- (NSString*)getLatestSensorData:(NSString *)sensorName;

- (bool) syncAllSensorsWithDBInForeground;
- (bool) syncAllSensorsWithDBInBackground;

- (void) stopAndRemoveAllSensors;
- (void) startAllSensorsWithStudy:(AWAREStudy *) study;
- (void) startAllSensors;
- (BOOL) createAllTables;

- (void) startSyncTimer:(double)interval;
- (void) stopSyncTimer;

@end