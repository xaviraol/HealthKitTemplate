//
//  HKWalkingRunning.h
//  HealthKitTemplate
//
//  Created by Xavier Ramos Oliver on 22/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HealthKitProvider.h"

@interface HKWalkingRunning : NSObject

/**
 * Reads the user's timeActive within a temporal range from HealthKit. This method works for both 'walking&running' and 'cycling' dataTypes.
 *
 *  @param sampleType type of sample where to get info
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with the timeActive and an error.
 */
- (void) readTimeActiveFromWalkingAndRunningfromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;

/**
 * Reads the user's timeActive of the last Walking&Running sample added to HealthKit.
 *
 *  @param sampleType type of sample where to get info
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with the timeActive and an error.
 */
- (void) readLastTimeActiveWalkingRunningSampleWithCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;

/**
 * Enables HealthKit to alert app of new changes of walking&running data.
 */
- (void) setTimeActiveOnBackgroundForWalkingRunningSample;

@end
