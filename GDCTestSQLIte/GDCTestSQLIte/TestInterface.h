//
//  TestInterface.h
//  GDCTestSQLIte
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GDCSQLite/GDCSQLite.h>

@interface TestInterface : NSObject

typedef void(^callCompletationCallback)(BOOL error,NSString *errorDescription);
typedef void(^callProgressCallback)(NSString *progress);


#pragma mark - METHODS
// ###### METHODS ######

+ (void)initDb:(void(^)(GDCDatabase *db, BOOL error, NSString *errorMessage))dbInstance;

+ (NSString *)openDb:(GDCDatabase *)db;

+ (NSString *)closeDb:(GDCDatabase *)db;

+ (void)insertTestPersonInto:(GDCDatabase *)db progress:(callProgressCallback)progress;

+ (NSArray *)selectDataFromTable:(NSString *)table andWhere:(NSString *)where fromDb:(GDCDatabase *)database;

+ (NSArray *)runQuery:(NSString *)query isSelect:(BOOL)isSelect fromDb:(GDCDatabase *)database;

+ (void)logSelectArrayResult:(NSArray *)result;

// #####################
@end
