//
//  ActivityViewController.m
//  HealthKitTemplate
//
//  Created by Xavier Ramos Oliver on 20/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "ActivityViewController.h"
#import "HealthKitManager.h"


@interface ActivityViewController ()

@property (nonatomic,strong) NSDate *twoDaysAgo;
@property (nonatomic,strong) NSDate *yesterday;
@property (nonatomic,strong) NSDate *today;
@property (nonatomic,strong) NSDate *tomorrow;
@property (nonatomic,strong) NSDate *pastTomorrow;

@end

@implementation ActivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _twoDaysAgo = [[NSDate date] dateByAddingTimeInterval:-172800];
    _yesterday = [[NSDate date] dateByAddingTimeInterval:-86400];
    _today = [NSDate date];
    _tomorrow = [[NSDate date] dateByAddingTimeInterval:86400];
    _pastTomorrow = [[NSDate date] dateByAddingTimeInterval:172800];
}

- (IBAction)getActivityTime:(id)sender{
    [[HealthKitManager sharedManager] getActivityTimeFromHealthkit];
    HKQuantityType *exerciseMinutesType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleExerciseTime];
    [[HealthKitManager sharedManager] getQuantativeDataFromTodayForType:exerciseMinutesType unit:[HKUnit minuteUnit] completion:^(double value, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"minutes: %@",[NSString stringWithFormat:@"%1.0f mins", value]);
        });
    }];
}

- (IBAction)writeWalkingRunningDistance:(id)sender{
    [[HealthKitManager sharedManager] writeWalkingRunningDistanceFromDate:_yesterday andEndDate:_today];
}

- (IBAction)getActiveSummaries:(id)sender{
    [[HealthKitManager sharedManager] getActivitySumaries];
}

@end
