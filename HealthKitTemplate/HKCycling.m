//
//  HKCycling.m
//  HealthKitTemplate
//
//  Created by Xavier Ramos Oliver on 22/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "HKCycling.h"


@implementation HKCycling

- (void) readCyclingTimeActiveFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    
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
    [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
}

- (void) readMostRecentCyclingTimeActiveSampleWithCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion{
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
    //TODO: what happens when a user adds a data point with a past startDate? HealthKit tell us that there is a change and we will retrieve the more newer startDate sample and not the most recent added.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                           predicate:nil
                                                               limit:1
                                                     sortDescriptors:@[sortDescriptor]
                                                      resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                                                          NSTimeInterval timeActive = 0;
                                                          HKQuantitySample *sample = results[0];
                                                          if ([sample.endDate isEqualToDate:sample.startDate]) {
                                                              //In case of a manually added sample: (when startDate is equal as endDate)
                                                              double distance = [[sample quantity] doubleValueForUnit:[HKUnit meterUnitWithMetricPrefix:HKMetricPrefixKilo]];
                                                              double averageWalkingSpeed = 5.0; //5.0 km/h
                                                              timeActive = distance/averageWalkingSpeed * 3600;
                                                          }else{
                                                              timeActive += [sample.endDate timeIntervalSinceDate:sample.startDate];
                                                          }
                                                          completion(timeActive,error);
                                                      }];
    [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
}

- (void) setTimeActiveOnBackgroundForCyclingSample{
    
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
    HKObserverQuery *query = [[HKObserverQuery alloc] initWithSampleType:sampleType predicate:nil updateHandler:^(HKObserverQuery *query, HKObserverQueryCompletionHandler completionHandler, NSError *error) {
        if (error) {
            NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***",
                  error.localizedDescription);
            abort();
        }
        [self readMostRecentCyclingTimeActiveSampleWithCompletion:^(NSTimeInterval timeActive, NSError *error) {
            NSLog(@"Added walking dataPoint: %.2f seconds", timeActive);
        }];
    }];
    
    [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
    [[HealthKitProvider sharedInstance].healthStore enableBackgroundDeliveryForType:sampleType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error){
        if (success) {
            NSLog(@"success background changes");
        }
    }];
}

@end
