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
    
    HKSourceQuery *sourceQuery = [[HKSourceQuery alloc] initWithSampleType:stepCountType samplePredicate:nil completionHandler:^(HKSourceQuery * _Nonnull query, NSSet<HKSource *> * _Nullable sources, NSError * _Nullable error) {
        
        NSMutableArray  *sourceArray = [[NSMutableArray alloc] init];
        for (HKSource *source in sources) {
            if ([source.bundleIdentifier hasPrefix:@"com.apple"]) {
                [sourceArray addObject:source];
            }
        }
        
        if([sourceArray count]){
            NSSet *sourceSet = [[NSSet alloc] initWithArray:sourceArray];
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSources:sourceSet];
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:stepCountType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
                completion((int)[result.sumQuantity doubleValueForUnit:[HKUnit countUnit]],error);
            }];
            [self.healthStore executeQuery:query];
        }
    }];
    [self.healthStore executeQuery:sourceQuery];
}

- (void) readStepsTimeActiveFromDate:(NSDate *)startDate toDate:(NSDate *)endDate withCompletion:(void (^)(NSTimeInterval timeInterval, NSError *error))completion{
    HKSampleType *type = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
    NSSortDescriptor *stepSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKSourceQuery *sourceQuery = [[HKSourceQuery alloc] initWithSampleType:type samplePredicate:nil completionHandler:^(HKSourceQuery * _Nonnull query, NSSet<HKSource *> * _Nullable sources, NSError * _Nullable error) {
        //NSLog(@"All Sources: %@",sources);
        //NSLog(@"%@",[[UIDevice currentDevice] name]);

        NSMutableArray  *sourceArray = [[NSMutableArray alloc] init];
        for (HKSource *source in sources) {
            if ([source.bundleIdentifier hasPrefix:@"com.apple"]) {
                [sourceArray addObject:source];
            }
        }
        //NSLog(@"Filtered Array of sources for Steps : %@", sourceArray);
        
        if([sourceArray count]){
            NSSet *sourceSet = [[NSSet alloc] initWithArray:sourceArray];
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSources:sourceSet];
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];

            HKSampleQuery *stepQuery = [[HKSampleQuery alloc] initWithSampleType:type predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[stepSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *hkSample, NSError *error){
                
                NSTimeInterval totalTime = 0;
                NSDate *lastStepDataPoint;
                NSDate *stepDataPointDate;
                
                int timeBetweenDataPoints = 300;
                
                for (int i = 0; i < [hkSample count]; i++) {
                    HKQuantitySample *stepDataPoint = [hkSample objectAtIndex:i];
                    int steps = [[stepDataPoint quantity] doubleValueForUnit:[HKUnit countUnit]];
                    if (steps >= 45) {
                        if (steps >= 200) {
                            timeBetweenDataPoints = 400;
                        }
                        stepDataPointDate = [stepDataPoint startDate];
                        NSTimeInterval secondsBetweenDataPoints = [stepDataPointDate timeIntervalSinceDate:lastStepDataPoint];
                        if (secondsBetweenDataPoints <= timeBetweenDataPoints) {
                            totalTime += secondsBetweenDataPoints;
                        }
                    }
                    lastStepDataPoint = stepDataPointDate;
                }
                completion(totalTime, error);
            }];
            
            [self.healthStore executeQuery:stepQuery];
        }
    }];
    
    [self.healthStore executeQuery:sourceQuery];
    

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

- (void) readSleepFromDate:(NSDate *)startDate toDate:(NSDate *) endDate withCompletion:(void (^)(NSTimeInterval sleepTime, NSTimeInterval bedTime, NSDate *startDate, NSDate *endDate, NSError *error)) completion{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSourceQuery *sleepSourceQuery = [[HKSourceQuery alloc] initWithSampleType:categoryType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        NSLog(@"All Sources: %@",sources);

        NSArray *acceptedSources = @[@"com.apple.Health",@"com.aliphcom.upopen"];
        NSPredicate *sleepSourcePredicate = [NSPredicate predicateWithFormat:@"SELF.bundleIdentifier IN %@",acceptedSources]; //To get only data from
        NSArray  *tempResults = [[sources allObjects] filteredArrayUsingPredicate:sleepSourcePredicate];
        HKSource *targetedSource = [tempResults firstObject];
        
        if(targetedSource){ //if there's jawbone
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSource:targetedSource];
            NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:[NSArray arrayWithObject:timeSortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                
                NSTimeInterval sleepTime = 0;
                NSTimeInterval bedTime = 0;
                
                for (HKCategorySample *sample in results) {
                    if (sample.value == HKCategoryValueSleepAnalysisAsleep) {
                        NSLog(@"Sample: %@",sample);
                        sleepTime += [sample.endDate timeIntervalSinceDate:sample.startDate];
                    }else if (sample.value == HKCategoryValueSleepAnalysisInBed){
                        bedTime += [sample.endDate timeIntervalSinceDate:sample.startDate];
                    }
                    [[NSUserDefaults standardUserDefaults] setObject:[dateFormatter stringFromDate:sample.endDate] forKey:@"lastSavedSleepDate"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                completion(sleepTime, bedTime, startDate, endDate, error);
            }];
            [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
        }
    }];
    
    [[HealthKitProvider sharedInstance].healthStore executeQuery:sleepSourceQuery];
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

#pragma mark - Writting data to HealthKit

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
#pragma mark - Dealing with HKSources

- (void) getAllSourcesForDataType:(NSString *)dataType withCompletion:(void (^) (NSArray *sources, NSError *error))completion{
    HKSampleType *sampleType = (HKSampleType *)[self hKObjectTypeFromHealthKitDataType:dataType];
    
    HKSourceQuery *sourceQuery = [[HKSourceQuery alloc] initWithSampleType:sampleType samplePredicate:nil completionHandler:^(HKSourceQuery * _Nonnull query, NSSet<HKSource *> * _Nullable sources, NSError * _Nullable error) {
        if ([sources count]){
            completion([sources allObjects], error);
        } else {
            completion(nil, error);
        }
    }];
    [self.healthStore executeQuery:sourceQuery];
}

- (void) retrievengSleepForACertainSource{
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKSourceQuery *sleepSourceQuery = [[HKSourceQuery alloc] initWithSampleType:sampleType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        NSLog(@"All Sources: %@",sources);
        NSPredicate *sleepSourcePredicate = [NSPredicate predicateWithFormat:@"SELF.bundleIdentifier = 'com.aliphcom.upopen'"];
        NSArray  *tempResults = [[sources allObjects] filteredArrayUsingPredicate:sleepSourcePredicate];
        NSLog(@"Filtered Array for Sleep : %@", tempResults);
        
        HKSource *targetedSource = [tempResults firstObject];
        if(targetedSource){
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSource:targetedSource];
            NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:[self getYesterdayAtFiveDate] endDate:[self getTodayAtFiveDate] options:HKQueryOptionNone];
            
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:[NSArray arrayWithObject:timeSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                //results array contains the HKSampleSample objects, whose source is "targetedSource".
                NSLog(@"Results: %@",results);
            }];
            [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
        }
    }];
    [[HealthKitProvider sharedInstance].healthStore executeQuery:sleepSourceQuery];
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
