//
//  ViewController.m
//  GDCTestSQLIte
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
	GDCDatabase *localDB;
}

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	
	// TEST GDCSQLite.framework
	
	 [TestInterface initDb:^(GDCDatabase *db, BOOL error, NSString *errorMessage) {
		
		 if (!error) {
			 
			 localDB = db;
			 localDB.DEBUG_DBMANAGER		= YES;
			 localDB.DEBUG_SQLMANAGER	= YES;
			 
		 }else{
			 
			 [self writeLog:errorMessage];
			
		 }
		//[self insertTestValue];
	}];
	
}

// ###### PRIVATE METHODS ######

- (void)insertTestValue{
	
	[TestInterface insertTestPersonInto:localDB progress:^(NSString *progress) {
		dispatch_async(dispatch_get_main_queue(), ^{
			_logTextLabel.text = progress;
		});
	}];
	
}

- (void)selectAllValue{
	NSArray *resultArray = [TestInterface selectDataFromTable:@"Person" andWhere:nil fromDb:localDB];
	
	[TestInterface logSelectArrayResult:resultArray];
}

- (void)writeLog:(NSString *)text{
	_logTextLabel.text = text;
}

// #############################


// ###### ACTION ######
- (IBAction)commandOpenConnAction:(id)sender {
	_logTextLabel.text = [TestInterface openDb:localDB];
}

- (IBAction)commandCloseConnAction:(id)sender {
	_logTextLabel.text = [TestInterface closeDb:localDB];
}

- (IBAction)commandResetAction:(id)sender {
	
	NSString *queryClear		= @"DELETE FROM Person";
	NSString *queryClearSqlite	= @"DELETE FROM sqlite_sequence WHERE name='Person'";
	
	NSArray *temp;
	
	temp = [TestInterface runQuery:queryClear isSelect:NO fromDb:localDB];
	NSNumber *number = temp[2];
	_logTextLabel.text = [NSString stringWithFormat:@"%@",number];
	
	temp = [TestInterface runQuery:queryClearSqlite isSelect:NO fromDb:localDB];
	_logTextLabel.text = [NSString stringWithFormat:@"%@",temp[2]];
	
	[self insertTestValue];
}

- (IBAction)queryRunAction:(id)sender {
	
	_logTextLabel.text = @"";
	// GET QUERY
	NSString *queryString = _queryTextField.text;
	
	if (queryString.length < 5) {
		_logTextLabel.text = @"Query not valid";
		return;
	}
	
	NSArray *resultArray;
	
	if ([queryString.uppercaseString rangeOfString:@"SELECT"].location == NSNotFound) {
		resultArray	= [TestInterface runQuery:queryString isSelect:NO fromDb:localDB];
		
		_logTextLabel.text = [NSString stringWithFormat:@"Affected: %@ with error: %@",resultArray[0],resultArray[2]];
	} else {
		resultArray	= [TestInterface runQuery:queryString isSelect:YES fromDb:localDB];
		
		NSString *tempString = @"";
		
		
		NSArray *dataArray		= resultArray[0];
		NSString *errorMessage	= resultArray[1];
		
		if (errorMessage && errorMessage.length > 0) {
			_logTextLabel.text = errorMessage;
			return;
		}
		
		for (NSArray *row in dataArray) {
			
			NSArray *attributes = row[0];
			NSArray *values		= row[1];
			
			NSUInteger count = attributes.count;
			
			tempString = [NSString stringWithFormat:@"%@\n%@\n",_resultTextView.text,@"- - - - - - - - - - - - - - "];
			_resultTextView.text = tempString;
			
			for (NSUInteger i = 0; i < count; i++) {
				
				tempString = [NSString stringWithFormat:@"%@\n %@ --> %@\n",_resultTextView.text,attributes[i],values[i]];
				_resultTextView.text = tempString;
				
				
			}
			tempString = [NSString stringWithFormat:@"%@\n%@\n",_resultTextView.text,@"- - - - - - - - - - - - - - "];
			_resultTextView.text = tempString;
		}
	}
	
}

- (IBAction)resultClearAction:(id)sender {
	_resultTextView.text = @"";
}

// ####################

@end
