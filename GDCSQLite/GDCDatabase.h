//
//  GDCDatabase.h
//  GDCSQLite
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface GDCDatabase : NSObject

#pragma mark - PROPERTY
// ****** PROPERY ******

/* ------ DEBUG ------ */
@property (nonatomic) BOOL DEBUG_SQLMANAGER;
@property (nonatomic) BOOL DEBUG_DBMANAGER;
/* ---------------- */

@property (nonatomic, strong) NSString *valueToReplaceToNullValue;

@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSString *databaseFilename;

@property (nonatomic, strong) NSMutableArray *fetchedRowArray;
@property (nonatomic, strong) NSMutableArray *valuesArray;
@property (nonatomic, strong) NSMutableArray *attributesArray;
@property (nonatomic, strong) NSNumber *affectedRows;
@property (nonatomic, strong) NSNumber *lastInsertedRowID;

// ***************************

#pragma mark - CALLBACK

// ****** CALLBACK ******

/**
 <p>
	Callback for completation
 </p>
 */
typedef void(^callCompletationCallback)(BOOL error,NSString *errorDescription);


// ***************************

#pragma mark - METHODS

// ****** METHODS ******

/**
 * Init the class instance and call the database check
 *
 * @param dbFilename The name of DataBase
 *
 */
-(void)initWithDatabaseFilename:(NSString *)dbFilename force:(BOOL)force completation:(callCompletationCallback)completation;

/**
 <p>
 Load a non executable query
 </p>
 
 @param query The query to load
 
 @return an NSArray fetchedRowArray with 2 dimension, any row
 <p>
	[0]->(NSArray)Atributes
 <br>
	[1]->(NSArray)Value
 </p>
 */
- (NSArray *)loadQuery:(NSString *)query;

/**
	Load a query a executable

	@param query The query select to run

	@return an NSArray with 2 dimension,
	<p>
		[0]->(NSNumber)RowAffected
	<br>
		[1]->(NSNumber)LastId
	</p>
 */
- (NSArray *)executeQuery:(NSString *)query;

/**
 <p>
	Open connection
 </p>
 
 */
- (void)openConnection;

/**
 <p>
	Close connection
 </p>
 
 */
- (void)closeConnection;

// ***************************
@end
