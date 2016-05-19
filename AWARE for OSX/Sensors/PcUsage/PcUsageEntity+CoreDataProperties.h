//
//  PcUsageEntity+CoreDataProperties.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 5/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "PcUsageEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface PcUsageEntity (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *state;
@property (nullable, nonatomic, retain) NSString *label;

@end

NS_ASSUME_NONNULL_END
