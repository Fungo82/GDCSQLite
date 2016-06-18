//
//  ViewController.m
//  GDCTestSQLIte
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//

#import "ViewController.h"
#import <GDCSQLite/GDCSQLite.h>

@interface ViewController ()

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
	GDCDatabase *db = [[GDCDatabase alloc] initWithDatabaseFilename:@"GDCDbTest.sqlite" force:NO completation:^(BOOL error, NSString *errorDescription) {
		
		NSLog(@"Error description: %@",errorDescription);
	}];
	[db openConnection];
	
}

@end
