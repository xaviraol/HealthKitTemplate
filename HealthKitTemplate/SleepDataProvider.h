//
//  SleepDataProvider.h
//  HealthKitTemplate
//
//  Created by Xavier Ramos Oliver on 17/08/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/Healthkit.h>

@interface SleepDataProvider : NSObject

+ (SleepDataProvider *) sharedInstance;

@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) NSCalendar *calendar;

- (void) readEndedSleepForDay:(NSDate *)day withCompletion:(void (^) (NSArray *sleepDataPoints, NSTimeInterval totalSleepTime, NSTimeInterval totalBedTime))completion;

- (void) readRealSleepForDay:(NSDate *)day withCompletion:(void (^) (NSArray *sleepDataPoints, NSTimeInterval totalSleepTime, NSTimeInterval totalBedTime))completion;

- (void) readSleepForVariousDays:(NSDate *)day withCompletion:(void (^) (NSDictionary *days))completion;

- (void) readRealSleepBetweenDate:(NSDate *)startDate andDate:(NSDate *)endDate withCompletion:(void (^)(NSTimeInterval sleepTime, NSTimeInterval bedTime, NSDate *startDate, NSDate *endDate, NSError *error)) completion;

- (void) readEndedSleepBetweenDate:(NSDate *)startDate andDate:(NSDate *)endDate withCompletion:(void (^)(NSTimeInterval sleepTime, NSTimeInterval bedTime, NSDate *startDate, NSDate *endDate, NSError *error)) completion;




//---------------------------------------------
//---------------------------------------------
//Read total sleep between two dates.
//Aquest ha de ser el model pels dos ultims metodes que apareixen en la llista superior. ara per ara te en compte tots els datapoints implicats.
- (void) readSleepFromDate:(NSDate *)startDate toDate:(NSDate *) endDate withCompletion:(void (^)(NSTimeInterval sleepTime, NSTimeInterval bedTime, NSDate *startDate, NSDate *endDate, NSError *error)) completion;

//Read sleep from lastSavedDate until now.
- (void) readNewSleepDataPointsWithCompletion:(void (^) (NSArray *sleepArray))completion;

//Read different sleep packs




- (void) readSleepForDay:(NSDate *)day withCompletion:(void (^) (NSTimeInterval sleepTime, NSTimeInterval bedTime))completion;
@end
