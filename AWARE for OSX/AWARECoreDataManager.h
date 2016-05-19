//
//  AWARECoreDataUploader.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/30/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWAREStudy.h"
#import "AppDelegate.h"
#import "AWAREKeys.h"
#import "AWAREUtils.h"

@interface AWARECoreDataManager : NSObject <NSURLSessionDelegate,  NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

- (instancetype) initWithSensorName:(NSString *)name
                          entityName:(NSString*)entity
                         awareStudy:(AWAREStudy *) study;

- (void) setFetchLimit:(int)limit;
- (void) setFetchBatchSize:(int)size;
- (void) syncDBInBackground;
- (void) syncDBInForeground;
- (NSString *) getEntityName;

@end
