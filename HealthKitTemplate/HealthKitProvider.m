//
//  HealthKitProvider.m
//  HealthKitTemplate
//
//  Created by Sense Health on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "HealthKitProvider.h"
#import <HealthKit/HealthKit.h>
#import "HKWalkingRunning.h"
#import "HKCycling.h"
#import "HKStepCounterSensor.h"
#import <UIKit/UIKit.h>


static NSString* kHEALTHKIT_AUTHORIZATION = @"healthkit_authorization";
@interface HealthKitProvider ()


@end

@implementation HealthKitProvider

+ (HealthKitProvider *)sharedInstance {
    
    static HealthKitProvider *instance = nil;
    instance = [[HealthKitProvider alloc] init];
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
        [[NSUserDefaults standardUserDefaults]setBool:success forKey:kHEALTHKIT_AUTHORIZATION];
        [[NSUserDefaults standardUserDefaults]synchronize];
        [self startObservingStepChanges];
        completion(success,error);
    }];
}
- (void) startObservingStepChanges{
    HKQuantityType *stepCountType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    [[HealthKitProvider sharedInstance].healthStore enableBackgroundDeliveryForType:stepCountType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error) {}];
    
    HKQuery *query = [[HKObserverQuery alloc] initWithSampleType:stepCountType predicate:nil updateHandler:
                      ^void(HKObserverQuery *query, HKObserverQueryCompletionHandler completionHandler, NSError *error)
                      {
                          //If we don't call the completion handler right away, Apple gets mad. They'll try sending us the same notification here 3 times on a back-off algorithm.  The preferred method is we just call the completion handler.  Makes me wonder why they even HAVE a completionHandler if we're expected to just call it right away...
                          if (completionHandler) {
                              HKStepCounterSensor *stepCounter = [[HKStepCounterSensor alloc] init];
                              [stepCounter onStepsUpdate];
                              UILocalNotification* localNotification = [[UILocalNotification alloc] init];
                              localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:3];
                              localNotification.alertBody = [NSString stringWithFormat:@"Nova dada afegida: %@",[[NSUserDefaults standardUserDefaults] valueForKey:@"cumulativeSteps"]];
                              localNotification.timeZone = [NSTimeZone defaultTimeZone];
                              localNotification.timeZone = [NSTimeZone defaultTimeZone];
                              localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
                              [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                              completionHandler();
                          }
                      }];
    [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
}

/* Walking and Running methods*/

- (void) readWalkingTimeActiveFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    HKWalkingRunning *walkingRunning = [[HKWalkingRunning alloc] init];
    [walkingRunning readWalkingTimeActiveFromStartDate:startDate toEndDate:endDate withCompletion:^(NSTimeInterval timeActive, NSError *error) {
        completion(timeActive,error);
    }];
}

- (void) readMostRecentWalkingTimeActiveSampleWithCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    HKWalkingRunning *walkingRunning = [[HKWalkingRunning alloc] init];
    [walkingRunning readMostRecentWalkingTimeActiveSampleWithCompletion:^(NSTimeInterval timeActive, NSError *error) {
        completion(timeActive,error);
    }];
}

- (void) setTimeActiveOnBackgroundForWalkingSample{
    HKWalkingRunning *walkingRunning = [[HKWalkingRunning alloc] init];
    [walkingRunning setTimeActiveOnBackgroundForWalkingSample];
}

/* Cycling methods*/

- (void) readCyclingTimeActiveFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    HKCycling *cycling = [[HKCycling alloc] init];
    [cycling readCyclingTimeActiveFromStartDate:startDate toEndDate:endDate withCompletion:^(NSTimeInterval timeActive, NSError *error) {
        completion(timeActive,error);
    }];
}

- (void) readMostRecentCyclingTimeActiveSampleWithCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    HKCycling *cycling = [[HKCycling alloc] init];
    [cycling readMostRecentCyclingTimeActiveSampleWithCompletion:^(NSTimeInterval timeActive, NSError *error) {
        completion(timeActive,error);
    }];
}

- (void) setTimeActiveOnBackgroundForCyclingSample{
    HKCycling *cycling = [[HKCycling alloc] init];
    [cycling setTimeActiveOnBackgroundForCyclingSample];
}

/* Other methods */

- (void) readCoveredDistanceForSampleType:(HKSampleType *)sampleType fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion{
    
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
                                                              completion(totalDistance, listOfSpeed, error);
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
    
    HKCategoryType *sleepAnalysis = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    //HKCategorySample *sleepSample = [HKCategorySample categorySampleWithType:sleepAnalysis value:HKCategoryValueSleepAnalysisInBed startDate:startDate endDate:endDate];
    
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    //HKCategoryType *sleepAnalysis = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sleepAnalysis
                                                           predicate:predicate
                                                               limit:HKObjectQueryNoLimit
                                                     sortDescriptors:@[sortDescriptor]
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

- (void) readHeartRateFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double bpm, NSError *error)) completion{
    //TODO: this method is not used right now in this project. Would be great to create an usage for it in the UI.
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
        completion(totalBpm, error);
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
        //TODO: Deep investigation to understand how it works.
        [self readCoveredDistanceForSampleType:sampleType fromStartDate:nil toEndDate:nil withCompletion:^(double totalDistance, NSArray *listOfSpeed, NSError *error) {
            NSLog(@"Covered distance: %f", totalDistance);
        }];
    }];
    [self.healthStore executeQuery:query];
    
    [self.healthStore enableBackgroundDeliveryForType:sampleType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error){
        if (success) {
            NSLog(@"success background changes");
        }
    }];
}

- (void) provesBackground{
    HKSampleType *stepCountType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKObserverQuery *query = [[HKObserverQuery alloc] initWithSampleType:stepCountType predicate:nil updateHandler:^(HKObserverQuery *query, HKObserverQueryCompletionHandler completionHandler, NSError *error) {
        if (error) {
            NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***",
                  error.localizedDescription);
            abort();
        }
        HKStepCounterSensor *stepCounter = [[HKStepCounterSensor alloc] init];
        [stepCounter onStepsUpdate];
    }];
    
    [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
    [[HealthKitProvider sharedInstance].healthStore enableBackgroundDeliveryForType:stepCountType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error){
        if (success) {
            NSLog(@"Background changes enabled!");
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
