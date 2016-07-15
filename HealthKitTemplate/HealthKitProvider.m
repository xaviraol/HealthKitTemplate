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

# pragma mark - Asking for Healthkit Permission

/**
*
*   requestHealthKitAuthorization: This method asks the user for the permissions to access Healthkit data. In this case, we ask for the
*   permissions of the different data types at once. So the user can enable all of them at the same time. A part from that, with this method
*   we ask for to read data that already exists in Healthkit and also to write new data to Healthkit.
*
*   In this example, we ask permissions for: Walking and Running, Cycling, Step counter and Sleep Analysis.
*
**/

- (void) requestHealthKitAuthorization:(void(^)(BOOL success, NSError *error))completion{
    
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        return;
    }
    NSArray *readTypes = @[
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling],
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                           [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],

                           ];
    
    NSArray *shareTypes = @[
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                            [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                            ];
    
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:shareTypes] readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        //[self startObservingStepChanges];
        completion(success,error);
    }];
}

/**
*
*   requestHealthKitAuthorizationForHKDataQuantityType: Similar as the previous method, but here we have a dataType string as an input.
*   So in this method we ask permissions for only one dataType. In this case, we ask for permissions for a QuantityType.
*   In this examples, our quantityTypes are stepCounter, walking and running, and cycling.
*
**/

- (void) requestHealthKitAuthorizationForHKDataQuantityType:(NSString*)dataType withCompletion:(void(^)(BOOL success, NSError *error))completion{
    
    self.healthStore = [[HKHealthStore alloc] init];
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        return;
    }
    NSArray *readTypes = @[[HKObjectType quantityTypeForIdentifier:[NSString stringWithFormat:@"%@",[self getHKSampleTypeFromString:dataType]]]];
    [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithArray:readTypes] readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        if (success) {
            NSLog(@"[HealthKitDataProvider] Success!");
        }else{
            NSLog(@"[HealthKitDataProvider] Error!");
            NSLog(@"Error: %@",error.localizedDescription);
        }
        completion(success,error);
    }];
}

/**
 *
 *   requestHealthKitAuthorizationForHKDataCategoryType: In this case, we ask for permissions for a QuantityType.
 *   In this examples, we have only one category type, sleep analysis.
 *
 **/
- (void) requestHealthKitAuthorizationForHKDataCategoryType:(NSString*)dataType withCompletion:(void(^)(BOOL success, NSError *error))completion{
    
    self.healthStore = [[HKHealthStore alloc] init];
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        return;
    }
    NSArray *readTypes = @[[HKObjectType categoryTypeForIdentifier:[NSString stringWithFormat:@"%@",[self getHKSampleTypeFromString:dataType]]]];
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        if (success) {
            NSLog(@"[HealthKitDataProvider] Success!");
        }else{
            NSLog(@"[HealthKitDataProvider] Error!");
            NSLog(@"Error: %@",error.localizedDescription);
        }
        completion(success,error);
    }];
}


# pragma mark - Reading data from Healthkit

// StepCounter
- (void) readCumulativeStepsFrom:(NSDate *)startDate toDate:(NSDate *)endDate withCompletion:(void (^)(int steps, NSError *error))completion{
    HKQuantityType *stepCountType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:stepCountType quantitySamplePredicate:stepPredicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
        completion((int)[result.sumQuantity doubleValueForUnit:[HKUnit countUnit]],error);
    }];
    [self.healthStore executeQuery:query];
}

- (void) readStepsTimeActiveFromDate:(NSDate *)startDate toDate:(NSDate *)endDate withCompletion:(void (^)(NSTimeInterval timeInterval, NSInteger totalSteps, NSError *error))completion{
    
    HKSampleType *type = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *stepSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    HKSampleQuery *stepQuery = [[HKSampleQuery alloc] initWithSampleType:type predicate:stepPredicate limit:HKObjectQueryNoLimit sortDescriptors:@[stepSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *hkSample, NSError *error){
        
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

// Walking and Running

- (void) readWalkingTimeActiveFromDate:(NSDate *) startDate toDate:(NSDate *) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    
    HKSampleType *walkingSample = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:walkingSample predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results,NSError * _Nullable error) {
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
- (void) readCoveredWalkingDistanceFromDate:(NSDate *)startDate toDate:(NSDate*)endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion{
    HKSampleType *walkingSample = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    
}

// Cycling

- (void) readCyclingTimeActiveFromDate:(NSDate*) startDate toDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
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
- (void) readCoveredCyclingDistanceFromDate:(NSDate *)startDate toDate:(NSDate*)endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion{
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];

}

// Sleep Analysis



/* Other methods */

- (void) readCoveredDistanceForSampleType:(HKSampleType *)sampleType fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion{
    
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    HKSampleQuery *stepQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *hkSample, NSError *error){
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


- (void) startObservingCyclingChanges{
        HKSampleType *sampleType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
        HKObserverQuery *query = [[HKObserverQuery alloc] initWithSampleType:sampleType predicate:nil updateHandler:^(HKObserverQuery *query,
                                                                                                                      HKObserverQueryCompletionHandler completionHandler,
                                                                                                                      NSError *error) {
            
            if (error) {
                
                // Perform Proper Error Handling Here...
                NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***",
                      error.localizedDescription);
                abort();
            }else{
                [self commitNewHealthKitSample];
                completionHandler();
            }
        }];
        [self.healthStore enableBackgroundDeliveryForType:sampleType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"enabled background delivery!");
            }else{
                NSLog(@"failed to enabling backgroun delivery!");
            }
        }];
        [self.healthStore executeQuery:query];
}

- (void) commitNewHealthKitSample{
        NSLog(@"TIME ACTIVE de les bicis");
}


# pragma mark - Helper methods

- (NSDictionary*) healthKitDataTypeStringToHKSample {
    return @{@"HKStepCounter": HKQuantityTypeIdentifierStepCount,
             @"HKSleepAnalysis": HKCategoryTypeIdentifierSleepAnalysis,
             @"HKWalking": HKQuantityTypeIdentifierDistanceWalkingRunning,
             };
}

- (HKSampleType *)getHKSampleTypeFromString:(NSString *)string{
    return (HKSampleType *)[[self healthKitDataTypeStringToHKSample] objectForKey:string];
}



# pragma mark - Not classified yet


- (void) startObservingStepChanges{
    HKSampleType *sampleType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKObserverQuery *query = [[HKObserverQuery alloc] initWithSampleType:sampleType predicate:nil updateHandler:^(HKObserverQuery *query,
                                                                                                                  HKObserverQueryCompletionHandler completionHandler,
                                                                                                                  NSError *error) {
        
        if (error) {
            
            // Perform Proper Error Handling Here...
            NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***",
                  error.localizedDescription);
            abort();
        }else{
            [self updateDailyStepCount];
            completionHandler();
        }
    }];
    [[HealthKitProvider sharedInstance].healthStore enableBackgroundDeliveryForType:sampleType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"enabled background delivery!");
        }else{
            NSLog(@"failed to enabling backgroun delivery!");
        }
    }];
    [self.healthStore executeQuery:query];
}
- (void) updateDailyStepCount{
    NSLog(@"Banyoles vinga va!");
    
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

@end
