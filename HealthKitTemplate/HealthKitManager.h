//
//  HealthKitManager.h
//  HealthKitTemplate
//
//  Created by Sense Health on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/Healthkit.h>

@interface HealthKitManager : NSObject

+ (HealthKitManager*)sharedInstance;

// Request authorization:
- (void) requestHealthKitAuthorization:(void(^)(BOOL success, NSError *error))completion;

// Reading timeActive from sampleTypes like walking&running or Cycling:
- (void) readTimeActiveForSampleType:(HKSampleType *) sampleType fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeInterval, NSError *error))completion;

// Reading distanceCovered and speed from sampleTypes like walking&running or cycling:
- (void) readCoveredDistanceForSampleType:(HKSampleType *)sampleType fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) onCompleted;

// Reading timeActive and totalSteps from stepCounter:
- (void) readStepsTimeActiveFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeInterval, NSInteger totalSteps, NSError *error))completion;

// Reading sleepAnalysis info:
- (void) readSleepAnalysisFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval sleepTime, NSError *error))completion;

// Reading heartRate info:
- (void) readHeartRateFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double bpm, NSError *error)) onCompleted;

// Enabling background connection for a certain type of sample:
- (void) setTimeActiveOnBackgroundForSampleType:(HKSampleType*) sampleType;

// Writting new data to HealthKit store.
- (void) writeWalkingRunningDistance:(double)distance fromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion;
- (void) writeCyclingDistance:(double)distance fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion;
- (void) writeSteps:(double)steps fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion;
- (void) writeSleepAnalysisFromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion;

@end
