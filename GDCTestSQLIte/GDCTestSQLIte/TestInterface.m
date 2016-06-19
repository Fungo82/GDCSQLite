//
//  TestInterface.m
//  GDCTestSQLIte
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//

#import "TestInterface.h"
#import "Person.h"

@interface TestInterface()

@end

@implementation TestInterface

#pragma mark - PUBLIC METHODS
// ###### PUBLIC METHODS ######

+ (void)initDb:(void (^)(GDCDatabase *, BOOL, NSString *))dbInstance{
	
	GDCDatabase *db = [GDCDatabase alloc];
	
	[db initWithDatabaseFilename:@"GDCDbTest.sqlite" force:YES completation:^(BOOL error, NSString *errorDescription) {

		dbInstance(db,error,errorDescription);
	}];

}

+ (NSString *)openDb:(GDCDatabase *)db{
	return [db openConnection];
}

+ (NSString *)closeDb:(GDCDatabase *)db{
	return [db closeConnection];
}

+ (NSArray *)selectDataFromTable:(NSString *)table andWhere:(NSString *)where fromDb:(GDCDatabase *)database{
	
	if (table == nil || table.length == 0) {
		return @[];
	}
	
	NSMutableString *mutableQuery = [[NSMutableString alloc] init];
	
	NSString *select = @"SELECT * FROM ";
	
	[mutableQuery appendString:select];
	[mutableQuery appendString:table];
	
	if (where && where.length > 0) {
		[mutableQuery appendString:where];
	}
	
	return [database loadQuery:mutableQuery];
	
}

+ (NSArray *)runQuery:(NSString *)query isSelect:(BOOL)isSelect fromDb:(GDCDatabase *)database{
	
	if (isSelect) {
		return [database loadQuery:query];
	}else{
		return [database executeQuery:query];
	}
}


+ (void)logSelectArrayResult:(NSArray *)result{
	
	
	
	for (NSArray *row in result) {
		
		NSArray *attributes = row[0];
		NSArray *values		= row[1];
		
		NSUInteger count = attributes.count;
		NSLog(@"#################################");
		for (NSUInteger i = 0; i < count; i++) {
			
			
			NSLog(@"Attribute: %@ --> Value: %@",attributes[i],values[i]);
			
		}
		NSLog(@"#################################");
	}

}

+ (void)insertTestPersonInto:(GDCDatabase *)db progress:(callProgressCallback)progress{
	
	// This test in only for example, code isn't optimizated
	
	Person *person1 = [[Person alloc] init];
	person1.name	= @"Name1";
	person1.surname	= @"Surname1";
	person1.age		= 34;
	
	Person *person2 = [[Person alloc] init];
	person2.name	= @"Name2";
	person2.surname	= @"Surname2";
	person2.age		= 32;
	
	Person *person3 = [[Person alloc] init];
	person3.name	= @"Name3";
	person3.surname	= @"Surname3";
	person3.age		= 28;
	
	Person *person4 = [[Person alloc] init];
	person4.name	= @"Name4";
	person4.surname	= @"Surname4";
	person4.age		= 36;
	
	NSArray *tempArray = @[person1,person2,person3,person4];
	
	for (Person *row in tempArray) {
		NSString *query = [NSString stringWithFormat:@"INSERT INTO Person (name,surname,age) values ('%@','%@',%li)",row.name,row.surname,(long)row.age];
		NSArray *temp =[db executeQuery:query];
		progress([NSString stringWithFormat:@"Num. Rec.:%@ - Rec. Id: %@ -- Error :%@",temp[0],temp[1],temp[2]]);
	}
	
}
// #####################

#pragma mark - PRIVATE METHODS
// ###### PRIVATE METHODS ######



// #####################

@end
