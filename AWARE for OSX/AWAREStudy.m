//
//  AWAREStudy.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREStudy.h"
#import "AWAREKeys.h"

@implementation AWAREStudy{
    NSString *crtUrl;
    NSString *mqttPassword;
    NSString *mqttUsername;
    NSString *studyId;
    NSString *mqttServer;
    NSString *webserviceServer;
    int mqttPort;
    int mqttKeepAlive;
    int mqttQos;
    
    bool readingState;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        crtUrl = @"http://www.awareframework.com/awareframework.crt";
        mqttPassword = @"";
        mqttUsername = @"";
        studyId = @"";
        mqttServer = @"";
        webserviceServer = @"";
        mqttPort = 1883;
        mqttKeepAlive = 600;
        mqttQos = 2;
        readingState = YES;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString* tempUserName = [userDefaults objectForKey:KEY_MQTT_USERNAME];
        if(tempUserName != nil){
            mqttServer = [userDefaults objectForKey:KEY_MQTT_SERVER];
            mqttUsername = [userDefaults objectForKey:KEY_MQTT_USERNAME];
            mqttPassword =  [userDefaults objectForKey:KEY_MQTT_PASS];
            mqttPort =  [[userDefaults objectForKey:KEY_MQTT_PORT] intValue];
            mqttKeepAlive = [[userDefaults objectForKey:KEY_MQTT_KEEP_ALIVE] intValue];
            mqttQos = [[userDefaults objectForKey:KEY_MQTT_QOS] intValue];
            studyId = [userDefaults objectForKey:KEY_STUDY_ID];
            webserviceServer = [userDefaults objectForKey:KEY_WEBSERVICE_SERVER];
        }
    }
    return self;
}


- (NSString *)getSystemUUID {
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    if (!platformExpert)
        return nil;
    
    CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformUUIDKey),kCFAllocatorDefault, 0);
    if (!serialNumberAsCFString)
        return nil;
    
    IOObjectRelease(platformExpert);
    return (__bridge NSString *)(serialNumberAsCFString);;
}

- (BOOL) setStudyInformationWithURL:(NSString*)url {
    return [self setStudyInformation:url withDeviceId:[self getSystemUUID]];
}

- (bool) setStudyInformation:(NSString *)url withDeviceId:(NSString *) uuid {
    NSString *post = [NSString stringWithFormat:@"device_id=%@", uuid];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        int responseCode = (int)[response statusCode];
        NSLog(@"%d",responseCode);
        if(responseCode == 0){
//            NSString *url =  crtUrl;
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }else{
            NSArray *mqttArray = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:nil];
            id obj = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:nil];
            NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
            NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            
//            dispatch_async(dispatch_get_main_queue(), ^{
                if(responseCode == 200){
                    NSLog(@"GET Study Information");
                    NSArray * array = [[mqttArray objectAtIndex:0] objectForKey:@"sensors"];
                    NSArray * plugins = [[mqttArray objectAtIndex:0] objectForKey:KEY_PLUGINS];
                    for (int i=0; i<[array count]; i++) {
                        NSDictionary *settingElement = [array objectAtIndex:i];
                        NSString *setting = [settingElement objectForKey:@"setting"];
                        NSString *value = [settingElement objectForKey:@"value"];
                        if([setting isEqualToString:@"mqtt_password"]){
                            mqttPassword = value;
                        }else if([setting isEqualToString:@"mqtt_username"]){
                            mqttUsername = value;
                        }else if([setting isEqualToString:@"mqtt_server"]){
                            mqttServer = value;
                        }else if([setting isEqualToString:@"mqtt_server"]){
                            mqttServer = value;
                        }else if([setting isEqualToString:@"mqtt_port"]){
                            mqttPort = [value intValue];
                        }else if([setting isEqualToString:@"mqtt_keep_alive"]){
                            mqttKeepAlive = [value intValue];
                        }else if([setting isEqualToString:@"mqtt_qos"]){
                            mqttQos = [value intValue];
                        }else if([setting isEqualToString:@"study_id"]){
                            studyId = value;
                        }else if([setting isEqualToString:@"webservice_server"]){
                            webserviceServer = value;
                        }
                    }
                    
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    // if Study ID is new, AWARE adds new Device ID to the AWARE server.
                    NSString * oldStudyId = [userDefaults objectForKey:KEY_STUDY_ID];
                    if(![oldStudyId isEqualToString:studyId]){
                        NSLog(@"Add new device ID to the AWARE server.");
                        [self addNewDeviceToAwareServer:url withDeviceId:uuid];
                    }else{
                        NSLog(@"This device ID is already regited to the AWARE server.");
                    }
                    [userDefaults setObject:mqttServer forKey:KEY_MQTT_SERVER];
                    [userDefaults setObject:mqttPassword forKey:KEY_MQTT_PASS];
                    [userDefaults setObject:mqttUsername forKey:KEY_MQTT_USERNAME];
                    [userDefaults setObject:[NSNumber numberWithInt:mqttPort] forKey:KEY_MQTT_PORT];
                    [userDefaults setObject:[NSNumber numberWithInt:mqttKeepAlive] forKey:KEY_MQTT_KEEP_ALIVE];
                    [userDefaults setObject:[NSNumber numberWithInt:mqttQos] forKey:KEY_MQTT_QOS];
                    [userDefaults setObject:studyId forKey:KEY_STUDY_ID];
                    [userDefaults setObject:webserviceServer forKey:KEY_WEBSERVICE_SERVER];
                    [userDefaults synchronize];
                    
                    [userDefaults setObject:array forKey:KEY_SENSORS];
                    [userDefaults setObject:plugins forKey:KEY_PLUGINS];
                    
                    readingState = YES;
                }else{
                    NSLog(@"AWARE cannot get study information from AWARE server.");
                }
//            });
        }
//    });
    return YES;
}


- (bool) addNewDeviceToAwareServer:(NSString *)url withDeviceId:(NSString *) uuid {
    url = [NSString stringWithFormat:@"%@/aware_device/insert", url];
    NSMutableDictionary *jsonQuery = [[NSMutableDictionary alloc] init];
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    
    NSString *deviceName = @"";
    NSString *manufacturer = @"Apple";
    NSString *model = @"Mac Book ---";
    NSString *code = @"";
    NSString *systemVersion = @"";
    NSString *identifier = @"";
    NSString *name = @"";
    
    [jsonQuery setValue:uuid  forKey:@"device_id"];
    [jsonQuery setValue:unixtime forKey:@"timestamp"];
    [jsonQuery setValue:manufacturer forKey:@"board"];//    board	TEXT	Manufacturer’s board name
    [jsonQuery setValue:model forKey:@"brand"];//    brand	TEXT	Manufacturer’s brand name
    [jsonQuery setValue:manufacturer forKey:@"device"];//    device	TEXT	Manufacturer’s device name
    [jsonQuery setValue:code forKey:@"build_id"];//    build_id	TEXT	Android OS build ID
    [jsonQuery setValue:manufacturer forKey:@"hardware"];//    hardware	TEXT	Hardware codename
    [jsonQuery setValue:manufacturer forKey:@"manufacturer"];//    manufacturer	TEXT	Device’s manufacturer
    [jsonQuery setValue:deviceName forKey:@"model"];//    model	TEXT	Device’s model
    [jsonQuery setValue:manufacturer forKey:@"product"];//    product	TEXT	Device’s product name
    [jsonQuery setValue:identifier forKey:@"serial"];//    serial	TEXT	Manufacturer’s device serial, not unique
    [jsonQuery setValue:systemVersion forKey:@"release"];//    release	TEXT	Android’s release
    [jsonQuery setValue:@"user" forKey:@"release_type"];//    release_type	TEXT	Android’s type of release (e.g., user, userdebug, eng)
    [jsonQuery setValue:systemVersion forKey:@"sdk"];//    sdk	INTEGER	Android’s SDK level
    [jsonQuery setValue:name forKey:@"label"];
    
    //    [[UIDevice currentDevice] platformType]   // ex: UIDevice4GiPhone
    //    [[UIDevice currentDevice] platformString] // ex: @"iPhone 4G"
    
    NSMutableArray *a = [[NSMutableArray alloc] init];
    [a addObject:jsonQuery];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:a
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = @"";
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",jsonString);
    }
    NSString *post = [NSString stringWithFormat:@"data=%@&device_id=%@", jsonString,uuid];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        int responseCode = (int)[response statusCode];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(responseCode == 200){
                NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
            }else{
                NSLog(@"ERROR");
            }
        });
    });
    return true;
}

// bool
- (BOOL) isAvailable {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray * sensors = [userDefaults objectForKey:KEY_SENSORS];
    if(sensors){
        return YES;
    }else{
        return NO;
    }
}

// MQTT Information
- (NSString* ) getMqttServer{
    return mqttServer;
}

- (NSString* ) getMqttUserName{
    return mqttUsername;
}

- (NSString* ) getMqttPassowrd{
    return mqttPassword;
}

- (NSNumber* ) getMqttPort{
    return [NSNumber numberWithInt:mqttPort];
}

- (NSNumber* ) getMqttKeepAlive{
    return [NSNumber numberWithInt:mqttKeepAlive];
}

- (NSNumber* ) getMqttQos{
    return [NSNumber numberWithInt:mqttKeepAlive];
}

// Study Information
- (NSString* ) getStudyId{
    return studyId;}

- (NSString* ) getWebserviceServer{
    return webserviceServer;
}

// Sensor Infromation
- (NSArray *) getSensors {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:KEY_SENSORS];
}

- (NSArray *) getPlugins{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:KEY_PLUGINS];
}

- (BOOL) clearAllSetting {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:KEY_MQTT_SERVER];
    [userDefaults removeObjectForKey:KEY_MQTT_USERNAME];
    [userDefaults removeObjectForKey:KEY_MQTT_PASS];
    [userDefaults removeObjectForKey:KEY_MQTT_PORT];
    [userDefaults removeObjectForKey:KEY_MQTT_KEEP_ALIVE];
    [userDefaults removeObjectForKey:KEY_MQTT_QOS];
    [userDefaults removeObjectForKey:KEY_STUDY_ID];
    [userDefaults removeObjectForKey:KEY_WEBSERVICE_SERVER];
    [userDefaults removeObjectForKey:KEY_SENSORS];
    [userDefaults removeObjectForKey:KEY_PLUGINS];
    return YES;
}

@end
