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
    bool writeAble;
    int marker;
    AWAREStudy *awareStudy;
}


- (instancetype) initWithSensorName:(NSString *)sensorName awareStudy:(AWAREStudy *) study{
    if (self = [super init]) {
        NSLog(@"[%@] Initialize an AWARESensor as '%@' ", sensorName, sensorName);
        awareSensorName = sensorName;
        bufferLimit = 0;
        marker = 0;
        previusUploadingState = NO;
        //        fileClearState = NO;
        awareSensorName = sensorName;
        latestSensorValue = @"";
        awareStudy = study;
        tempData = [[NSMutableString alloc] init];
        bufferStr = [[NSMutableString alloc] init];
        reachability = [[SCNetworkReachability alloc] initWithHost:@"www.google.com"];
        [reachability observeReachability:^(SCNetworkStatus status) {
             switch (status) {
                 case SCNetworkStatusReachable:
                     NSLog(@"[%@] Reachable via WiFi", [self getSensorName]);
                     wifiState = YES;
                     break;
                default:
                     NSLog(@"[%@] No Reachable", [self getSensorName]);
                     wifiState = NO;
                     break;
             }
         }];
        
        // Make new file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",sensorName]];
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        if (!fh) { // no
            NSLog(@"You don't have a file for %@, then system recreated new file!", sensorName);
            NSFileManager *manager = [NSFileManager defaultManager];
            if (![manager fileExistsAtPath:path]) { // yes
                BOOL result = [manager createFileAtPath:path
                                               contents:[NSData data] attributes:nil];
                if (!result) {
                    NSLog(@"[%@] Error to create the file", sensorName);
                } else {
                    NSLog(@"[%@] Sucess to create the file", sensorName);
                }
            }
        }
        writeAble = YES;
    }
    return self;
}

- (void) setWriteableYES{
    writeAble = YES;
}

- (void) setWriteableNO{
    writeAble = NO;
}

- (void) startWriteAbleTimer{
    writeAbleTimer =  [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                       target:self
                                                     selector:@selector(setWriteableYES)
                                                     userInfo:nil repeats:YES];
    [writeAbleTimer fire];
}

- (void) stopWriteableTimer{
    if (!writeAbleTimer) {
        [writeAbleTimer invalidate];
    }
}

- (void) setBufferLimit:(int)limit{
    bufferLimit = limit;
}

- (void) setLatestValue:(NSString *) valueStr{
//    NSLog(@"latest value is %@.", valueStr);
    latestSensorValue = valueStr;
}

- (NSString *)getLatestValue{
    return latestSensorValue;
}

- (void) setSensorName:(NSString *)sensorName{
    awareSensorName = sensorName;
    // network check
    wifiState = NO;
}

- (NSString *)getSensorName{
    return awareSensorName;
}

-(BOOL)startSensor:(double)syncInterval withSettings:(NSArray *)settings{
    return NO;
}

- (BOOL)stopSensor{
    [writeAbleTimer invalidate];
    return NO;
}


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


- (NSString *)getInsertUrl:(NSString *)sensorName{
    //    - insert: insert new data to the table
    return [NSString stringWithFormat:@"%@/%@/insert", [self getWebserviceUrl], sensorName];
}


- (NSString *)getLatestDataUrl:(NSString *)sensorName{
    //    - latest: returns the latest timestamp on the server, for synching what’s new on the phone
    return [NSString stringWithFormat:@"%@/%@/latest", [self getWebserviceUrl], sensorName];
}


- (NSString *)getCreateTableUrl:(NSString *)sensorName{
    //    - create_table: creates a table if it doesn’t exist already
    return [NSString stringWithFormat:@"%@/%@/create_table", [self getWebserviceUrl], sensorName];
}


- (NSString *)getClearTableUrl:(NSString *)sensorName{
    //    - clear_table: remove a specific device ID data from the database table
    return [NSString stringWithFormat:@"%@/%@/clear_table", [self getWebserviceUrl], sensorName];
}


- (NSString *)getWebserviceUrl{
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    NSString* url = [userDefaults objectForKey:KEY_WEBSERVICE_SERVER];
    NSString *url = [awareStudy getWebserviceServer];
    if (url == NULL || [url isEqualToString:@""]) {
        NSLog(@"[Error] You did not have a StudyID. Please check your study configuration.");
        return @"";
    }
    return url;
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


- (bool) saveData:(NSDictionary *)data{
    return [self saveData:data toLocalFile:[self getSensorName]];
}


- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
    NSError*error=nil;
    NSData*d=[NSJSONSerialization dataWithJSONObject:data options:2 error:&error];
    NSString*jsonstr= @"";
    // TODO: error hundling of nill in NSDictionary.
    if (!error) {
        jsonstr = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
    } else {
//        NSString * errorStr = [NSString stringWithFormat:@"[%@] %@", [self getSensorName], [error localizedDescription]];
//        [self sendLocalNotificationForMessage:errorStr soundFlag:YES];
        return NO;
        //Do additional data manipulation or handling work here.
    }
    [bufferStr appendString:jsonstr];
    [bufferStr appendFormat:@","];
    if (writeAble) {
        [self appendLine:bufferStr path:fileName];
        [bufferStr setString:@""];
        [self setWriteableNO];
    }
    return YES;
}


- (BOOL) appendLine:(NSString *)line path:(NSString*) fileName {
    if (!line) {
        NSLog(@"[%@] Line is null", [self getSensorName] );
        return NO;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",fileName]];
//    NSLog(@"%@", path);
    if(previusUploadingState){
        [tempData appendFormat:@"%@", line];
        return YES;
    }else{
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        if (fh == nil) { // no
            NSLog(@"[%@] ERROR: AWARE can not handle the file.", fileName);
            [self createNewFile:fileName];
            return NO;
        }else{
            [fh seekToEndOfFile];
            if (![tempData isEqualToString:@""]) {
                NSData * tempdataLine = [tempData dataUsingEncoding:NSUTF8StringEncoding];
                [fh writeData:tempdataLine]; //write temp data to the main file
                [tempData setString:@""];
                NSLog(@"[%@] Add the sensor data to temp variable.", fileName);
            }
            //                    NSString * oneLine = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@\n", line]];
            NSString * oneLine = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@", line]];
            NSData *data = [oneLine dataUsingEncoding:NSUTF8StringEncoding];
            [fh writeData:data];
            [fh synchronizeFile];
            [fh closeFile];
            return YES;
        }
    }
    //        });
    
    return YES;
    
}


-(void)createNewFile:(NSString*) fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",fileName]];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) { // yes
        BOOL result = [manager createFileAtPath:path
                                       contents:[NSData data]
                                     attributes:nil];
        if (!result) {
            NSLog(@"[%@] Failed to create the file.", fileName);
            return;
        }else{
            NSLog(@"[%@] Create the file.", fileName);
        }
    }
}

- (bool) removeFile:(NSString *) fileName {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",fileName]];
    if ([manager fileExistsAtPath:path]) { // yes
        bool result = [@"" writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
        if (result) {
            NSLog(@"[%@] Correct to clear sensor data.", fileName);
        }else{
            NSLog(@"[%@] Error to clear sensor data.", fileName);
        }
        
    }else{
        NSLog(@"[%@] The file is not exist.", fileName);
        [self createNewFile:fileName];
        return YES;
    }
    return NO;
}



- (void) syncAwareDB {
    if (!wifiState) {
        NSLog(@"You need wifi network to upload sensor data.");
        return;
    }
    
    //    NSUInteger seek = 0;
    NSUInteger length = 1000 * 1000; // 1MB
    //    NSUInteger length = 1000 * 100; // 10MB
    NSUInteger seek = marker * length;
    
    previusUploadingState = YES;
    
    // init variables
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    NSString *sensorName = [self getSensorName];
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:sensorName];
    lineCount = 0;
    
    // get sensor data from file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",sensorName]];
    NSMutableString *data = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        NSLog(@"[%@] AWARE can not handle the file.", sensorName);
        [self createNewFile:sensorName];
        previusUploadingState = NO;
        return;// @"[]";
    }
    [fileHandle seekToFileOffset:seek];
    NSData *clipedData = [fileHandle readDataOfLength:length];
    [fileHandle closeFile];
    
    data = [[NSMutableString alloc] initWithData:clipedData encoding:NSUTF8StringEncoding];
    lineCount = (int)data.length;
    NSLog(@"[%@] Line lenght is %ld", [self getSensorName], (unsigned long)data.length);
    if (data.length == 0) {
        previusUploadingState = NO;
        marker = 0;
        return;
    }
    
    if(data.length < length){
        // more post = 0
        marker = 0;
    }else{
        // more post += 1
        marker += 1;
    }
    data = [self fixJsonFormat:data];
    
    // Set settion configu and HTTP/POST body.
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    //        sessionConfig.allowsCellularAccess = NO;
    //        [sessionConfig setHTTPAdditionalHeaders:
    //         @{@"Accept": @"application/json"}];
    sessionConfig.timeoutIntervalForRequest = 120.0;
    //    sessionConfig.timeoutIntervalForResource = 300.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 30;
    
    post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, data];
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    // Check application condition: "foreground(YES)" or "background(NO)"
    //    NSUserDefaults* defaults =` [NSUserDefaults standardUserDefaults];
    //    bool foreground = [defaults objectForKey:@"APP_STATE"];
    
    session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData * _Nullable data,
                                    NSURLResponse * _Nullable response,
                                    NSError * _Nullable error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    int responseCode = (int)[httpResponse statusCode];
                    
                    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"[%@] %d  Response =====> %@",[self getSensorName], responseCode, newStr);
                    
                    if(responseCode == 200){
                        // [self removeFile:[self getSensorName]];
                        // [self createNewFile:[self getSensorName]];
                        NSString *bytes = @"";
                        if (lineCount >= 1000*1000) { //MB
                            bytes = [NSString stringWithFormat:@"%.2f MB", (double)lineCount/(double)(1000*1000)];
                        } else if (lineCount >= 1000) { //KB
                            bytes = [NSString stringWithFormat:@"%.2f KB", (double)lineCount/(double)1000];
                        } else if (lineCount < 1000) {
                            bytes = [NSString stringWithFormat:@"%d Bytes", lineCount];
                        } else {
                            bytes = [NSString stringWithFormat:@"%d Bytes", lineCount];
                        }
                        NSString *message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@ - %d", [self getSensorName], bytes, marker ];
                        NSLog(@"%@", message);
                        // send notification
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        bool debugState = [userDefaults boolForKey:SETTING_DEBUG_STATE];
                        if (debugState) {
//                            [self sendLocalNotificationForMessage:message soundFlag:NO];
                        }
                    }
                    
                    previusUploadingState = NO;
                    
                    data = nil;
                    response = nil;
                    error = nil;
                    httpResponse = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
//                        if (currentVersion >= 9.0) {
//                            [session finishTasksAndInvalidate];
//                            [session invalidateAndCancel];
//                        }
                        if (marker != 0) {
                            [self syncAwareDB];
                        }else{
                            if(responseCode == 200){
                                [self removeFile:[self getSensorName]];
                                //                                NSLog(@"[%@] File is removed.", [self getSensorName]);
                            }
                            //                            previusUploadingState = NO;
                        }
                    });
                }] resume];
    
}

- (NSMutableString *) fixJsonFormat:(NSMutableString *) clipedText {
    // head
    if ([clipedText hasPrefix:@"{"]) {
        NSLog(@"HEAD => correct!");
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"{"];
        if (rangeOfExtraText.location == NSNotFound) {
            NSLog(@"[HEAD] There is no extra text");
        }else{
            NSLog(@"[HEAD] There is some extra text!");
            NSRange deleteRange = NSMakeRange(0, rangeOfExtraText.location);
            [clipedText deleteCharactersInRange:deleteRange];
        }
    }
    
    // tail
    if ([clipedText hasSuffix:@"}"]){
        NSLog(@"TAIL => correct!");
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"}" options:NSBackwardsSearch];
        if (rangeOfExtraText.location == NSNotFound) {
            NSLog(@"[TAIL] There is no extra text");
        }else{
            NSLog(@"[TAIL] There is some extra text!");
            NSRange deleteRange = NSMakeRange(rangeOfExtraText.location+1, clipedText.length-rangeOfExtraText.location-1);
            //                NSLog(@"%@", clipedText);
            [clipedText deleteCharactersInRange:deleteRange];
        }
    }
    [clipedText insertString:@"[" atIndex:0];
    [clipedText appendString:@"]"];
    
    return clipedText;
}

- (NSString *)getLatestSensorData:(NSString *)deviceId withUrl:(NSString *)url{
    NSString *post = [NSString stringWithFormat:@"device_id=%@", deviceId];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response error:&error];
    NSString* newStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@", newStr);
    int responseCode = (int)[response statusCode];
    if(responseCode == 200){
        NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
        return newStr;
    }
    return @"";
}



- (void) createTable:(NSString *)query{
    
    NSLog(@"%@",[self getCreateTableUrl:[self getSensorName]]);
    
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
    [request setURL:[NSURL URLWithString:[self getCreateTableUrl:[self getSensorName]]]];
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

@end
