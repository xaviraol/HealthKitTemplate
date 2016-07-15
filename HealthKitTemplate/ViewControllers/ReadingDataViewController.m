//
//  ReadingDataViewController.m
//  HealthKitTemplate
//
//  Created by Sense Health on 20/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "ReadingDataViewController.h"
#import "HealthKitProvider.h"

static int kSECONDS_IN_HOUR = 3600;
@interface ReadingDataViewController ()

@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;

@property (nonatomic,weak) IBOutlet UITextField *startDateTextfield;
@property (nonatomic,weak) IBOutlet UITextField *endDateTextfield;

@property (nonatomic,weak) IBOutlet UILabel *resultsFirstLabel;
@property (nonatomic,weak) IBOutlet UILabel *resultsSecondLabel;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;


@end

@implementation ReadingDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    _resultsFirstLabel.text = @"";
    _resultsSecondLabel.text = @"";
    
    [_segmentedControl addTarget:self
                          action:@selector(changeIndex:)
                forControlEvents:UIControlEventValueChanged];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc]init];
    [datePicker setDate:[NSDate date]];
    [datePicker addTarget:self action:@selector(updateTextField:) forControlEvents:UIControlEventValueChanged];
    [_startDateTextfield setInputView:datePicker];
    [_endDateTextfield setInputView:datePicker];
}

- (IBAction)readDataFromHealthKit:(id)sender{
    [self hideKeyboard];

    int index = (int)_segmentedControl.selectedSegmentIndex;
    if (index == 0) {
        [self readWalkingData];
    }else if (index == 1){
        [self readCyclingData];
    }else if (index == 2){
        [self readStepsData];
    }else{
        [self readSleepData];
    }
    
}
- (void) readWalkingData{
    HKSampleType *walkingSample = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    
    [[HealthKitProvider sharedInstance] readWalkingTimeActiveFromDate:[_dateFormatter dateFromString:_startDateTextfield.text] toDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(NSTimeInterval timeActive, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsFirstLabel.text = [NSString stringWithFormat:@"You've been walking for %.2f h.", timeActive / kSECONDS_IN_HOUR];
            });
        } else {
            NSLog(@"Error retrieving timeActive data: %@", error.localizedDescription);
        }
    }];

    [[HealthKitProvider sharedInstance] readCoveredDistanceForSampleType:walkingSample fromStartDate:[_dateFormatter dateFromString:_startDateTextfield.text] toEndDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(double totalDistance, NSArray *listOfSpeed, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsSecondLabel.text = [NSString stringWithFormat:@"You've walked %.2f km", totalDistance];
            });
        } else {
            NSLog(@"Error retrieving distance data: %@", error.localizedDescription);
        }
    }];
}

-(void) readCyclingData{
    HKSampleType *cyclingSample = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];

    [[HealthKitProvider sharedInstance] readCyclingTimeActiveFromStartDate:[_dateFormatter dateFromString:_startDateTextfield.text] toEndDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(NSTimeInterval timeInterval, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsFirstLabel.text = [NSString stringWithFormat:@"You've been cycling for %.2f h.", timeInterval / kSECONDS_IN_HOUR];
            });
        } else {
            NSLog(@"Error retrieving data: %@", error.localizedDescription);
        }
    }];
    
    [[HealthKitProvider sharedInstance] readCoveredDistanceForSampleType:cyclingSample fromStartDate:[_dateFormatter dateFromString:_startDateTextfield.text] toEndDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(double totalDistance, NSArray *listOfSpeed, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsSecondLabel.text = [NSString stringWithFormat:@"You've cycled %.2f km", totalDistance];
            });
        } else {
            NSLog(@"Error retrieving distance data: %@", error.localizedDescription);
        }
    }];
}

- (void) readStepsData{
    [[HealthKitProvider sharedInstance] readCumulativeStepsFrom:[_dateFormatter dateFromString:_startDateTextfield.text] toDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(int steps, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsFirstLabel.text = [NSString stringWithFormat:@"You did %d steps.",steps];
            });
        } else {
            NSLog(@"Error retrieving sleep data: %@", error.localizedDescription);
        }
    }];
    
    [[HealthKitProvider sharedInstance] readStepsTimeActiveFromDate:[_dateFormatter dateFromString:_startDateTextfield.text] toDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(NSTimeInterval timeInterval, NSInteger totalSteps, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsSecondLabel.text = [NSString stringWithFormat:@"You've been walking for %.2f minutes.", timeInterval / kSECONDS_IN_HOUR];
            });
        } else {
            NSLog(@"Error retrieving sleep data: %@", error.localizedDescription);
        }
    }];
}

- (void) readSleepData{
    [[HealthKitProvider sharedInstance] readSleepAnalysisFromStartDate:[_dateFormatter dateFromString:_startDateTextfield.text] toEndDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(NSTimeInterval sleepTime, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsFirstLabel.text = [NSString stringWithFormat:@"You slept for %.2f h.", sleepTime / kSECONDS_IN_HOUR];
            });
        } else {
            NSLog(@"Error retrieving sleep data: %@", error.localizedDescription);
        }
    }];
}


#pragma mark - UI Helper methods.

- (void)updateTextField:(id)sender{
    UITextField *textField = sender;
    UIDatePicker *picker = (UIDatePicker*)textField.inputView;
    NSDate *pickerDate = picker.date;
    if ([_startDateTextfield isFirstResponder]) {
        _startDateTextfield.text = [NSString stringWithFormat:@"%@",[_dateFormatter stringFromDate:pickerDate]];
    }else if ([_endDateTextfield isFirstResponder]){
        _endDateTextfield.text = [NSString stringWithFormat:@"%@",[_dateFormatter stringFromDate:pickerDate]];
    }
}
-(void)hideKeyboard{
    [_startDateTextfield resignFirstResponder];
    [_endDateTextfield resignFirstResponder];
}

-(void)changeIndex:(id)sender{
    _startDateTextfield.text = @"";
    _endDateTextfield.text = @"";
    _resultsFirstLabel.text = @"";
    _resultsSecondLabel.text = @"";
}

@end
