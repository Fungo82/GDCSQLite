//
//  GDCDatabase.m
//  GDCSQLite
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//
#import <sqlite3.h>
#import "GDCDatabase.h"

/* ------ ERROR MESSAGE ------ */

#define GDCDATABASE_ERROR_EMPTY		@""
#define GDCDATABASE_ERROR_REMOVE	@"Remove db error:"
#define GDCDATABASE_ERROR_COPY		@"Copy db error:"

#define GDCDATABASE_OPEN_CONNECTION_OK		@"OPEN CONNECTION OK"
#define GDCDATABASE_OPEN_CONNECTION_ERROR	@""

#define GDCDATABASE_CLOSE_CONNECTION_OK		@"CLOSE CONNECTION OK"
#define GDCDATABASE_CLOSE_CONNECTION_BUSY	@"NOT CLOSED IS BUSY"
#define GDCDATABASE_CLOSE_CONNECTION_ERROR	@"NOT CLOSED"

/* ---------------------------- */

@interface GDCDatabase(){
	// Create a sqlite object.
	sqlite3 *sqlite3Database;

	// Database file path.
	NSString *databasePath;

	// Return value from sqlite3_open
	int openDatabaseResult;
	
	// Error message
	NSString *errorMessage;
	
}

/**
	Clean end init the result array
 
 */
- (void)initializeResultArray;

/**
 * Check if db exist in Document path, otherwise copy the db in Document
 *
 * @param dbFilename The name of DataBase
 *
 */
- (void)copyDatabaseIntoDocumentsDirectory:(callCompletationCallback)completation;

/**
 * Check if db exist in Document path, remove current db end copy the new db in Document
 *
 * @param dbFilename The name of DataBase
 *
 */
- (void)removeAndCopyDatabaseIntoDocumentsDirectory:(callCompletationCallback)completation;

/**
 * Run a query in two differnt mode in function of the type of query
 *
 * @param query The query to execute
 * @param queryExecutable To inform the method if is a executable query like insert, update, delete
 *
 */
- (void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable;

@end

@implementation GDCDatabase

#pragma mark - INIT

-(void)initWithDatabaseFilename:(NSString *)dbFilename force:(BOOL)force completation:(callCompletationCallback)completation{
	
	// Set the documents directory path to the documentsDirectory property.
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	self.documentsDirectory = [paths objectAtIndex:0];
	
	// Keep the database filename.
	self.databaseFilename = dbFilename;
	
	if (force) {
		
		// Copy the database file into the documents directory
		[self removeAndCopyDatabaseIntoDocumentsDirectory:^(BOOL error, NSString *errorDescription) {
			completation(error,errorDescription);
		}];
	}else{
		
		// Copy the database file into the documents directory if necessary
		[self copyDatabaseIntoDocumentsDirectory:^(BOOL error, NSString *errorDescription) {
			completation(error,errorDescription);
		}];
	}
	
	openDatabaseResult = -1;
}

#pragma mark - METHODS
/* ###### METHODS ###### */

#pragma mark - PRIVATE METHODS
// ------ PRIVATE ------

- (void)initializeResultArray{
	
	// Initialize the values array.
	if (self.valuesArray != nil) {
		[self.valuesArray removeAllObjects];
		self.valuesArray = nil;
	}
	self.valuesArray = [[NSMutableArray alloc] init];
	
	// Initialize the attributes array.
	if (self.attributesArray != nil) {
		[self.attributesArray removeAllObjects];
		self.attributesArray = nil;
	}
	self.attributesArray = [[NSMutableArray alloc] init];
}

- (void)copyDatabaseIntoDocumentsDirectory:(callCompletationCallback)completation{
	
	NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
	
	// Check if the database file exists in the documents directory.
	if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
		// The database file does not exist in the documents directory, so copy it from the main bundle now.
		NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
		NSError *error;
		[[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
		
		// Check if any error occurred during copying and display it.
		if (error != nil) {
			completation(YES,[NSString stringWithFormat:@"%@ %@",GDCDATABASE_ERROR_COPY,[error localizedDescription]]);
		}else{
			completation(NO,GDCDATABASE_ERROR_EMPTY);
		}
	}else{
		completation(NO,GDCDATABASE_ERROR_EMPTY);
	}
	
}

- (void)removeAndCopyDatabaseIntoDocumentsDirectory:(callCompletationCallback)completation{
	NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
	NSError *error;
	if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:destinationPath error:&error];
		if (error != nil) {
			completation(YES,[NSString stringWithFormat:@"%@ %@",GDCDATABASE_ERROR_REMOVE,[error localizedDescription]]);
			return;
		}else{
			//completation(NO,GDCDATABASE_ERROR_EMPTY);
		}
	}
	NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
	[[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
	
	// Check if any error occurred during copying and display it.
	if (error != nil) {
		completation(YES,[NSString stringWithFormat:@"%@ %@",GDCDATABASE_ERROR_COPY,[error localizedDescription]]);
	}else{
		completation(NO,GDCDATABASE_ERROR_EMPTY);
	}
}

- (void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable{
	
	if (self.DEBUG_SQLMANAGER) {
		NSLog(@"QUERY: %s",query);
	}
	
	if (self.valueToReplaceToNullValue == nil) {
		self.valueToReplaceToNullValue = @"null";
	}
	
	// Initialize the fetched data row array.
	if (self.fetchedRowArray != nil) {
		[self.fetchedRowArray removeAllObjects];
		self.fetchedRowArray = nil;
	}
	self.fetchedRowArray = [[NSMutableArray alloc] init];
	
	errorMessage = @"";
	self.affectedRows		= [[NSNumber alloc] initWithInt:0];
	self.lastInsertedRowID	= [[NSNumber alloc] initWithInt:0];
	
	if(openDatabaseResult == SQLITE_OK) {
		
		// Declare a sqlite3_stmt object, stored the query after having been compiled into a SQLite statement.
		sqlite3_stmt *compiledStatement;
		
		// Load all data from database to memory.
		int prepareStatementResult = sqlite3_prepare_v2(sqlite3Database, query, -1, &compiledStatement, NULL);
		
		switch (prepareStatementResult) {
			case SQLITE_OK:{
				
				if (!queryExecutable){
					// In this case data must be loaded from the database.
	
					while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
						
						[self initializeResultArray];
						
						// Get the total number of columns.
						int totalColumns	= sqlite3_column_count(compiledStatement);
						char *dbAttribute;
						char *dbValue;
						
						// Go through all columns and fetch each column data.
						for (int i = 0; i < totalColumns; i++){
							
							// Convert the column data to text.
							dbAttribute	= (char *)sqlite3_column_name(compiledStatement, i);
							dbValue		= (char *)sqlite3_column_text(compiledStatement, i);
							
							// If there are values in the currenct column then add them to the current row array.
							if (dbValue != NULL) {
								// Convert the characters to string.
								//[dataRowArray addObject:[NSString  stringWithUTF8String:dbValue]];
								[self.valuesArray addObject:[NSString stringWithUTF8String:dbValue]];
							}else{
								// If parameter is null
								//[dataRowArray addObject:self.valueToReplaceToNullValue];
								[self.valuesArray addObject:self.valueToReplaceToNullValue];
							}
							
							// Keep the current column name.
							if (self.attributesArray.count != totalColumns) {
								[self.attributesArray addObject:[NSString stringWithUTF8String:dbAttribute]];
							}
						}
						
						if (self.attributesArray.count > 0 && self.valuesArray.count > 0) {
							// Store each fetched data row in the fetched array
							[self.fetchedRowArray addObject:@[(NSArray *)self.attributesArray.copy,(NSArray *)self.valuesArray.copy]];
						}
						
					}
					
					sqlite3_reset(compiledStatement);
					compiledStatement = nil;
					
				}else {
					
					// Execute the query.
					if (sqlite3_step(compiledStatement) == SQLITE_DONE) {
						
						// Keep the affected rows.
						self.affectedRows = [NSNumber numberWithInt:sqlite3_changes(sqlite3Database)];
						
						// Keep the last inserted row ID.
						self.lastInsertedRowID = [NSNumber numberWithInteger:sqlite3_last_insert_rowid(sqlite3Database)];
						
					}else {
						// If could not execute the query
						errorMessage = [NSString  stringWithUTF8String:sqlite3_errmsg(sqlite3Database)];
						if (self.DEBUG_DBMANAGER) {
							NSLog(@"DB Error: %s - Query: %s", sqlite3_errmsg(sqlite3Database),query);
						}
					}
				}
				break;
			}
			default:{
				
				// In the database cannot be opened
				errorMessage = [NSString  stringWithUTF8String:sqlite3_errmsg(sqlite3Database)];
				if (self.DEBUG_DBMANAGER) {
					NSLog(@"DB not opened %s", sqlite3_errmsg(sqlite3Database));
				}
				break;
			}
		}
		// Release the compiled statement from memory.
		sqlite3_finalize(compiledStatement);
	}else{
		errorMessage = [NSString  stringWithUTF8String:sqlite3_errmsg(sqlite3Database)];
	}
}

// --------------------- end private methods

#pragma mark - PUBLIC METHODS
// ------ PUBLIC ------

- (NSArray *)loadQuery:(NSString *)query{
	
	[self runQuery:[query UTF8String] isQueryExecutable:NO];
	
	return @[(NSArray *)self.fetchedRowArray,errorMessage];
}

- (NSArray *)executeQuery:(NSString *)query{
	// Run the query and indicate that is executable.
	[self runQuery:[query UTF8String] isQueryExecutable:YES];

	NSNumber *affected = [[NSNumber alloc] initWithInt:0];
	
	if ([self.affectedRows isEqual:[NSNull null]] || (self.affectedRows == nil) || [[self.affectedRows description] isEqualToString:@"(null)"]) {
		affected = 0;
	}else{
		affected = self.affectedRows;
	}
	
	NSNumber *lastId = [[NSNumber alloc] initWithInt:0];
	if ([self.lastInsertedRowID isEqual:[NSNull null]] || (self.lastInsertedRowID == nil) || [[self.lastInsertedRowID description] isEqualToString:@"(null)"]) {
		lastId = 0;
	}else{
		lastId = self.lastInsertedRowID;
	}
	
	//NSLog(@"Affected: %@ -- LastId: %@ -- Error: %@",affected,lastId,errorMessage);
	
	return @[affected,lastId,errorMessage];
}

- (NSString *)openConnection{
	
	databasePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
	
	openDatabaseResult = sqlite3_open([databasePath UTF8String], &sqlite3Database);
	
	if (openDatabaseResult == SQLITE_OK) {
		return GDCDATABASE_OPEN_CONNECTION_OK;
	}else{
		return [NSString  stringWithUTF8String:sqlite3_errmsg(sqlite3Database)];
	}
}

- (NSString *)closeConnection{
	
	// Close the database.
	int returnValue = sqlite3_close_v2(sqlite3Database);
	
	if (returnValue == SQLITE_OK) {
		return GDCDATABASE_CLOSE_CONNECTION_OK;
	}else if (returnValue == SQLITE_BUSY){
		return GDCDATABASE_CLOSE_CONNECTION_BUSY;
	}else{
		return GDCDATABASE_CLOSE_CONNECTION_ERROR;
	}
}

// -------------------- end public methods

@end
