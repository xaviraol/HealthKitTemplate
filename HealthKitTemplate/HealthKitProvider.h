//
//  HealthKitProvider.h
//  HealthKitTemplate
//
//  Created by Sense Health on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/Healthkit.h>

@interface HealthKitProvider : NSObject

+ (HealthKitProvider*)sharedInstance;

@property (nonatomic, retain) HKHealthStore *healthStore;

# pragma mark - Healthkit Permissions

/**
 *
 *   This method asks the user for the permissions to access Healthkit data. In this case, we ask for the
 *   permissions of the different data types at once. So the user can enable all of them at the same time. A part from that, with this method
 *   we ask for to read data that already exists in Healthkit and also to write new data to Healthkit.
 *
 *   In this example, we ask permissions for: Walking and Running, Cycling, Step counter and Sleep Analysis.
 *
 **/
- (void) requestHealthKitAuthorization:(void(^)(BOOL success, NSError *error))completion;

/**
 *
 *   Similar as the previous method, but here we have a dataType string as an input.
 *   So in this method we ask permissions for only one dataType. In this case, we ask for permissions for a QuantityType.
 *   In this examples, our quantityTypes are stepCounter, walking and running, and cycling.
 *
 **/
- (void) requestHealthKitAuthorizationForHKDataQuantityType:(NSString*)dataType withCompletion:(void(^)(BOOL success, NSError *error))completion;

/**
 *
 *   requestHealthKitAuthorizationForHKDataCategoryType: In this case, we ask for permissions for a QuantityType.
 *   In this examples, we have only one category type, sleep analysis.
 *
 **/
- (void) requestHealthKitAuthorizationForHKDataCategoryType:(NSString*)dataType withCompletion:(void(^)(BOOL success, NSError *error))completion;


#pragma mark - Reading data from Healthkit

/**
 *  It reads the cumulative steps between two given dates.
 *
 **/
- (void) readCumulativeStepsFrom:(NSDate *)startDate toDate:(NSDate *)endDate withCompletion:(void (^)(int steps, NSError *error))completion;

/**
 *  Using the dates that a stepCount dataPoint has, this method calculates an aproximation of the time that the user has been active between two different dates.
 *  It uses a simple algorithm, with two simple rules: 1. If the stepCount value is lower than 45 steps, it discards it. 2. If the difference between two different
 *  dataPoints is higher than 200 seconds, it considers that the user has not been moving between this time. (While moving, healhtkit sends dataPoints at least every
 *  two minutes.
 *
 **/
- (void) readStepsTimeActiveFromDate:(NSDate*)startDate toDate:(NSDate*)endDate withCompletion:(void (^)(NSTimeInterval timeInterval, NSError *error))completion;


//reading walking and running
- (void) readWalkingTimeActiveFromDate:(NSDate*) startDate toDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;

- (void) readCoveredWalkingDistanceFromDate:(NSDate *)startDate toDate:(NSDate*)endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion;


//reading cycling
- (void) readCyclingTimeActiveFromDate:(NSDate*) startDate toDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;

- (void) readCoveredCyclingDistanceFromDate:(NSDate *)startDate toDate:(NSDate*)endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion;


//-------------------------------------
- (void) startObservingStepChanges;
- (void) startObservingCyclingChanges;
/**
 * Reads the user's walking timeActive within a temporal range from HealthKit.
 *
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with the timeActive and an error.
 */
- (void) readWalkingTimeActiveFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;
/**
 * Reads the user's timeActive of the last walking&running sample added to HealthKit.
 *
 *  @param completion block with the timeActive and an error.
 */
- (void) readMostRecentWalkingTimeActiveSampleWithCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;

/**
 * Enables HealthKit to alert app of new changes of walking&running data.
 */
- (void) setTimeActiveOnBackgroundForWalkingSample;

/**
 * Reads the user's walking timeActive within a temporal range from HealthKit.
 *
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with the timeActive and an error.
 */
- (void) readCyclingTimeActiveFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;
/**
 * Reads the user's timeActive of the last walking&running sample added to HealthKit.
 *
 *  @param completion block with the timeActive and an error.
 */
- (void) readMostRecentCyclingTimeActiveSampleWithCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;

/**
 * Enables HealthKit to alert app of new changes of walking&running data.
 */
- (void) setTimeActiveOnBackgroundForCyclingSample;

- (void) provesBackground;


/**
 * Reads the user's coveredDistance within a temporal range from HealthKit. This method works for both 'walking&running' and 'cycling' dataTypes.
 *
 *  @param sampleType type of sample where to get info
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with totalDistance, an array of speedAverage of each sample and an error.
 */
//- (void) readCoveredDistanceForSampleType:(HKSampleType *)sampleType fromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(double totalDistance, NSArray * listOfSpeed, NSError *error)) completion;

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
