//
//  HealthKitManager.h
//  HealthKitTemplate
//
//  Created by Xavier Ramos Oliver on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <HealthKit/Healthkit.h>

@interface HealthKitManager : NSObject

+ (HealthKitManager*) sharedManager;


//Authorization:
- (void) requestAuthorization;

//BirthDate:
- (NSDate *) readBirthDate;

//Weight:
- (void) writeWeightSample:(CGFloat)weight;


//Workout:
- (void) writeWorkoutSamplewithStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate withDistance:(double)distance withDistanceUnit:(HKUnit*)distanceUnit withKiloCalories:(double)kiloCalories;


//StepCount:
- (void) readStepsCount;
- (void) writeStepsCountnumberOfSteps:(int)steps fromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate;

//Activity time:
- (void) getActivityTimeFromHealthkit;
- (void) getActivitySumaries;
- (void) writeWalkingRunningDistanceFromDate:(NSDate*)startDate andEndDate:(NSDate*)endDate;
- (void)getQuantativeDataFromTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double value, NSError *error))completionHandler;

@end
