//
//  HealthKitManager.m
//  HealthKitTemplate
//
//  Created by Xavier Ramos Oliver on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "HealthKitManager.h"
#import <HealthKit/HealthKit.h>

@interface HealthKitManager ()

@property (nonatomic, retain) HKHealthStore *healthStore;

@end

@implementation HealthKitManager

+ (HealthKitManager *)sharedManager {
    static dispatch_once_t pred = 0;
    static HealthKitManager *instance = nil;
    dispatch_once(&pred, ^{
        instance = [[HealthKitManager alloc] init];
        instance.healthStore = [[HKHealthStore alloc] init];
    });
    return instance;
}

- (void)requestAuthorization {
    
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        // If our device doesn't support HealthKit -> return.
        return;
    }
    
    NSArray *readTypes = @[[HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleExerciseTime]];
    
    NSArray *writeTypes = @[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                            [HKObjectType workoutType],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]];
    
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes] readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"Authorization Failed!");
        }
    }];
}

- (NSDate *)readBirthDate{
    NSError *error;
    NSDate *dateOfBirth = [self.healthStore dateOfBirthWithError:&error];
    if (!dateOfBirth) {
        NSLog(@"Either an error ocurred fetching the user's age information or none has been stored yet.");
    }
    
    return dateOfBirth;
}

- (void) writeWeightSample:(CGFloat)weight{
    
    HKUnit *kilogramUnit = [HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo];
    HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:kilogramUnit doubleValue:weight];
    
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    NSDate *now = [NSDate date];
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:now endDate:now];
    
    [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"Quantity sample not saved!");
        }
    }];
}

- (void) writeWorkoutSamplewithStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate withDistance:(double)distance withDistanceUnit:(HKUnit*)distanceUnit withKiloCalories:(double)kiloCalories{
    
    HKQuantity *distanceQuantity = [HKQuantity quantityWithUnit:distanceUnit doubleValue:distance];
    HKQuantity *kiloCaloriesQuantity = [HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:kiloCalories];
    
    HKWorkout *workout = [HKWorkout workoutWithActivityType:HKWorkoutActivityTypeRunning startDate:startDate endDate:endDate duration:[endDate timeIntervalSinceDate:startDate] totalEnergyBurned:kiloCaloriesQuantity totalDistance:distanceQuantity metadata:nil];
    
    [self.healthStore saveObject:workout withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"Workout not saved!");
        }
    }];
}

- (void) readStepsCount{
    
    HKSampleType *stepType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:stepType
                                                           predicate:nil
                                                               limit:HKObjectQueryNoLimit
                                                     sortDescriptors:nil
                                                      resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                                                          if (!results) {
                                                              NSLog(@"An error ocurred %@",error.localizedDescription);
                                                          }else{
                                                              for (HKQuantitySample *result in results) {
                                                                  NSLog(@"result_startTime: %@",result.startDate);
                                                                  NSLog(@"result_endTime: %@",result.endDate);
                                                                  NSLog(@"resutl_source: %@", result.sourceRevision);
                                                              }
                                                              NSLog(@"RESULTS: %@", results);
                                                          }
                                                      }];
    
    [self.healthStore executeQuery:query];
}

- (void) writeStepsCountnumberOfSteps:(int)steps fromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate{
    
    HKQuantityType *stepQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKUnit *stepUnit = [HKUnit countUnit];
    HKQuantity *quantitySteps = [HKQuantity quantityWithUnit:stepUnit doubleValue:1000];
    
    HKQuantitySample *stepSample = [HKQuantitySample quantitySampleWithType:stepQuantityType quantity:quantitySteps startDate:startDate endDate:endDate];
    
    [self.healthStore saveObject:stepSample withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"Step sample added!");
        }
    }];
}

- (void) getActivityTimeFromHealthkit{
//    HKSampleType *activityTimeType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleExerciseTime];
//    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:activityTimeType
//                                                           predicate:nil
//                                                               limit:HKObjectQueryNoLimit
//                                                     sortDescriptors:nil
//                                                      resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
//                                                          if (!results) {
//                                                              NSLog(@"An error occurred %@", error.localizedDescription);
//                                                          }else{
//                                                              NSLog(@"Results: %@", results);
//                                                          }
//                                                      }];
//    [self.healthStore executeQuery:query];
}

- (void) getActivitySumaries{
    // Create the date components for the predicate
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:endDate options:0];
    NSCalendarUnit unit = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitEra;
    
    NSDateComponents *startDateComponents = [calendar components:unit fromDate:startDate];
    startDateComponents.calendar = calendar;
    
    NSDateComponents *endDateComponents = [calendar components:unit fromDate:endDate];
    endDateComponents.calendar = calendar;
    
    // Create the predicate for the query
    NSPredicate *summariesWithinRange =
    [HKQuery predicateForActivitySummariesBetweenStartDateComponents:startDateComponents endDateComponents:endDateComponents];
    
    // Build the query
    HKActivitySummaryQuery *query = [[HKActivitySummaryQuery alloc]
                                     initWithPredicate:summariesWithinRange
                                     resultsHandler:^(HKActivitySummaryQuery * _Nonnull query, NSArray<HKActivitySummary *> * _Nullable activitySummaries, NSError * _Nullable error) {
        if (activitySummaries == nil) {
            
            // Handle the error here...
            NSLog(@"Error active time");
            return;
        }
        // Do something with the summaries here...
        NSLog(@"Active time: %@",activitySummaries);
        
    }];
    
    // Run the query
    [self.healthStore executeQuery:query];
}

- (void) writeWalkingRunningDistanceFromDate:(NSDate*)startDate andEndDate:(NSDate*)endDate{
    HKQuantityType *walkRunQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    HKUnit *walkRunUnit = [HKUnit meterUnit];
    HKQuantity *quantityWalkRun = [HKQuantity quantityWithUnit:walkRunUnit doubleValue:1000];
    
    HKQuantitySample *stepSample = [HKQuantitySample quantitySampleWithType:walkRunQuantityType quantity:quantityWalkRun startDate:startDate endDate:endDate];
    
    [self.healthStore saveObject:stepSample withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"Walking and running sample added!");
        }
    }];
}

- (void)getQuantativeDataFromTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double value, NSError *error))completionHandler {
    //NSPredicate *predicate = [self predicateForSamplesToday];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType quantitySamplePredicate:nil options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        HKQuantity *sum = [result sumQuantity];
        
        if (completionHandler) {
            double value = [sum doubleValueForUnit:unit];
            
            completionHandler(value, error);
        }
    }];
    
    [self.healthStore executeQuery:query];
}


@end
