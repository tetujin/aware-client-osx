//
//  AWARESensor.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCNetworkReachability.h"
#import "AWAREStudy.h"
#import "AWARECoreDataManager.h"

@protocol AWARESensorDelegate <NSObject>
- (BOOL) startSensorWithSettings:(NSArray *)settings;
- (BOOL) stopSensor;
- (void) createTable;
@end

@interface AWARESensor : AWARECoreDataManager <AWARESensorDelegate, NSURLConnectionDelegate, NSURLSessionDelegate>

- (instancetype) initWithSensorName:(NSString *)name
                         entityName:(NSString*)entity
                         awareStudy:(AWAREStudy *) study;

// Setter
- (void) setSensorName:(NSString *) sensorName;
- (void) setLatestValue:(NSString *) valueStr;

// Getter
- (NSString *) getLatestValue;
- (NSString *) getSensorName;
- (NSString *) getDeviceId;

//- (NSString *) getInsertUrl:(NSString *)sensorName;
//- (NSString *) getLatestDataUrl:(NSString *)sensorName;
//- (NSString *) getCreateTableUrl:(NSString*) sensorName;
//- (NSString *) getClearTableUrl:(NSString*) sensorName;

// Controllers
- (void) createTable:(NSString *)query;
- (void) syncAwareDB;

// Utils
- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency;
- (double) getCurrentUnixtime;
- (double) getSensorSetting:(NSArray *)settings withKey:(NSString *)key;
//- (NSString *) getLatestSensorData:(NSString*)deviceId withUrl:(NSString*) url;


@end
