//
//  HKStepCounterSensor.m
//  SenseService
//
//  Created by Xavier Ramos Oliver on 28/06/16.
//
//

#import "HKStepCounterSensor.h"
#import "HealthKitProvider.h"
#import <UIKit/UIKit.h>

@implementation HKStepCounterSensor

- (void) onStepsUpdate{
    
    [self getCumulativeStepsWithCompletion:^(int steps, NSError *error) {
        NSLog(@"steps recollits: %d",steps);
        
        [[NSUserDefaults standardUserDefaults]setValue:[NSNumber numberWithInteger:steps] forKey:@"cumulativeSteps"];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }];
}

- (void) getCumulativeStepsWithCompletion:(void (^)(int steps, NSError *error))completion{
    
    HKQuantityType *stepCountType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSLog(@"stepCountType : %@",stepCountType);
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:stepCountType quantitySamplePredicate:nil options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
        completion((int)[result.sumQuantity doubleValueForUnit:[HKUnit countUnit]],error);
    }];
    
    [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
}

- (void) setTimeActiveOnBackgroundForStepCountSamples{
    
    HKSampleType *stepCountType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKObserverQuery *query = [[HKObserverQuery alloc] initWithSampleType:stepCountType predicate:nil updateHandler:^(HKObserverQuery *query, HKObserverQueryCompletionHandler completionHandler, NSError *error) {
        if (error) {
            NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***",
                  error.localizedDescription);
            abort();
        }
        [self onStepsUpdate];
    }];
    
    [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
    [[HealthKitProvider sharedInstance].healthStore enableBackgroundDeliveryForType:stepCountType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error){
        if (success) {
            NSLog(@"success background changes");
        }
    }];
}


@end
