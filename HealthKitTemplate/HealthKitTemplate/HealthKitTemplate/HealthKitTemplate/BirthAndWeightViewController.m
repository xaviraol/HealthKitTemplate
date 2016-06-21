//
//  BirthAndWeightViewController.m
//  HealthKitTemplate
//
//  Created by Xavier Ramos Oliver on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "BirthAndWeightViewController.h"
#import "HealthKitManager.h"

@interface BirthAndWeightViewController ()

@property (nonatomic,weak) IBOutlet UILabel *ageLabel;
@property (nonatomic,weak) IBOutlet UITextField *weightTextField;

@end

@implementation BirthAndWeightViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) healthIntegrationButtonSwitched:(UISwitch*)sender {
    
    if (sender.isOn) {
        [[HealthKitManager sharedManager]requestAuthorization];
    }else{
        //disable HealthKit
    }
}


- (IBAction)readAgeButtonPressed:(id)sender{
    NSDate *birthDate = [[HealthKitManager sharedManager] readBirthDate];
    if (birthDate == nil) {
        return;
    }
    NSDateComponents *ageComponents = [[NSCalendar currentCalendar]
                                       components:NSCalendarUnitYear
                                       fromDate:birthDate
                                       toDate:[NSDate date]
                                       options:0];
    
    self.ageLabel.text = [@(ageComponents.year) stringValue];
}

- (IBAction)writeWeightButtonPressed:(id)sender {
    [self.weightTextField resignFirstResponder];
    [[HealthKitManager sharedManager] writeWeightSample:self.weightTextField.text.floatValue];
}
@end
