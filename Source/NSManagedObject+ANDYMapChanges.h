//
//  NSManagedObject+ANDYMapChanges.h
//
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

@import CoreData;

@interface NSManagedObject (ANDYMapChanges)

+ (void)andy_mapChanges:(NSArray *)changes
              inContext:(NSManagedObjectContext *)context
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated;

+ (void)andy_mapChanges:(NSArray *)changes
               localKey:(NSString *)localKey
              remoteKey:(NSString *)remoteKey
         usingPredicate:(NSPredicate *)predicate
              inContext:(NSManagedObjectContext *)context
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated;

@end
