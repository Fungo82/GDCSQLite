//
//  GDCDatabase.h
//  GDCSQLite
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface GDCDatabase : NSObject

//Property
@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSString *databaseFilename;
@property (nonatomic, strong) NSString *databaseFilename1;

@property (nonatomic, strong) NSMutableArray *arrResults;
@property (nonatomic, strong) NSMutableArray *arrColumnNames;
@property (nonatomic) int affectedRows;
@property (nonatomic) long long lastInsertedRowID;

#pragma mark - CALLBACK

// ****** CALLBACK ******

/**
 <p>
	Callback per la completation
 </p>
 */
typedef void(^callCompletationCallback)(BOOL error,NSString *errorDescription);


// ***************************

#pragma mark - METHODS

// ****** METHODS ******

/**
 * Init the class instance and call the database check
 *
 * @author Germano Dario Carlino
 *
 * @param dbFilename The name of DataBase
 *
 */
-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename force:(BOOL)force completation:(callCompletationCallback)completationo;


/**
 * Load a query non executable
 *
 * @param query The query select to run
 *
 * @return an NSArray with 2 dimension, one to result and another with column attributes
 */
-(NSArray *)loadDataFromDB:(NSString *)query;

/**
 * Load a query a executable
 *
 * @param query The query select to run
 *
 */
- (void)executeQuery:(NSString *)query;

- (void)openConnection;

- (void)closeConnection;

// ***************************
@end
