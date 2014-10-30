//
//  NSManagedObject+ANDYMapChanges.m
//
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

#import "NSManagedObject+ANDYMapChanges.h"

@interface NSManagedObject ()

+ (NSString *)entityName;

@end

@implementation NSManagedObject (ANDYMapChanges)

+ (void)andy_mapChanges:(NSArray *)changes
         withPrimaryKey:(NSString *)primaryKey
              inContext:(NSManagedObjectContext *)context
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated
{
    [self andy_mapChanges:changes
           withPrimaryKey:primaryKey
             andRemoteKey:@"id"
           usingPredicate:nil
                inContext:context
                 inserted:inserted
                  updated:updated];
}

+ (void)andy_mapChanges:(NSArray *)changes
         withPrimaryKey:(NSString *)primaryKey
         usingPredicate:(NSPredicate *)predicate
              inContext:(NSManagedObjectContext *)context
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated
{
    [self andy_mapChanges:changes
           withPrimaryKey:primaryKey
             andRemoteKey:@"id"
           usingPredicate:nil
                inContext:context
                 inserted:inserted
                  updated:updated];
}


+ (void)andy_mapChanges:(NSArray *)changes
         withPrimaryKey:(NSString *)primaryKey
           andRemoteKey:(NSString *)remoteKey
         usingPredicate:(NSPredicate *)predicate
              inContext:(NSManagedObjectContext *)context
               inserted:(void (^)(NSDictionary *objectDict))inserted
                updated:(void (^)(NSDictionary *objectDict, NSManagedObject *object))updated;

{
    NSMutableDictionary *dictionaryIDAndObjectID = nil;

    if (predicate) {
        dictionaryIDAndObjectID = [self dictionaryOfIDsAndFetchedIDsUsingPredicate:predicate
                                                                     andPrimaryKey:primaryKey
                                                                         inContext:context];
    } else {
        dictionaryIDAndObjectID = [self dictionaryOfIDsAndFetchedIDsInContext:context
                                                              usingPrimaryKey:primaryKey];
    }

    NSArray *fetchedObjectIDs = [dictionaryIDAndObjectID allKeys];
    NSArray *remoteObjectIDs = [changes valueForKey:remoteKey];

    NSMutableSet *intersection = [NSMutableSet setWithArray:remoteObjectIDs];
    [intersection intersectSet:[NSSet setWithArray:fetchedObjectIDs]];
    NSArray *updatedObjectIDs = [intersection allObjects];

    NSMutableArray *deletedObjectIDs = [NSMutableArray arrayWithArray:fetchedObjectIDs];
    [deletedObjectIDs removeObjectsInArray:remoteObjectIDs];

    NSMutableArray *insertedObjectIDs = [NSMutableArray arrayWithArray:remoteObjectIDs];
    [insertedObjectIDs removeObjectsInArray:fetchedObjectIDs];

    for (NSNumber *fetchedID in deletedObjectIDs) {
        NSManagedObjectID *objectID = [dictionaryIDAndObjectID objectForKey:fetchedID];
        if (objectID) {
            NSManagedObject *object = [context objectWithID:objectID];
            if (object) {
                [context deleteObject:object];
            }
        }
    }

    for (NSNumber *fetchedID in insertedObjectIDs) {
        [changes enumerateObjectsUsingBlock:^(NSDictionary *objectDict, NSUInteger idx, BOOL *stop) {
            if ([[objectDict objectForKey:remoteKey] isEqualToNumber:fetchedID]) {
                if (inserted) {
                    inserted(objectDict);
                }
            }
        }];
    }

    for (NSNumber *fetchedID in updatedObjectIDs) {
        [changes enumerateObjectsUsingBlock:^(NSDictionary *objectDict, NSUInteger idx, BOOL *stop) {
            if ([[objectDict objectForKey:remoteKey] isEqualToNumber:fetchedID]) {
                NSManagedObjectID *objectID = [dictionaryIDAndObjectID objectForKey:fetchedID];
                if (objectID) {
                    NSManagedObject *object = [context objectWithID:objectID];
                    if (object && updated) {
                        updated(objectDict, object);
                    }
                }
            }
        }];
    }
}

+ (NSMutableDictionary *)dictionaryOfIDsAndFetchedIDsUsingPredicate:(NSPredicate *)predicate
                                                      andPrimaryKey:(NSString *)primaryKey
                                                          inContext:(NSManagedObjectContext *)context
{
    __block NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [context performBlockAndWait:^{
        NSError *error = nil;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
        fetchRequest.predicate = predicate;
        [fetchRequest setResultType:NSDictionaryResultType];
        NSExpressionDescription *objectIdDesc = [[NSExpressionDescription alloc] init];
        objectIdDesc.name = @"objectID";
        objectIdDesc.expression = [NSExpression expressionForEvaluatedObject];
        objectIdDesc.expressionResultType = NSObjectIDAttributeType;
        [fetchRequest setPropertiesToFetch:@[objectIdDesc, primaryKey]];

        NSArray *objects = [context executeFetchRequest:fetchRequest error:&error];
        for (NSDictionary *object in objects) {
            NSNumber *fetchedID = [object valueForKeyPath:primaryKey];
            if (fetchedID) {
                [dictionary setObject:[object valueForKeyPath:@"objectID"] forKey:fetchedID];
            }
        }
    }];

    return dictionary;
}

+ (NSMutableDictionary *)dictionaryOfIDsAndFetchedIDsInContext:(NSManagedObjectContext *)context
                                               usingPrimaryKey:(NSString *)primaryKey
{
    return [self dictionaryOfIDsAndFetchedIDsUsingPredicate:nil
                                              andPrimaryKey:primaryKey
                                                  inContext:context];
}

@end
