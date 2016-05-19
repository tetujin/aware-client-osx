//
//  AWAREStudy.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWAREStudy : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSString* getSettingIdentifier;
@property (strong, nonatomic) NSString* makeDeviceTableIdentifier;
@property (strong, nonatomic) NSString* addDeviceTableIdentifier;


- (BOOL) setStudyInformationWithURL:(NSString*)url;
- (BOOL) refreshStudy;
- (BOOL) clearAllSetting;

// for check
- (BOOL) isAvailable;
- (bool) isReachable;

// MQTT Information
- (NSString* ) getMqttServer;
- (NSString* ) getMqttUserName;
- (NSString* ) getMqttPassowrd;
- (NSNumber* ) getMqttPort;
- (NSNumber* ) getMqttKeepAlive;
- (NSNumber* ) getMqttQos;

// Study Information
- (NSString* ) getStudyId;
- (NSString* ) getWebserviceServer;

// Sensor Infromation
- (NSArray *) getSensors;
- (NSArray *) getPlugins;
- (NSString *) getDeviceId;

@end
