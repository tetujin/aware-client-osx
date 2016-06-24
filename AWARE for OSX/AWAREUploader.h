//
//  AWAREUploader.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWAREStudy.h"

@protocol AWAREDataUploaderDelegate <NSObject>

- (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString*)name;

- (bool) isUploading;
- (void) setUploadingState:(bool)state;
- (void) lockBackgroundUpload;
- (void) unlockBackgroundUpload;



- (void) allowsCellularAccess;
- (void) forbidCellularAccess;
- (void) allowsDateUploadWithoutBatteryCharging;
- (void) forbidDatauploadWithoutBatteryCharging;


- (bool) isDebug;
- (bool) isSyncWithOnlyWifi;
- (bool) isSyncWithOnlyBatteryCharging;


// CoreData
- (void) setBufferSize:(int)size;
- (void) setFetchLimit:(int)limit;
- (void) setFetchBatchSize:(int)size;
- (int) getBufferSize;
- (int)  getFetchLimit;
- (int)  getFetchBatchSize;
- (bool) saveDataToDB;//TODO

- (void) syncAwareDBInBackground;
- (void) syncAwareDBInBackgroundWithSensorName:(NSString*) name;
- (void) postSensorDataWithSensorName:(NSString*) name session:(NSURLSession *)oursession;
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary;


- (BOOL) syncAwareDBInForeground;
- (BOOL) syncAwareDBInForegroundWithSensorName:(NSString*) name;


- (void) createTable:(NSString*) query;
- (void) createTable:(NSString *)query withTableName:(NSString*) tableName;
- (BOOL) clearTable;

//- (NSString *) getNetworkReachabilityAsText;
- (NSString *) getSyncProgressAsText;
- (NSString *) getSyncProgressAsText:(NSString *)sensorName;

//- (bool)saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label;


- (NSString *) getWebserviceUrl;
- (NSString *) getInsertUrl:(NSString *)sensorName;
- (NSString *) getLatestDataUrl:(NSString *)sensorName;
- (NSString *) getCreateTableUrl:(NSString *)sensorName;
- (NSString *) getClearTableUrl:(NSString *)sensorName;


@end

@interface AWAREUploader : NSData <AWAREDataUploaderDelegate>



@end
