//
//  HKCycling.h
//  HealthKitTemplate
//
//  Created by Xavier Ramos Oliver on 22/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HealthKitProvider.h"

@interface HKCycling : NSObject

/**
 * Reads the user's cycling timeActive within a temporal range from HealthKit.
 *
 *  @param sampleType type of sample where to get info
 *  @param startDate date to start counting
 *  @param endDate date to end counting
 *  @param completion block with the timeActive and an error.
 */
- (void) readCyclingTimeActiveFromStartDate:(NSDate*) startDate toEndDate:(NSDate*) endDate withCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;

/**
 * Reads the user's timeActive of the last cycling sample added to HealthKit.
 *
 *  @param completion block with the timeActive and an error.
 */
- (void) readMostRecentCyclingTimeActiveSampleWithCompletion:(void (^)(NSTimeInterval timeActive, NSError *error))completion;

/**
 * Enables HealthKit to alert app of new changes of cycling data.
 */
- (void) setTimeActiveOnBackgroundForCyclingSample;

@end
