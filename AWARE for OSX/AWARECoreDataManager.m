//
//  AWARECoreDataUploader.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/30/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARECoreDataManager.h"

@implementation AWARECoreDataManager {
    AWAREStudy * awareStudy;
    NSString* entityName;
    NSString* sensorName;
    NSString * syncDataQueryIdentifier;
    NSString * createTableQueryIdentifier;
    NSString * timeMarkerIdentifier;
    double httpStartTimestamp;
    double postedTextLength;
    BOOL isDebug;
    BOOL isUploading;
    BOOL isSyncWithOnlyBatteryCharging;
    int errorPosts;
    
    int fetchLimit;
    int batchSize;
    
    NSNumber * unixtimeOfUploadingData;
}

- (instancetype)initWithSensorName:(NSString *)name entityName:(NSString *)entity awareStudy:(AWAREStudy *)study{
    self = [super init];
    if(self != nil){
        awareStudy = study;
        sensorName = name;
        entityName = entity;
        isUploading = NO;
        httpStartTimestamp = [[NSDate new] timeIntervalSince1970];
        postedTextLength = 0;
        errorPosts = 0;
        fetchLimit = 100;
        batchSize = 0;
        syncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        createTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        timeMarkerIdentifier = [NSString stringWithFormat:@"uploader_coredata_timestamp_marker_%@", sensorName];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        isDebug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        
        NSNumber * timestamp = [userDefaults objectForKey:timeMarkerIdentifier];
        if(timestamp == 0){
            [self setTimeMark:[NSDate new]];
        }
    }
    return self;
}

- (void)setFetchLimit:(int)limit{
    fetchLimit = limit;
}

- (void)setFetchBatchSize:(int)size{
    batchSize = size;
}

- (void)syncDBInBackground{
    // chekc wifi state
    if(isUploading){
        NSString * message= [NSString stringWithFormat:@"[%@] AWARE is uploading sendsor data now. So, a new upload process was killed.", sensorName];
        NSLog(@"%@", message);
        return;
    }
    
    // chekc wifi state
    if (![awareStudy isReachable]) {
        NSString * message = [NSString stringWithFormat:@"[%@] Wifi is not availabe.", sensorName];
        NSLog(@"%@", message);
        return;
    }
    
    // check battery condition
//    if (isSyncWithOnlyBatteryCharging) {
//        NSInteger batteryState = [UIDevice currentDevice].batteryState;
//        if ( batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
//        }else{
//            NSString * message = [NSString stringWithFormat:@"[%@] This device is not charginig battery now.", sensorName];
//            NSLog(@"%@", message);
//            return;
//        }
//    }
    
    isUploading = YES;
    [self uploadSensorDataInBackground];
}


- (NSString *)getEntityName{
    return entityName;
}


//////////////////////////////////////////////////
//////////////////////////////////////////////////

- (void) setTimeMark:(NSDate *) timestamp {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[AWAREUtils getUnixTimestamp:timestamp] forKey:timeMarkerIdentifier];
}

- (void) setTimeMarkWithTimestamp:(NSNumber *)timestamp  {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:timestamp forKey:timeMarkerIdentifier];
}


- (NSNumber *) getTimeMark {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:timeMarkerIdentifier];
}


/////////////////////////////////////////////////
/////////////////////////////////////////////////



- (NSData *) getSensorData{
    
    AppDelegate *delegate=(AppDelegate*)[NSApplication sharedApplication].delegate;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setFetchLimit:fetchLimit];
    if (batchSize != 0) [fetchRequest setFetchBatchSize:batchSize];
    
    NSNumber * timestamp = [self getTimeMark];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp]];

    //Set sort option
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    //Get NSManagedObject from managedObjectContext by using fetch setting
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];

    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSManagedObject *data in results) {
        NSArray *keys = [[[data entity] attributesByName] allKeys];
        NSDictionary *dict = [data dictionaryWithValuesForKeys:keys];
        unixtimeOfUploadingData = [dict objectForKey:@"timestamp"];
//        NSLog(@"[%@] timestamp: %@",[self getEntityName] , unixtimeOfUploadingData );
        [array addObject:dict];
    }
    
    if (results != nil) {
        NSError * error = nil;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
        if (error == nil && jsonData != nil) {
            return jsonData; //[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}


- (void) removeUploadedDate {
    
    AppDelegate *delegate=(AppDelegate*)[NSApplication sharedApplication].delegate;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSNumber * timestamp = [self getTimeMark];
    [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp <= %@", timestamp]];
    
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    NSError *deleteError = nil;
    [delegate.managedObjectContext executeRequest:delete error:&deleteError];
//    NSBatchDeleteResult * result =
//    NSLog(@"%ld", [[result result] count]);
    if (deleteError != nil) {
        NSLog(@"%@", deleteError.debugDescription);
    }
}


- (NSUInteger)getCategoryCount {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    AppDelegate *delegate=(AppDelegate*)[NSApplication sharedApplication].delegate;
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:delegate.managedObjectContext]];
    [request setIncludesSubentities:NO];
    
    NSNumber * timestamp = [self getTimeMark];
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp]];
    
    NSError* error = nil;
    NSUInteger count = [delegate.managedObjectContext countForFetchRequest:request error:&error];
    if (count == NSNotFound) {
        count = 0;
    }
    
    if(error != nil){
        NSLog(@"%@", error.debugDescription);
    }
    
    return count;
}


//////////////////////////////////////////////////
//////////////////////////////////////////////////

/**
 * Upload method
 */
- (void) uploadSensorDataInBackground {
    
    NSString *deviceId = [self getDeviceId];
    NSString *url = [AWAREUtils getInsertUrl:sensorName awareStudy:awareStudy];
    
    // Get sensor data from CoreData
    NSData* sensorData = [self getSensorData];
    
    if (sensorData == nil || sensorData.length == 0 || sensorData.length == 2) {
        NSString * message = [NSString stringWithFormat:@"[%@] The data is 'null', or the length of data is 'zero'", sensorName];
        NSLog(@"%@", message);
        [self dataSyncIsFinishedCorrectoly];
        return;
    }
    
//    NSString * line = [[NSString alloc] initWithData:sensorData encoding:NSUTF8StringEncoding];
//    NSLog(@"[%@] \n %@", [self getEntityName], line );
    
    // Set session configuration
    NSURLSessionConfiguration *sessionConfig = nil;
    double unxtime = [[NSDate new] timeIntervalSince1970];
    syncDataQueryIdentifier = [NSString stringWithFormat:@"%@%f", syncDataQueryIdentifier, unxtime];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:syncDataQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 60 * 3;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60 * 3;
    sessionConfig.timeoutIntervalForResource = 60 * 3;
    sessionConfig.allowsCellularAccess = NO;
    
    // set HTTP/POST body information
    NSString* post = [NSString stringWithFormat:@"device_id=%@&data=", deviceId];
    NSData* postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:postData];
    [mutablePostData appendData:sensorData];
    
    NSString* postLength = [NSString stringWithFormat:@"%ld", [mutablePostData length]];
    //    NSLog(@"Data Length: %@", postLength);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:mutablePostData];
    
    NSString * logMessage = [NSString stringWithFormat:@"[%@] A background task is ready to start.", sensorName];
    NSLog(@"%@", logMessage);
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:self
                                                     delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    
    httpStartTimestamp = [[NSDate new] timeIntervalSince1970];
    postedTextLength = [[NSNumber numberWithInteger:postData.length] doubleValue];
    
    [dataTask resume];
}

///////////////////////////////////////////////////
///////////////////////////////////////////////////

- (void)syncDBInForeground{
    
}


/////////////////////////////////////////////////
/////////////////////////////////////////////////

/* The task has received a response and no further messages will be
 * received until the completion block is called. The disposition
 * allows you to cancel a request or to turn a data task into a
 * download task. This delegate message is optional - if you do not
 * implement it, you can get the response as a property of the task.
 *
 * This method will not be called for background upload tasks (which cannot be converted to download tasks).
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    // test: server peformance
    double diff = [[NSDate new] timeIntervalSince1970] - httpStartTimestamp;
    if (postedTextLength > 0 && diff > 0) {
        NSString *networkPeformance = [NSString stringWithFormat:@"%0.2f KB/s",postedTextLength/diff/1000.0f];
        NSLog(@"[%@] Uploading speed => %@", sensorName, networkPeformance);
    }
    
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    completionHandler(NSURLSessionResponseAllow);
    
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        NSLog(@"[%@] Get a response from the server.", sensorName);
        [self receivedResponseFromServer:dataTask.response withData:nil error:nil];
    } else if ( [session.configuration.identifier isEqualToString:createTableQueryIdentifier] ){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        int responseCode = (int)[httpResponse statusCode];
        if (responseCode == 200) {
            NSLog(@"[%@] Sucess to create new table on AWARE server.", sensorName);
        }
    } else {
        
    }
}

/* Notification that a data task has become a download task.  No
 * future messages will be sent to the data task.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask{
    
}

/*
 * Notification that a data task has become a bidirectional stream
 * task.  No future messages will be sent to the data task.  The newly
 * created streamTask will carry the original request and response as
 * properties.
 *
 * For requests that were pipelined, the stream object will only allow
 * reading, and the object will immediately issue a
 * -URLSession:writeClosedForStream:.  Pipelining can be disabled for
 * all requests in a session, or by the NSURLRequest
 * HTTPShouldUsePipelining property.
 *
 * The underlying connection is no longer considered part of the HTTP
 * connection cache and won't count against the total number of
 * connections per host.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask{
    
}

/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        // If the data is null, this method is not called.
        NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] Response => %@", sensorName, result);
    } else if ([session.configuration.identifier isEqualToString:createTableQueryIdentifier]){
        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] Response => %@",sensorName, newStr);
    }
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    session = nil;
    dataTask = nil;
    data = nil;
}

/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (error != nil) {
        NSLog(@"[%@] The session did become invaild with error: %@", sensorName, error.debugDescription);
//        [AWAREUtils sendLocalNotificationForMessage:error.debugDescription soundFlag:NO];
    }
    [session invalidateAndCancel];
    [session finishTasksAndInvalidate];
}

//////////////////////////////////////////////
/////////////////////////////////////////////

- (void)receivedResponseFromServer:(NSURLResponse *)response
                          withData:(NSData *)data
                             error:(NSError *)error{
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    NSLog(@"[%@] The response code is %d",sensorName, responseCode);
    //    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //    NSLog(@"[%@] %d  Response =====> %@",sensorName, responseCode, newStr);
    
    data = nil;
    response = nil;
    error = nil;
    httpResponse = nil;
    
    if ( responseCode == 200 ) {
        [self setTimeMarkWithTimestamp:unixtimeOfUploadingData];
        [self removeUploadedDate];
        if ([self getCategoryCount] < fetchLimit ){
            [self dataSyncIsFinishedCorrectoly];
        }else{
            [self uploadSensorDataInBackground];
        }
    }
}



/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error;
{
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        if (error) {
            errorPosts++;
            if (isDebug) {
            }
            if (errorPosts < 3) { //TODO
                [self uploadSensorDataInBackground];
            } else {
                [self dataSyncIsFinishedCorrectoly];
            }
        } else {
            
        }
        // NSLog(@"%@", task.description);
        return;
    } else if ([session.configuration.identifier isEqualToString:createTableQueryIdentifier]){
        session = nil;
        task = nil;
    }
}

- (void) dataSyncIsFinishedCorrectoly {
    isUploading = NO;
    NSLog(@"[%@] A session task is finished correctly.", sensorName);
    errorPosts = 0;
}


/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

/**
 * AWARE URL makers
 */

- (NSString *)getDeviceId{
    NSString * deviceId = [awareStudy getDeviceId];
    return deviceId;
}


//////////////////////////////////////////////
/////////////////////////////////////////////


/**
 * Return current network condition with a text
 */
//- (NSString *) getNetworkReachabilityAsText{
//    return [awareStudy getNetworkReachabilityAsText];
//}


////////////////////////////////////////////
////////////////////////////////////////////
//SSL
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    
}


@end
