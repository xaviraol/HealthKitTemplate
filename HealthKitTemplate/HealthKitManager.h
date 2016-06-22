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

@property (nonatomic, retain) HKHealthStore *healthStore;

/**
 * Requests the user to acces HealthKit data. It already contains the needed types of data for our app.
 *
 *  @param completion block with a success boolean and an error.
 */
- (void) requestHealthKitAuthorization:(void(^)(BOOL success, NSError *error))completion;

/**
 * Reads the user's timeActive within a temporal range from HealthKit. This method works for both 'walking&running' and 'cycling' dataTypes.
 *
 *  @param sampleType type of sample where to get info
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with the timeActive and an error.
 */
- (void) readTimeActiveForSampleType:(HKSampleType *) sampleType fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;

/**
 * Reads the user's coveredDistance within a temporal range from HealthKit. This method works for both 'walking&running' and 'cycling' dataTypes.
 *
 *  @param sampleType type of sample where to get info
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with totalDistance, an array of speedAverage of each sample and an error.
 */
- (void) readCoveredDistanceForSampleType:(HKSampleType *)sampleType fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion;

/**
 * Reads the user's timeActive within a temporal range from HealthKit. This method is intended for only extract the data from 'stepsCount' dataType.
 *
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with the timeActive, the total number of steps and an error.
 */
- (void) readStepsTimeActiveFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSInteger totalSteps, NSError *error))completion;

/**
 * Reads the user's sleepTime within a temporal range from HealthKit.
 *
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with the sleepTime, and an error.
 */
- (void) readSleepAnalysisFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval sleepTime, NSError *error))completion;

/**
 * Reads the user's heartRate within a temporal range from HealthKit.
 *
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with the bpm (beats per minute), and an error.
 */
- (void) readHeartRateFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double bpm, NSError *error)) completion;

/**
 * Enables HealthKit to alert the app of new changes of matching data.
 *
 *  @param sampleType sample to get info of
 *  TODO: Not finished, at this moment it's only used for walking&running and cycling types of samples to get their covered distance.
 */
- (void) setTimeActiveOnBackgroundForSampleType:(HKSampleType*) sampleType;

/**
 * Helper methods to add custom data to Healthkit.
 */
- (void) writeWalkingRunningDistance:(double)distance fromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion;
- (void) writeCyclingDistance:(double)distance fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion;
- (void) writeSteps:(double)steps fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion;
- (void) writeSleepAnalysisFromStartDate:(NSDate*)startDate toEndDate:(NSDate*)endDate withCompletion:(void (^)(bool savedSuccessfully, NSError *error))completion;

@end
