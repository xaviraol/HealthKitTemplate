//
//  ReadingDataViewController.m
//  HealthKitTemplate
//
//  Created by Sense Health on 20/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "ReadingDataViewController.h"
#import "HealthKitProvider.h"
#import "SleepDataProvider.h"

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
    [self dateFormatEditor];
    _resultsFirstLabel.text = @"";
    _resultsSecondLabel.text = @"";
    

    
    [_segmentedControl addTarget:self
                          action:@selector(changeIndex:)
                forControlEvents:UIControlEventValueChanged];
}

- (void) viewDidAppear:(BOOL)animated{
    _startDateTextfield.text = @"2016-08-15 12:45:01";
    _endDateTextfield.text = @"2016-08-16 23:59:59";
    
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
    [[HealthKitProvider sharedInstance] readWalkingTimeActiveFromDate:[_dateFormatter dateFromString:_startDateTextfield.text] toDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(NSTimeInterval timeActive, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsFirstLabel.text = [NSString stringWithFormat:@"You've been walking for %.0f h.", timeActive / kSECONDS_IN_HOUR];
            });
        } else {
            NSLog(@"Error retrieving timeActive data: %@", error.localizedDescription);
        }
    }];
    [[HealthKitProvider sharedInstance] readCoveredWalkingDistanceFromDate:[_dateFormatter dateFromString:_startDateTextfield.text] toDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(double totalDistance, NSArray *listOfSpeed, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsSecondLabel.text = [NSString stringWithFormat:@"You've walked %.0f km", totalDistance];
            });
        } else {
            NSLog(@"Error retrieving distance data: %@", error.localizedDescription);
        }
    }];
}

-(void) readCyclingData{
    [[HealthKitProvider sharedInstance] readCyclingTimeActiveFromDate:[_dateFormatter dateFromString:_startDateTextfield.text] toDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(NSTimeInterval timeInterval, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsFirstLabel.text = [NSString stringWithFormat:@"You've been cycling for %.2f h.", timeInterval / 60];
            });
        } else {
            NSLog(@"Error retrieving data: %@", error.localizedDescription);
        }
    }];
    
    [[HealthKitProvider sharedInstance] readCoveredCyclingDistanceFromDate:[_dateFormatter dateFromString:_startDateTextfield.text] toDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(double totalDistance, NSArray *listOfSpeed, NSError *error) {
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
                _resultsFirstLabel.text = [NSString stringWithFormat:@"Total steps: %d steps.",steps];
            });
        } else {
            NSLog(@"Error retrieving sleep data: %@", error.localizedDescription);
        }
    }];
    
    [[HealthKitProvider sharedInstance] readStepsTimeActiveFromDate:[_dateFormatter dateFromString:_startDateTextfield.text] toDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(NSTimeInterval timeInterval, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultsSecondLabel.text = [NSString stringWithFormat:@"You've been walking for %.0f min.", timeInterval / 60];
            });
        } else {
            NSLog(@"Error retrieving sleep data: %@", error.localizedDescription);
        }
    }];
}

- (void) readSleepData{
    
    //Read ended sleep for a day:
//    [[SleepDataProvider sharedInstance] readEndedSleepForDay:[_dateFormatter dateFromString:_startDateTextfield.text] withCompletion:^(NSArray *sleepDataPoints, NSTimeInterval totalSleepTime, NSTimeInterval totalBedTime) {
//        NSLog(@"[readEndedSleepForDay] SleepDataPoints: %@",sleepDataPoints);
//        NSLog(@"[readEndedSleepForDay] TotalSleepTime: %f",totalSleepTime);
//        NSLog(@"[readEndedSleepForDay] TotalBedTime: %f",totalBedTime);
//
//    }];

    
//    //Read real sleep for a day:
//    [[SleepDataProvider sharedInstance] readRealSleepForDay:[_dateFormatter dateFromString:_startDateTextfield.text] withCompletion:^(NSArray *sleepDataPoints, NSTimeInterval totalSleepTime, NSTimeInterval totalBedTime) {
//        NSLog(@"[readRealSleepForDay] SleepDataPoints: %@",sleepDataPoints);
//        NSLog(@"[readRealSleepForDay] TotalSleepTime: %f",totalSleepTime);
//        NSLog(@"[readRealSleepForDay] TotalBedTime: %f",totalBedTime);
//    }];
    
    
//    [[SleepDataProvider sharedInstance] readEndedSleepBetweenDate:[_dateFormatter dateFromString:_startDateTextfield.text] andDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(NSArray *sleepDataPoints, NSTimeInterval sleepTime, NSTimeInterval bedTime, NSError *error) {
//        NSLog(@"[readRealSleepForDay] SleepDataPoints: %@",sleepDataPoints);
//        NSLog(@"[readRealSleepForDay] TotalSleepTime: %f",sleepTime);
//        NSLog(@"[readRealSleepForDay] TotalBedTime: %f",bedTime);
//    }];
    
    //Read ended and real data since a given date:
    NSDate *lastSavedDate = [_dateFormatter dateFromString:@"2016-08-15 00:00:01"];
    NSArray *datesBetween = [self daysBetweenDate:lastSavedDate toDate:[NSDate date]];
    for (int i = 0; i < [datesBetween count]; i++) {
        NSDate *date = [datesBetween objectAtIndex:i];
//        [[SleepDataProvider sharedInstance] readEndedSleepForDay:date withCompletion:^(NSArray *sleepDataPoints, NSTimeInterval totalSleepTime, NSTimeInterval totalBedTime) {
//            NSLog(@"[readEndedSleepForDay: %@] SleepDataPoints: %@",date, sleepDataPoints);
//            NSLog(@"[readEndedSleepForDay: %@] TotalSleepTime: %f",date, totalSleepTime);
//            NSLog(@"[readEndedSleepForDay: %@] TotalBedTime: %f\n",date, totalBedTime);
//        }];
        [[SleepDataProvider sharedInstance] readRealSleepForDay:date withCompletion:^(NSArray *sleepDataPoints, NSTimeInterval totalSleepTime, NSTimeInterval totalBedTime) {
            NSLog(@"[readRealSleepForDay: %@] SleepDataPoints: %@",date, sleepDataPoints);
            NSLog(@"[readRealSleepForDay: %@] TotalSleepTime: %f",date, totalSleepTime);
            NSLog(@"[readRealSleepForDay: %@] TotalBedTime: %f\n",date, totalBedTime);
        }];
    }

    //--------------------------
    
// Get sleep data for only a day:
//    [[SleepDataProvider sharedInstance] readSleepForDay:[NSDate date] withCompletion:^(NSTimeInterval sleepTime, NSTimeInterval bedTime) {
//        NSLog(@"S'ha complert !");
//    }];
    
// Get sleep data for more than one day:
//    [[SleepDataProvider sharedInstance] readSleepForVariousDays:[NSDate date] withCompletion:^(NSDictionary *days) {
//        NSLog(@"Days dictionary: %@",days);
//    }];
//    [[SleepDataProvider sharedInstance] readSleepFromDate:[_dateFormatter dateFromString:_startDateTextfield.text] toDate:[_dateFormatter dateFromString:_endDateTextfield.text] withCompletion:^(NSTimeInterval sleepTime, NSTimeInterval bedTime, NSDate *startDate, NSDate *endDate, NSError *error) {
//        if (!error) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                _resultsFirstLabel.text = [NSString stringWithFormat:@"You slept for %.2f h. bedTime: %.2f h", sleepTime / kSECONDS_IN_HOUR, bedTime / kSECONDS_IN_HOUR];
//                NSDateFormatter *hourMinuteFormatter = [[NSDateFormatter alloc] init];
//                [hourMinuteFormatter setDateFormat:@"HH:mm"];
//                _resultsSecondLabel.text = [NSString stringWithFormat:@"From %@h to %@h", [hourMinuteFormatter stringFromDate:startDate], [hourMinuteFormatter stringFromDate:endDate]];
//            });
//        } else {
//            NSLog(@"Error retrieving sleep data: %@", error.localizedDescription);
//        }
//    }];
}

-(NSArray *) daysBetweenDate:(NSDate *)fromDate toDate:(NSDate *)toDate{
    
    NSCalendar *calendar = [NSCalendar currentCalendar];

    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate interval:NULL forDate:fromDate];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate interval:NULL forDate:toDate];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    NSLog(@"Difference day: %ld", (long)[difference day]);
    
    NSMutableArray *datesBetween = [NSMutableArray new];
    NSDate *lastDate = fromDate;
    for (int i = 0; i <= [difference day]; i++) {
        [datesBetween addObject:lastDate];
        lastDate = [lastDate dateByAddingTimeInterval:24*60*60];
    }
    NSLog(@"Dates: %@",datesBetween);
    return datesBetween;

}

//HKSource proves:
- (IBAction) provesSource:(id)sender{
    [[HealthKitProvider sharedInstance] getAllSourcesForDataType:@"sleep_analysis" withCompletion:^(NSArray *sources, NSError *error) {
        NSLog(@"Array de sources: %@", sources);
    }];
}


#pragma mark - UI methods.

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
    int index = (int)_segmentedControl.selectedSegmentIndex;
    if (index == 0) {
        _startDateTextfield.text = @"";
        _endDateTextfield.text = @"";

    }else if (index == 1){
        _startDateTextfield.text = @"";
        _endDateTextfield.text = @"";

    }else if (index == 2){
        _startDateTextfield.text = [_dateFormatter stringFromDate:[self beginningOfTheDay:[NSDate date]]];
        _endDateTextfield.text = [_dateFormatter stringFromDate:[NSDate date]];
    }else{
        _startDateTextfield.text = @"2016-08-12 17:00:00";
        _endDateTextfield.text = @"2016-08-13 17:00:00";
    }

    _resultsFirstLabel.text = @"";
    _resultsSecondLabel.text = @"";
}

- (void) dateFormatEditor{
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc]init];
    [datePicker setDate:[NSDate date]];
    [datePicker addTarget:self action:@selector(updateTextField:) forControlEvents:UIControlEventValueChanged];
    [_startDateTextfield setInputView:datePicker];
    [_endDateTextfield setInputView:datePicker];
}

#pragma mark - Helper methods

- (NSDate *) getYesterdayAtFiveDate{
    return [[self beginningOfTheDay:[[NSDate date] dateByAddingTimeInterval:(-1)*24*60*60]] dateByAddingTimeInterval:17*60*60];
}
- (NSDate *) getTodayAtFiveDate{
    return [[self beginningOfTheDay:[NSDate date]] dateByAddingTimeInterval:17*60*60];
}

- (NSDate *) beginningOfTheDay:(NSDate *)date{
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *beginningOfTheDay = [gregorianCalendar dateFromComponents:components];
    
    return  beginningOfTheDay;
}


@end
