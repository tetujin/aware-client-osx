//
//  EntityMouseClick+CoreDataProperties.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 6/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityMouseClick.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityMouseClick (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *button;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSString *label;
@property (nullable, nonatomic, retain) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
