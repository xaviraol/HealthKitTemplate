//
//  SavingDataViewController.m
//  HealthKitTemplate
//
//  Created by Sense Health on 20/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "SavingDataViewController.h"
#import "HealthKitProvider.h"

@interface SavingDataViewController ()

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;

@property (nonatomic,weak) IBOutlet UITextField *stepsTextfield;
@property (nonatomic,weak) IBOutlet UITextField *distanceTextfield;
@property (nonatomic,weak) IBOutlet UITextField *startDateTextfield;
@property (nonatomic,weak) IBOutlet UITextField *endDateTextfield;

@property (nonatomic,weak) IBOutlet UILabel *feedbackLabel;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation SavingDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    _feedbackLabel.text = @"";
    
    [_segmentedControl addTarget:self
                         action:@selector(changeIndex:)
               forControlEvents:UIControlEventValueChanged];
    [self enableTextFieldsForIndex:_segmentedControl.selectedSegmentIndex];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc]init];
    [datePicker setDate:[NSDate date]];
    [datePicker addTarget:self action:@selector(updateTextField:) forControlEvents:UIControlEventValueChanged];
    [_startDateTextfield setInputView:datePicker];
    [_endDateTextfield setInputView:datePicker];
    
}
- (IBAction)addDateToHealthKit:(id)sender{
    int index = _segmentedControl.selectedSegmentIndex;

    if (index == 0) {
        [self addWalkingData];
    }else if (index == 1){
        [self addCyclingData];
    }else if (index == 2){
        [self addStepsData];
    }else{
        [self addSleepData];
    }
    [self hideKeyboard];
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}

- (void) changeIndex:(id)sender{
    [self enableTextFieldsForIndex:_segmentedControl.selectedSegmentIndex];
    _startDateTextfield.text = @"";
    _endDateTextfield.text = @"";
    _stepsTextfield.text = @"";
    _distanceTextfield.text = @"";
    _feedbackLabel.text = @"";
}

- (void) addWalkingData{
    
    [[HealthKitProvider sharedInstance] writeWalkingRunningDistance:[_distanceTextfield.text doubleValue]
                                                         fromStartDate:[_dateFormatter dateFromString:_startDateTextfield.text]
                                                       toEndDate:[_dateFormatter dateFromString:_endDateTextfield.text]
                                                   withCompletion:^(bool savedSuccessfully, NSError *error) {
                                                       if (savedSuccessfully) {
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               _feedbackLabel.textColor = [UIColor greenColor];
                                                               _feedbackLabel.text = [NSString stringWithFormat:@"Successfully saved!"];
                                                           });
                                                       }else{
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               _feedbackLabel.textColor = [UIColor redColor];
                                                               _feedbackLabel.text = [NSString stringWithFormat:@"Not saved!"];
                                                           });
                                                       }
                                                   }];
    [self hideKeyboard];
}

- (void)addCyclingData{
    [[HealthKitProvider sharedInstance] writeCyclingDistance:[_distanceTextfield.text doubleValue]
                                                  fromStartDate:[_dateFormatter dateFromString:_startDateTextfield.text]
                                                toEndDate:[_dateFormatter dateFromString:_endDateTextfield.text]
                                            withCompletion:^(bool savedSuccessfully, NSError *error) {
                                                if (savedSuccessfully) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        _feedbackLabel.textColor = [UIColor greenColor];
                                                        _feedbackLabel.text = [NSString stringWithFormat:@"Successfully saved!"];
                                                    });
                                                }else{
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        _feedbackLabel.textColor = [UIColor redColor];
                                                        _feedbackLabel.text = [NSString stringWithFormat:@"Not saved!"];
                                                    });
                                                }
                                            }];
    [self hideKeyboard];
}

- (void) addStepsData{
    [[HealthKitProvider sharedInstance] writeSteps:[_stepsTextfield.text doubleValue]
                                        fromStartDate:[_dateFormatter dateFromString:_startDateTextfield.text]
                                      toEndDate:[_dateFormatter dateFromString:_endDateTextfield.text]
                                  withCompletion:^(bool savedSuccessfully, NSError *error) {
                                      if (savedSuccessfully) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              _feedbackLabel.textColor = [UIColor greenColor];
                                              _feedbackLabel.text = [NSString stringWithFormat:@"Successfully saved!"];
                                          });
                                      }else{
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              _feedbackLabel.textColor = [UIColor redColor];
                                              _feedbackLabel.text = [NSString stringWithFormat:@"Not saved!"];
                                          });
                                      }
                                  }];
}

- (void) addSleepData{
    [[HealthKitProvider sharedInstance] writeSleepAnalysisFromStartDate:[_dateFormatter dateFromString:_startDateTextfield.text]
                                                   toEndDate:[_dateFormatter dateFromString:_endDateTextfield.text]
                                              withCompletion:^(bool savedSuccessfully, NSError *error) {
                                                  if (savedSuccessfully) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          _feedbackLabel.textColor = [UIColor greenColor];
                                                          _feedbackLabel.text = [NSString stringWithFormat:@"Successfully saved!"];
                                                      });
                                                  }else{
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          _feedbackLabel.textColor = [UIColor redColor];
                                                          _feedbackLabel.text = [NSString stringWithFormat:@"Not saved!"];
                                                      });
                                                  }
                                              }];
}

#pragma mark - UI refresh methods.

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
    
    [_distanceTextfield resignFirstResponder];
    [_startDateTextfield resignFirstResponder];
    [_endDateTextfield resignFirstResponder];
    [_stepsTextfield resignFirstResponder];

}

- (void) enableTextFieldsForIndex:(int)index{
    if (index==0) {
        _stepsTextfield.enabled = NO;
        _distanceTextfield.enabled = YES;
        _startDateTextfield.enabled = YES;
        _endDateTextfield.enabled = YES;
    }else if (index==1){
        _stepsTextfield.enabled = NO;
        _distanceTextfield.enabled = YES;
        _startDateTextfield.enabled = YES;
        _endDateTextfield.enabled = YES;
    }else if (index==2){
        _stepsTextfield.enabled = YES;
        _distanceTextfield.enabled = NO;
        _startDateTextfield.enabled = YES;
        _endDateTextfield.enabled = YES;
    }else{
        _stepsTextfield.enabled = NO;
        _distanceTextfield.enabled = NO;
        _startDateTextfield.enabled = YES;
        _endDateTextfield.enabled = YES;
    }

}

@end
