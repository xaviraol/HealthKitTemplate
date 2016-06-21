//
//  HealthKitManager.m
//  HealthKitTemplate
//
//  Created by Sense Health on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "HealthKitManager.h"
#import <HealthKit/HealthKit.h>

@interface HealthKitManager ()

@property (nonatomic, retain) HKHealthStore *healthStore;

@end

@implementation HealthKitManager

+ (HealthKitManager *)sharedInstance {
    
    static HealthKitManager *instance = nil;
    instance = [[HealthKitManager alloc] init];
    instance.healthStore = [[HKHealthStore alloc] init];
    return instance;
}

- (void) requestHealthKitAuthorization:(void(^)(BOOL success, NSError *error))completion{
    
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        return;
    }
    NSArray *readTypes = @[
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
                           [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                           [HKObjectType activitySummaryType],
                           [HKObjectType workoutType]
                           ];
    
    NSArray *shareTypes = @[
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                            [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                            [HKObjectType workoutType]
                            ];
    
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:shareTypes] readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        completion(success,error);
    }];
}



- (void)readTimeActiveForSampleType:(HKSampleType *)sampleType fromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate withCompletion:(void (^)(NSTimeInterval timeInterval, NSError *error))completion{
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                           predicate:predicate
                                                               limit:HKObjectQueryNoLimit
                                                     sortDescriptors:@[sortDescriptor]
                                                      resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                                                          NSTimeInterval timeActive = 0;
                                                          for (HKQuantitySample *sample in results) {
                                                              if ([sample.quantity doubleValueForUnit:[HKUnit meterUnit]] >= 1){
                                                                  timeActive += [sample.endDate timeIntervalSinceDate:sample.startDate];
                                                              }
                                                          }
                                                          completion(timeActive,error);
                                                      }];
    [self.healthStore executeQuery:query];
}

- (void) readCoveredDistanceForSampleType:(HKSampleType *)sampleType fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) onCompleted{
    
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    HKSampleQuery *stepQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                               predicate:predicate
                                                                   limit:HKObjectQueryNoLimit
                                                         sortDescriptors:@[sortDescriptor]
                                                          resultsHandler:^(HKSampleQuery *query, NSArray *hkSample, NSError *error){
                                                              
                                                              double totalDistance = 0;
                                                              NSMutableArray *listOfSpeed = [[NSMutableArray alloc] init];
                                                              
                                                              for (int i = 0; i < [hkSample count]; i++) {
                                                                  HKQuantitySample *sampleData = [hkSample objectAtIndex:i];
                                                                  double distance = [[sampleData quantity] doubleValueForUnit:[HKUnit meterUnitWithMetricPrefix:HKMetricPrefixKilo]];
                                                                  totalDistance += distance;
                                                                  
                                                                  double distanceMeter = [[sampleData quantity] doubleValueForUnit:[HKUnit meterUnit]];
                                                                  //            double distanceSecond = [[sampleData startDate] doubleValueForUnit:[HKUnit secondUnitWithMetricPrefix:HKMetricPrefixKilo]];
                                                                  NSDate *startDate = [sampleData startDate];
                                                                  NSDate *endDate = [sampleData endDate];
                                                                  NSTimeInterval distanceSecond = [endDate timeIntervalSinceDate:startDate];
                                                                  
                                                                  double distanceMeterPerSecond = distanceMeter / distanceSecond;
                                                                  NSNumber *numberMeterPerSecond = [NSNumber numberWithDouble:distanceMeterPerSecond];
                                                                  [listOfSpeed addObject:numberMeterPerSecond];
                                                                  
                                                                  //            HKUnit *meters = [HKUnit meterUnit];
                                                                  //            HKUnit *seconds = [HKUnit secondUnit];
                                                                  //            HKUnit *metersPerSecond = [meters unitDividedByUnit:seconds];
                                                                  //            HKQuantity *quantityPerSecond = [HKQuantity quantityWithUnit:metersPerSecond doubleValue:distanceMeter];
                                                                  
                                                                  //            NSLog(@"distance activity %f, %@, %f m/s", distance, quantityPerSecond, distanceMeterPerSecond);
                                                                  
                                                              }
                                                              NSLog(@"total distance %f", totalDistance);
                                                              onCompleted(totalDistance, listOfSpeed, error);
                                                          }];
    [self.healthStore executeQuery:stepQuery];
}


- (void) readStepsTimeActiveFromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate withCompletion:(void (^)(NSTimeInterval timeInterval, NSInteger totalSteps, NSError *error))completion{
    
    HKSampleType *type = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *stepSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    HKSampleQuery *stepQuery = [[HKSampleQuery alloc] initWithSampleType:type
                                                               predicate:stepPredicate
                                                                   limit:HKObjectQueryNoLimit
                                                         sortDescriptors:@[stepSortDescriptor]
                                                          resultsHandler:^(HKSampleQuery *query, NSArray *hkSample, NSError *error){
                                                              
                                                              NSTimeInterval totalTime = 0;
                                                              NSInteger totalStep = 0;
                                                              
                                                              for (int i = 0; i < [hkSample count]; i++) {
                                                                  HKQuantitySample *sampleStep = [hkSample objectAtIndex:i];
                                                                  NSDate *startDate = [sampleStep startDate];
                                                                  NSDate *endDate = [sampleStep endDate];
                                                                  NSTimeInterval secondBetween = [endDate timeIntervalSinceDate:startDate];
                                                                  NSInteger stepCount = [[sampleStep quantity] doubleValueForUnit:[HKUnit countUnit]];
                                                                  totalTime += secondBetween;
                                                                  totalStep += stepCount;
                                                                  // TODO: time active can be zero if data source from healthkit app, because start date and end date is same
                                                                  NSLog(@"second activity %@ = %@ = %f = %ld", startDate, endDate, secondBetween, (long)stepCount);
                                                              }
                                                              NSLog(@"total activity %@ = %@ = %f = %ld", startDate, endDate, totalTime, (long)totalStep);
                                                              completion(totalTime, totalStep, error);
                                                          }];
    
    [self.healthStore executeQuery:stepQuery];
}

- (void) readSleepAnalysisFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval sleepTime, NSError *error))completion{
    
    //TODO: create a predicate to get sleep info for a certain range of hours/days...
    
    HKCategoryType *sleepAnalysis = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sleepAnalysis
                                                           predicate:nil
                                                               limit:HKObjectQueryNoLimit
                                                     sortDescriptors:nil
                                                      resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                                                          NSTimeInterval sleepTime = 0;
                                                          for (HKQuantitySample *sample in results) {
                                                              NSLog(@"StartDate: %@",sample.startDate);
                                                              NSLog(@"EndDate: %@",sample.endDate);
                                                              NSLog(@"Time Interval: %f", [sample.endDate timeIntervalSinceDate:sample.startDate]);
                                                              sleepTime += [sample.endDate timeIntervalSinceDate:sample.startDate];
                                                          }
                                                          completion(sleepTime,error);
                                                      }];
    [self.healthStore executeQuery:query];
}

- (void) readHeartRateFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double bpm, NSError *error)) onCompleted{
    HKSampleType *type = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *stepSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    HKSampleQuery *stepQuery = [[HKSampleQuery alloc] initWithSampleType:type predicate:stepPredicate limit:0 sortDescriptors:@[stepSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *hkSample, NSError *error){
        
        double totalBpm = 0;
        
        for (int i = 0; i < [hkSample count]; i++) {
            HKQuantitySample *sampleData = [hkSample objectAtIndex:i];
            double bpm = [[sampleData quantity] doubleValueForUnit:[HKUnit countUnit]];
            totalBpm += bpm;
            NSLog(@"distance activity %f", bpm);
            
        }
        NSLog(@"total distance %f", totalBpm);
        onCompleted(totalBpm, error);
    }];
    
    
    [self.healthStore executeQuery:stepQuery];
}

- (void) setTimeActiveOnBackgroundForSampleType:(HKSampleType*) sampleType{
    HKObserverQuery *query = [[HKObserverQuery alloc] initWithSampleType:sampleType predicate:nil updateHandler:^(HKObserverQuery *query, HKObserverQueryCompletionHandler completionHandler, NSError *error) {
        if (error) {
            NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***",
                  error.localizedDescription);
            abort();
        }
        //TODO:
        //        [self readTimeActiveForSampleType:sampleType withSortDescriptors:nil withPredicate:nil andCompletion:^(NSTimeInterval timeInterval, NSError *error) {
        //            NSLog(@"Walking timeInterval: %f", timeInterval);
        //        }];
        completionHandler();
        
    }];
    [self.healthStore executeQuery:query];
    [self.healthStore enableBackgroundDeliveryForType:sampleType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error){
        if (success) {
            NSLog(@"success background changes");
        }
    }];
}


#pragma mark - Helper methods to write custom data to HealthKit

- (void) writeWalkingRunningDistance:(double)distance fromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion{
    
    HKQuantityType *walkRunQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    HKUnit *walkRunUnit = [HKUnit meterUnit];
    HKQuantity *quantityWalkRun = [HKQuantity quantityWithUnit:walkRunUnit doubleValue:distance];
    
    HKQuantitySample *walkingRunningSample = [HKQuantitySample quantitySampleWithType:walkRunQuantityType quantity:quantityWalkRun startDate:startDate endDate:endDate];
    
    [self.healthStore saveObject:walkingRunningSample withCompletion:^(BOOL success, NSError * _Nullable error) {
        completion(success, error);
    }];
}

- (void) writeCyclingDistance:(double)distance fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion{
    
    HKQuantityType *cyclingQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
    HKUnit *walkRunUnit = [HKUnit meterUnit];
    HKQuantity *quantityCycling = [HKQuantity quantityWithUnit:walkRunUnit doubleValue:distance];
    
    HKQuantitySample *cyclingSample = [HKQuantitySample quantitySampleWithType:cyclingQuantityType quantity:quantityCycling startDate:startDate endDate:endDate];
    
    [self.healthStore saveObject:cyclingSample withCompletion:^(BOOL success, NSError * _Nullable error) {
        completion(success,error);
    }];
}

- (void) writeSteps:(double)steps fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion{
    HKQuantityType *stepsQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKUnit *stepsUnit = [HKUnit countUnit];
    HKQuantity *stepsQuantity = [HKQuantity quantityWithUnit:stepsUnit doubleValue:steps];
    
    HKQuantitySample *cyclingSample = [HKQuantitySample quantitySampleWithType:stepsQuantityType quantity:stepsQuantity startDate:startDate endDate:endDate];
    
    [self.healthStore saveObject:cyclingSample withCompletion:^(BOOL success, NSError * _Nullable error) {
        completion(success,error);
    }];
}

- (void) writeSleepAnalysisFromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion{
    
    HKCategoryType *sleepAnalysis = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKCategorySample *sleepSample = [HKCategorySample categorySampleWithType:sleepAnalysis value:HKCategoryValueSleepAnalysisInBed startDate:startDate endDate:endDate];
    [self.healthStore saveObject:sleepSample withCompletion:^(BOOL success, NSError * _Nullable error) {
        completion(success, error);
    }];
}

@end
