//
//  AWARESensor.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"
#import "AWAREUtils.h"

@implementation AWARESensor {
    int bufferLimit;
    BOOL previusUploadingState;
    NSString * awareSensorName;
    NSString *latestSensorValue;
    int lineCount;
    SCNetworkReachability* reachability;
    NSMutableString *tempData;
    NSMutableString *bufferStr;
    bool wifiState;
    NSTimer* writeAbleTimer;
    int marker;
    AWAREStudy *awareStudy;
}


- (instancetype) initWithSensorName:(NSString *)name
                         entityName:(NSString*)entity
                         awareStudy:(AWAREStudy *) study{
    if (self = [super initWithAwareStudy:study sensorName:name dbEntityName:entity]) {
        NSLog(@"[%@] Initialize an AWARESensor as '%@' ", name, name);
        awareSensorName = name;
        bufferLimit = 0;
        marker = 0;
        previusUploadingState = NO;
        latestSensorValue = @"";
        awareStudy = study;
    }
    return self;
}


//////////////////////////////////////////
//////////////////////////////////////////
// delegates

- (void) createTable{
    
}


-(BOOL)startSensorWithSettings:(NSArray *)settings{
    return NO;
}

- (BOOL)stopSensor{
    return NO;
}

//////////////////////////////////////////
/////////////////////////////////////////
- (void) syncAwareDB {
    [super syncAwareDBInBackground];
}

//////////////////////////////////////////
//////////////////////////////////////////

- (void) setLatestValue:(NSString *) valueStr{
//    NSLog(@"latest value is %@.", valueStr);
    latestSensorValue = valueStr;
}


- (void) setSensorName:(NSString *)sensorName{
    awareSensorName = sensorName;
    // network check
    wifiState = NO;
}

- (NSString *)getSensorName{
    return awareSensorName;
}


- (NSString *)getLatestValue{
    return latestSensorValue;
}


- (NSString *)getDeviceId{
    //    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //    NSString* deviceId = [userDefaults objectForKey:KEY_MQTT_USERNAME];
    NSString *deviceId = [awareStudy getMqttUserName];
    if (deviceId == NULL || [deviceId isEqualToString:@""]) {
        NSLog(@"[Error] You did not have a StudyID. Please check your study configuration.");
        return @"";
    }
    return deviceId;
}


///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
// Utils

- (double)getSensorSetting:(NSArray *)settings withKey:(NSString *)key{
    if (settings != nil) {
        for (NSDictionary * setting in settings) {
            if ([[setting objectForKey:@"setting"] isEqualToString:key]) {
                double value = [[setting objectForKey:@"value"] doubleValue];
                return value;
            }
        }
    }
    return -1;
}


- (void) createTable:(NSString *)query{
    
    NSLog(@"%@",[AWAREUtils getCreateTableUrl:[self getSensorName] awareStudy:awareStudy]);
    
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    post = [NSString stringWithFormat:@"device_id=%@&fields=%@", [self getDeviceId], query];
    //            NSLog(@"%@", post);
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[AWAREUtils getCreateTableUrl:[self getSensorName] awareStudy:awareStudy]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    //        sessionConfig.allowsCellularAccess = NO;
    //        [sessionConfig setHTTPAdditionalHeaders:
    //         @{@"Accept": @"application/json"}];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.timeoutIntervalForResource = 300.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 30;
    
    session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData * _Nullable data,
                                    NSURLResponse * _Nullable response,
                                    NSError * _Nullable error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    int responseCode = (int)[httpResponse statusCode];
                    
                    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"[%@] Response----> %d, %@", [self getSensorName],responseCode, newStr);
                    
                    if(responseCode == 200){
                        //                        [self removeFile:[self getSensorName]];
                        //                        //                            [self createNewFile:[self getSensorName]];
                        NSString *message = [NSString stringWithFormat:@"[%@] Sucess to create new table on AWARE server.", [self getSensorName]];
                        NSLog(@"%@", message);
                        //                        [self sendLocalNotificationForMessage:message soundFlag:NO];
                    }
                    //                    previusUploadingState = NO;
                    data = nil;
                    response = nil;
                    error = nil;
                    httpResponse = nil;
                    //                    dispatch_async(dispatch_get_main_queue(), ^{
                    //                        [session finishTasksAndInvalidate];
                    //                        [session invalidateAndCancel];
                    //                    });
                }] resume];
}



- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency{
    //        Android: Non-deterministic frequency in microseconds (dependent of the hardware sensor capabilities and resources), e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest).
    //         iOS: https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html
    //          e.g 10-20Hz, 30-60Hz, 70-100Hz
    double y1 = 0.01; //iOS 1 max
    double y2 = 0.1; //iOS 2 min
    double x1 = 0; //Android 1 max
    double x2 = 200000; // Android 2 min
    
    // y1 = a * x1 + b;
    // y2 = a * x2 + b;
    double a = (y1-y2)/(x1-x2);
    double b = y1 - x1*a;
    //    y =a * x + b;
    //    NSLog(@"%f", a *frequency + b);
    return a *frequency + b;
}

/**
 * Get current time (unixtime)
 */
- (double) getCurrentUnixtime
{
    NSDate *now = [[NSDate alloc] init];
    return [now timeIntervalSince1970];
}



///////////////////////////////////////////
//////////////////////////////////////////
// SSL
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    
}

@end
