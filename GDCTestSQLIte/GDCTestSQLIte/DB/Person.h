//
//  Person.h
//  GDCTestSQLIte
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (nonatomic) NSInteger idTable;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *surname;
@property (nonatomic) NSInteger age;

@end
