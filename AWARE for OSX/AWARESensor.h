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

@protocol AWARESensorDelegate <NSObject>
//- (BOOL) startSensor:(double) interval withUploadInterval:(double)upInterval;
- (BOOL) startSensor:(double)syncInterval  withSettings:(NSArray *)settings;
- (BOOL) stopSensor;
@end

@interface AWARESensor : NSObject <AWARESensorDelegate, NSURLConnectionDelegate>

- (instancetype) initWithSensorName:(NSString *) sensorName awareStudy:(AWAREStudy *) study;

- (void) setBufferLimit:(int) limit;

- (void) startWriteAbleTimer;

- (void) stopWriteableTimer;

-(void) setLatestValue:(NSString *) valueStr;

-(NSString *) getLatestValue;

-(NSString *) getDeviceId;

// get generate URL for insert
- (NSString *) getInsertUrl:(NSString *)sensorName;

// get latest sensor data URL
- (NSString *) getLatestDataUrl:(NSString *)sensorName;

// get create table URL
- (NSString *) getCreateTableUrl:(NSString*) sensorName;

// get clear table URL
- (NSString *) getClearTableUrl:(NSString*) sensorName;

//- (NSString *) saveData:(NSDictionary*)data toLocalFile:(NSString*)fileName;
//
//- (NSString *) getData:(NSString*)fileName withJsonArrayFormat:(bool)jsonArrayFormat;

// insert sensor data
//- (BOOL) insertSensorData:(NSString*)data withDeviceId:(NSString*)deviceId url:(NSString*)url;

- (bool) saveData:(NSDictionary *) data;

- (bool) saveData:(NSDictionary *) data toLocalFile:(NSString*) fileName;

- (void) syncAwareDB;

// get latest sensor data -> for debug
- (NSString *) getLatestSensorData:(NSString*)deviceId withUrl:(NSString*) url;

- (double) getSensorSetting:(NSArray *)settings withKey:(NSString *)key;

// create new table in the database
- (void) createTable:(NSString *)query;

// clear the table in the database
- (BOOL) clearTable;

- (void) setSensorName:(NSString *) sensorName;

- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency;

- (NSString *) getSensorName;

- (double) getCurrentUnixtime;

+ (SecCertificateRef)sslCertificate;

@end
