//
//  HealthKitProvider.m
//  HealthKitTemplate
//
//  Created by Sense Health on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "HealthKitProvider.h"
#import <HealthKit/HealthKit.h>
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

# pragma mark - Healthkit Permissions

- (void) requestHealthKitAuthorizationForDataTypes:(NSArray *)dataTypes withCompletion:(void(^)(BOOL success, NSError *error))completion{
    
    if ([HKHealthStore isHealthDataAvailable] == NO) {
        return;
    }
    NSMutableArray *readTypes = [NSMutableArray new];
    for (int i = 0;i<dataTypes.count ; i++) {
        [readTypes addObject:[self hKObjectTypeFromHealthKitDataType:dataTypes[i]]];
    }
    
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithArray:readTypes] completion:^(BOOL success, NSError *error){
        completion(success,error);
    }];
}



# pragma mark - Reading Steps

- (void) readCumulativeStepsFrom:(NSDate *)startDate toDate:(NSDate *)endDate withCompletion:(void (^)(int steps, NSError *error))completion{
    HKQuantityType *stepCountType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:stepCountType quantitySamplePredicate:stepPredicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
        completion((int)[result.sumQuantity doubleValueForUnit:[HKUnit countUnit]],error);
    }];
    [self.healthStore executeQuery:query];
}

- (void) readStepsTimeActiveFromDate:(NSDate *)startDate toDate:(NSDate *)endDate withCompletion:(void (^)(NSTimeInterval timeInterval, NSError *error))completion{
    HKSampleType *type = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *stepSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKSampleQuery *stepQuery = [[HKSampleQuery alloc] initWithSampleType:type predicate:stepPredicate limit:HKObjectQueryNoLimit sortDescriptors:@[stepSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *hkSample, NSError *error){
        
        NSTimeInterval totalTime = 0;
        NSDate *lastStepDataPoint;
        NSDate *stepDataPointDate;

        for (int i = 0; i < [hkSample count]; i++) {
            HKQuantitySample *stepDataPoint = [hkSample objectAtIndex:i];
            if ([[stepDataPoint quantity] doubleValueForUnit:[HKUnit countUnit]]>45) {
                stepDataPointDate = [stepDataPoint startDate];
                NSTimeInterval secondsBetweenDataPoints = [stepDataPointDate timeIntervalSinceDate:lastStepDataPoint];
                if (secondsBetweenDataPoints < 300) {
                    totalTime += secondsBetweenDataPoints;
                }
            }
            lastStepDataPoint = stepDataPointDate;
        }
        completion(totalTime, error);
    }];
    
    [self.healthStore executeQuery:stepQuery];
}

# pragma mark - Reading Walking & Running data

- (void) readWalkingTimeActiveFromDate:(NSDate *) startDate toDate:(NSDate *) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    
   HKSampleType *walkingSample = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    [self readActivityTimeActiveForSampleType:walkingSample fromDate:startDate toDate:endDate withCompletion:^(NSTimeInterval timeActive, NSError *error) {
        completion (timeActive,error);
    }];
}
- (void) readCoveredWalkingDistanceFromDate:(NSDate *)startDate toDate:(NSDate*)endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion{
    HKSampleType *walkingSample = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    [self readCoveredDistanceForSampleType:walkingSample fromStartDate:startDate toEndDate:endDate withCompletion:^(double totalDistance, NSArray *listOfSpeed, NSError *error) {
        completion (totalDistance, listOfSpeed, error);
    }];
}

# pragma mark - Reading Cycling data

- (void) readCyclingTimeActiveFromDate:(NSDate*) startDate toDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    
    HKSampleType *cyclingSample = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
    [self readActivityTimeActiveForSampleType:cyclingSample fromDate:startDate toDate:endDate withCompletion:^(NSTimeInterval timeActive, NSError *error) {
        completion (timeActive,error);
    }];
}

- (void) readCoveredCyclingDistanceFromDate:(NSDate *)startDate toDate:(NSDate*)endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion{
    HKSampleType *cyclingSample = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
    [self readCoveredDistanceForSampleType:cyclingSample fromStartDate:startDate toEndDate:endDate withCompletion:^(double totalDistance, NSArray *listOfSpeed, NSError *error) {
        completion (totalDistance, listOfSpeed, error);
    }];
}

# pragma mark - Reading Sleep data

- (void) readSleepFromDate:(NSDate *)startDate toDate:(NSDate *) endDate withCompletion:(void (^)(NSTimeInterval sleepTime, NSDate *startDate, NSDate *endDate, NSError *error)) completion{
    HKCategoryType *sleepAnalysis = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sleepAnalysis
                                                           predicate:predicate
                                                               limit:HKObjectQueryNoLimit
                                                     sortDescriptors:@[sortDescriptor]
                                                      resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                                                          NSTimeInterval sleepTime = 0;
                                                          NSDate *startDate;
                                                          NSDate *endDate;
                                                          if (results.count >= 1) {
                                                              startDate = results[0].startDate;
                                                              endDate = results[results.count-1].endDate;
                                                          }
                                                          for (HKQuantitySample *sample in results) {
                                                              sleepTime += [sample.endDate timeIntervalSinceDate:sample.startDate];
                                                          }
                                                          completion(sleepTime, startDate, endDate, error);
                                                      }];
    [self.healthStore executeQuery:query];
}


// Sources
- (void) checkSourcesFromStartDate:(NSDate *)startDate toDate:(NSDate *)endDate{
    NSSortDescriptor *timeSortDesriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    HKQuantityType *quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKSourceQuery *sourceQuery = [[HKSourceQuery alloc] initWithSampleType:quantityType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        NSLog(@"Sources: %@",sources);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.bundleIdentifier = 'com.misfitwearables.Prometheus'"];
        NSArray  *tempResults = [[sources allObjects] filteredArrayUsingPredicate:predicate];
        NSLog(@"Filtered Array : %@", tempResults);
        
        //TODO:
        HKSource *targetedSource = [tempResults firstObject];
        if(targetedSource){
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSource:targetedSource];
            NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:[NSArray arrayWithObject:timeSortDesriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                //results array contains the HKSampleSample objects, whose source is "targetedSource".
                NSLog(@"results: %@",results);
            }];
            [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
        }
    }];
    [[HealthKitProvider sharedInstance].healthStore executeQuery:sourceQuery];
}

# pragma mark - Reading activity time and distance

- (void) readActivityTimeActiveForSampleType:(HKSampleType *)sampleType fromDate:(NSDate *)startDate toDate:(NSDate *)endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
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
            NSDate *startDate = [sampleData startDate];
            NSDate *endDate = [sampleData endDate];
            NSTimeInterval distanceSecond = [endDate timeIntervalSinceDate:startDate];
            
            double distanceMeterPerSecond = distanceMeter / distanceSecond;
            NSNumber *numberMeterPerSecond = [NSNumber numberWithDouble:distanceMeterPerSecond];
            [listOfSpeed addObject:numberMeterPerSecond];
        }
        NSLog(@"total distance %f", totalDistance);
        completion(totalDistance, listOfSpeed, error);
    }];
    [self.healthStore executeQuery:stepQuery];
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
    
    HKQuantitySample *stepsSample = [HKQuantitySample quantitySampleWithType:stepsQuantityType quantity:stepsQuantity startDate:startDate endDate:endDate];
    
    [self.healthStore saveObject:stepsSample withCompletion:^(BOOL success, NSError * _Nullable error) {
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

# pragma mark - Creating HKObservers




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

- (HKObjectType *) hKObjectTypeFromHealthKitDataType:(NSString *) dataType{
    NSDictionary *objectTypeDictionary = @{@"step_count": [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                                 @"walking_running": [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning ],
                                 @"cycling": [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling],
                                 @"sleep_analysis": [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]};
    
    return (HKSampleType *)[objectTypeDictionary objectForKey:dataType];
}

@end
