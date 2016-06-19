//
//  ViewController.h
//  GDCTestSQLIte
//
//  Created by Germano Dario Carlino on 18/06/16.
//  Copyright © 2016 GDC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TestInterface.h"

@interface ViewController : UIViewController

// ###### PROPERTY ######

// --- Command UI ---
@property (weak, nonatomic) IBOutlet UILabel *commandLabel;
@property (weak, nonatomic) IBOutlet UIView *commantContentView;
@property (weak, nonatomic) IBOutlet UIButton *commandOpenConnButton;
@property (weak, nonatomic) IBOutlet UIButton *commandCloseConnButton;
@property (weak, nonatomic) IBOutlet UIButton *commandResetButton;

// ------------------- end command UI

// --- Query UI ---

@property (weak, nonatomic) IBOutlet UIView *queryContentView;
@property (weak, nonatomic) IBOutlet UITextField *queryTextField;
@property (weak, nonatomic) IBOutlet UIButton *queryRunButton;

// -------------------- end query UI

// --- Result UI ---

@property (weak, nonatomic) IBOutlet UIView *resultContentView;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (weak, nonatomic) IBOutlet UIButton *resultClearButton;

// -------------------- end result UI

// --- Result UI ---

@property (weak, nonatomic) IBOutlet UIView *logContentView;
@property (weak, nonatomic) IBOutlet UILabel *logTextLabel;


// -------------------- end result UI

// #######################

// ###### ACTION ######

- (IBAction)commandOpenConnAction:(id)sender;
- (IBAction)commandCloseConnAction:(id)sender;
- (IBAction)commandResetAction:(id)sender;

- (IBAction)queryRunAction:(id)sender;

- (IBAction)resultClearAction:(id)sender;

// #######################

@end

