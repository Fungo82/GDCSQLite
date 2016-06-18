//
//  GDCDatabase.m
//  GDCSQLite
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//
#import <sqlite3.h>
#import "GDCDatabase.h"

/* --- DEBUG --- */
#define DEBUG_SQLMANAGER		@"FALSE" // VERIFICARE SE UTILIZZATA
#define DEBUG_DBMANAGER			@"FALSE"
#define DEBUG_DB_ERROR_MANAGER	@"FALSE"
#define DEBUG_DB_STACK			@"FALSE"

/* ------------- */

@interface GDCDatabase(){
// Create a sqlite object.
sqlite3 *sqlite3Database;

// Set the database file path.
NSString *databasePath;

// Open the database
BOOL openDatabaseResult;

// Load Stack
NSMutableArray *loadStack;
NSInteger indexLoadStack;

// Execute Stack
NSMutableArray *executeStack;
NSInteger indexExecuteStack;
}

/**
 * Check if db exist in Document path, otherwise copy the db in Document
 *
 * @author Germano Dario Carlino
 *
 * @param dbFilename The name of DataBase
 *
 */
-(void)copyDatabaseIntoDocumentsDirectory:(callCompletationCallback)completation;

/**
 * Run a query in two differnt mode in function of the type of query
 *
 * @author Germano Dario Carlino
 *
 * @param query The query to execute
 * @param queryExecutable To inform the method if is a executable query like insert, update, delete
 *
 */
-(void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable;

- (void)pushLoadStack:(NSString *)query;

- (void)popLoadStack;

- (void)pushExecuteStack:(NSString *)query;

- (void)popExecuteStack;

- (void)cleanLoadStack;

- (void)cleanExecuteStack;

@end

@implementation GDCDatabase

#pragma mark - INIT
-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename force:(BOOL)force completation:(callCompletationCallback)completationo{
	self = [super init];
	if (self) {
		
		loadStack = [[NSMutableArray alloc] init];
		indexLoadStack = 0;
		
		executeStack = [[NSMutableArray alloc] init];
		indexExecuteStack = 0;
		
		// Set the documents directory path to the documentsDirectory property.
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		self.documentsDirectory = [paths objectAtIndex:0];
		
		// Keep the database filename.
		self.databaseFilename = dbFilename;
		//self.databaseFilename1 = @"barilla.sqlite";
		
		// Copy the database file into the documents directory if necessary.
		if (force) {
			NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
			NSError *error;
			if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
				[[NSFileManager defaultManager] removeItemAtPath:destinationPath error:&error];
				if (error != nil) {
					NSLog(@"Remove db error %@", [error localizedDescription]);
					completationo(YES,[NSString stringWithFormat:@"Remove db error: %@",[error localizedDescription]]);
				}else{
					NSLog(@"Remove db OK");
					completationo(NO,@"");
				}
			}
			NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
			
			[[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
			
			// Check if any error occurred during copying and display it.
			if (error != nil) {
				NSLog(@"Copy db error %@", [error localizedDescription]);
				completationo(YES,[NSString stringWithFormat:@"Copy db error: %@",[error localizedDescription]]);
			}else{
				NSLog(@"Copy database OK");
				completationo(NO,@"");
			}
		}else{
			[self copyDatabaseIntoDocumentsDirectory:^(BOOL error, NSString *errorDescription) {
				completationo(error,errorDescription);
			}];
		}
		
		
	}
	return self;
}


#pragma mark - METHODS
/* --- METHODS --- */

#pragma mark - PRIVATE METHODS
// PRIVATE
-(void)copyDatabaseIntoDocumentsDirectory:(callCompletationCallback)completation{
	
	// Check if the database file exists in the documents directory.
	NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
	if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
		// The database file does not exist in the documents directory, so copy it from the main bundle now.
		NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
		NSError *error;
		[[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
		
		// Check if any error occurred during copying and display it.
		if (error != nil) {
			NSLog(@"%@", [error localizedDescription]);
		}else{
			NSLog(@"Copy database OK");
		}
	}
	
}

-(void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable{
	
	
	if ([DEBUG_DBMANAGER isEqualToString:@"TRUE"]) {
		NSLog(@"QUERY: %s",query);
	}
	
	
	// Initialize the results array.
	if (self.arrResults != nil) {
		[self.arrResults removeAllObjects];
		self.arrResults = nil;
	}
	self.arrResults = [[NSMutableArray alloc] init];
	
	// Initialize the column names array.
	if (self.arrColumnNames != nil) {
		[self.arrColumnNames removeAllObjects];
		self.arrColumnNames = nil;
	}
	self.arrColumnNames = [[NSMutableArray alloc] init];
	
	if(openDatabaseResult == SQLITE_OK) {
		
		// Declare a sqlite3_stmt object in which will be stored the query after having been compiled into a SQLite statement.
		sqlite3_stmt *compiledStatement;
		
		if (queryExecutable) {
			//sqlite3_exec(sqlite3Database,"BEGIN", 0, 0, 0);
		}
		
		// Load all data from database to memory.
		BOOL prepareStatementResult = sqlite3_prepare_v2(sqlite3Database, query, -1, &compiledStatement, NULL);
		
		if(prepareStatementResult == SQLITE_OK) {
			
			// Check if the query is non-executable.
			if (!queryExecutable){
				// In this case data must be loaded from the database.
				
				// Declare an array to keep the data for each fetched row.
				NSMutableArray *arrDataRow;
				
				// Loop through the results and add them to the results array row by row.
				while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
					// Initialize the mutable array that will contain the data of a fetched row.
					arrDataRow = [[NSMutableArray alloc] init];
					
					// Get the total number of columns.
					int totalColumns = sqlite3_column_count(compiledStatement);
					
					// Go through all columns and fetch each column data.
					for (int i=0; i<totalColumns; i++){
						// Convert the column data to text (characters).
						char *dbDataAsChars = (char *)sqlite3_column_text(compiledStatement, i);
						
						// If there are contents in the currenct column (field) then add them to the current row array.
						if (dbDataAsChars != NULL) {
							// Convert the characters to string.
							[arrDataRow addObject:[NSString  stringWithUTF8String:dbDataAsChars]];
						}else{
							// If parameter is null
							[arrDataRow addObject:[NSString  stringWithUTF8String:"null"]];
						}
						
						// Keep the current column name.
						if (self.arrColumnNames.count != totalColumns) {
							dbDataAsChars = (char *)sqlite3_column_name(compiledStatement, i);
							[self.arrColumnNames addObject:[NSString stringWithUTF8String:dbDataAsChars]];
						}
					}
					
					// Store each fetched data row in the results array, but first check if there is actually data.
					if (arrDataRow.count > 0) {
						[self.arrResults addObject:arrDataRow];
					}
					
					
				}
				
				sqlite3_reset(compiledStatement);
				compiledStatement = nil;
			}
			else {
				// This is the case of an executable query (insert, update, ...).
				
				// Execute the query.
				//BOOL executeQueryResults = sqlite3_step(compiledStatement);
				if (sqlite3_step(compiledStatement) == SQLITE_DONE) {
					
					//sqlite3_exec(sqlite3Database, "COMMIT", 0, 0, 0);
					
					// Keep the affected rows.
					self.affectedRows = sqlite3_changes(sqlite3Database);
					
					// Keep the last inserted row ID.
					self.lastInsertedRowID = sqlite3_last_insert_rowid(sqlite3Database);
				}
				else {
					// If could not execute the query show the error message on the debugger.
					if ([DEBUG_DB_ERROR_MANAGER isEqualToString:@"TRUE"]) {
						NSLog(@"DB Error: %s - Query: %s", sqlite3_errmsg(sqlite3Database),query);
					}
				}
			}
		}
		else {
			// In the database cannot be opened then show the error message on the debugger.
			if ([DEBUG_DB_ERROR_MANAGER isEqualToString:@"TRUE"]) {
				NSLog(@"DB not opened %s", sqlite3_errmsg(sqlite3Database));
			}
		}
		
		// Release the compiled statement from memory.
		sqlite3_finalize(compiledStatement);
		
	}
	
	if (queryExecutable) {
		[self popExecuteStack];
	}else{
		[self popLoadStack];
	}
	
}

- (void)unzipMap:(NSString *)nomeFile{
	/*
	 //NSString *tilesPath = [self.documentsDirectory stringByAppendingPathComponent:@"tiles"];
	 //dispatch_queue_t backgroundQueue = dispatch_queue_create("com.moko.it", 0);
	 
	 dispatch_async(dispatch_get_main_queue(), ^{
	 //[self.titoloText setText:[NSString stringWithFormat:@"Current map: %@",nomeFile]];
	 
	 NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@",nomeFile]];
	 
	 NSError *errorMap;
	 ZZArchive* zipArchive = [ZZArchive archiveWithURL:URL error:&errorMap];
	 
	 //[self.titoloText setText : @"Make folder: ..."];
	 // Cicle to make folder structure
	 unsigned long countFolder= zipArchive.entries.count;
	 for(unsigned long i=0;i < countFolder; i++){
	 
	 ZZArchiveEntry *archiveEntry = zipArchive.entries[i];
	 NSString *entryName = archiveEntry.fileName;
	 NSString *lastCharacterName = [entryName substringFromIndex:entryName.length - 1];
	 
	 if([lastCharacterName isEqualToString:@"/"]){
	 //NSData *zipDataRow = [archiveEntry newDataWithError:nil];
	 NSString *folderRow = [self.documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",archiveEntry.fileName]];
	 [[NSFileManager defaultManager] createDirectoryAtPath:folderRow withIntermediateDirectories:YES attributes:nil error:nil];
	 
	 }
	 
	 
	 }
	 
	 // Cicle to save file
	 unsigned long countFile = zipArchive.entries.count;
	 for(unsigned long i=0;i < countFile; i++){
	 ZZArchiveEntry *archiveEntry = zipArchive.entries[i];
	 NSString *entryName = archiveEntry.fileName;
	 NSString *lastCharacterName = [entryName substringFromIndex:entryName.length - 1];
	 if(!([lastCharacterName isEqualToString:@"/"])){
	 
	 //NSString *zipRowPath = [NSString stringWithFormat:@"%@",entryName];
	 NSString *zipRowPath = [NSString stringWithFormat:@"%@/%@",self.documentsDirectory,entryName];
	 
	 NSData *zipDataRow = [archiveEntry newDataWithError:nil];
	 [zipDataRow writeToFile:zipRowPath atomically:NO];
	 
	 }
	 
	 }
	 
	 });
	 */
}


#pragma mark - PUBLIC METHODS
// PUBLIC
#warning Inserire stack per loadQuery
-(NSArray *)loadDataFromDB:(NSString *)query{
	// Run the query and indicate that is not executable.
	// The query string is converted to a char* object.
	[self runQuery:[query UTF8String] isQueryExecutable:NO];
	/*
	 [self pushLoadStack:query];
	 if (indexLoadStack == 1) {
	 [self popLoadStack];
	 }
	 */
	// Returned the loaded results.
	return (NSArray *)self.arrResults;
}

-(void)executeQuery:(NSString *)query{
	// Run the query and indicate that is executable.
	//[self runQuery:[query UTF8String] isQueryExecutable:YES];
	[self pushExecuteStack:query];
	if (indexExecuteStack == 1) {
		[self popExecuteStack];
	}
}

- (void)openConnection{
	
	databasePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
	
	openDatabaseResult = sqlite3_open([databasePath UTF8String], &sqlite3Database);
}

- (void)closeConnection{
	
	// Close the database.
	sqlite3_close(sqlite3Database);
}

- (void)pushLoadStack:(NSString *)query{
	[loadStack addObject:query];
	indexLoadStack += 1;
}

- (void)popLoadStack{
	
	if ([DEBUG_DB_STACK isEqualToString:@"TRUE"]) {
		NSLog(@"LOAD STACK: %@ --- INDEX: %li",loadStack,(long)indexLoadStack);
	}
	
	if (indexLoadStack > 0) {
		NSString *query = loadStack[indexLoadStack - 1];
		indexLoadStack -= 1;
		[self runQuery:[query UTF8String] isQueryExecutable:NO];
	}
}

- (void)pushExecuteStack:(NSString *)query{
	[executeStack addObject:query];
	indexExecuteStack += 1;
}

- (void)popExecuteStack{
	if (indexExecuteStack > 0) {
		NSString *query = executeStack[indexExecuteStack - 1];
		indexExecuteStack -= 1;
		[executeStack removeObjectAtIndex:executeStack.count-1];
		[self runQuery:[query UTF8String] isQueryExecutable:YES];
	}
}

- (void)cleanLoadStack{
	[loadStack removeAllObjects];
	indexLoadStack = 0;
}

- (void)cleanExecuteStack{
	[executeStack removeAllObjects];
	indexExecuteStack = 0;
}


@end
