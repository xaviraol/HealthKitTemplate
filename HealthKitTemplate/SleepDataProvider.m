//
//  SleepDataProvider.m
//  HealthKitTemplate
//
//  Created by Xavier Ramos Oliver on 17/08/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "SleepDataProvider.h"
#import "HealthKitProvider.h"

@implementation SleepDataProvider


+ (SleepDataProvider*) sharedInstance{
    static SleepDataProvider* sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SleepDataProvider alloc] init];
    });
    return sharedInstance;
}

- (id) init {
    self = [super init];
    if (self) {
        self.healthStore = [[HKHealthStore alloc] init];
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        self.calendar = [NSCalendar currentCalendar];
    }
    return self;
}

//Read Real Sleep in a certain Day:
- (void) readRealSleepForDay:(NSDate *)day withCompletion:(void (^) (NSArray *sleepDataPoints, NSTimeInterval totalSleepTime, NSTimeInterval totalBedTime))completion{
    
    NSDate *startDate = [self beginningOfTheDay:day];
    NSDate *endDate = [self endOfTheDay:day];
    
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSourceQuery *sleepSourceQuery = [[HKSourceQuery alloc] initWithSampleType:categoryType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        
        NSArray *acceptedSources = @[@"com.apple.Health"/*,@"com.aliphcom.upopen"*/]; //sleep data from apple health (added by user) and data from Jawbone wearable.
        NSPredicate *sleepSourcePredicate = [NSPredicate predicateWithFormat:@"SELF.bundleIdentifier IN %@",acceptedSources]; //To get only data from
        NSArray  *filteredSources = [[sources allObjects] filteredArrayUsingPredicate:sleepSourcePredicate];
        
        if([filteredSources count] >= 1){
            NSSet *sourceSet = [NSSet setWithArray:filteredSources];
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSources:sourceSet];
            NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:[NSArray arrayWithObject:timeSortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                
                NSTimeInterval sleepTime = 0;
                
                for (HKCategorySample *sample in results) {
                    if (sample.value == HKCategoryValueSleepAnalysisInBed) {// in bed for testing
                        if ([self beginningOfTheDay:sample.startDate] == [self beginningOfTheDay:sample.endDate]) {// si comensa i acaba al mateix dia, sumem directe.
                            sleepTime += [self timeIntervalBetween:sample.startDate andDate:sample.endDate];
                        }else{
                            if ([[self beginningOfTheDay:sample.startDate] compare:[self beginningOfTheDay:day]]  == NSOrderedAscending) {// si comenca abans del dia, sumem a partir del dia fins al end date
                                sleepTime += [self timeIntervalBetween:[self beginningOfTheDay:sample.endDate] andDate:sample.endDate];
                            }else{ // si acaba un cop s'ha acabat el dia, sumem a partir de l'start date fins final del dia.
                                sleepTime += [self timeIntervalBetween:sample.startDate andDate:[self endOfTheDay:sample.startDate]];
                            }
                        }
                    }
                }
                completion(results, sleepTime, sleepTime);//TODOX els resultats son tots els datapoints relacionats amb la data, no estan filtrats. el betTime encara no existeix.
            }];
            [self.healthStore executeQuery:query];
        }
    }];
    [self.healthStore executeQuery:sleepSourceQuery];
}


//Read Ended Sleep in a certain Day:
- (void) readEndedSleepForDay:(NSDate *)day withCompletion:(void (^)(NSArray *sleepDataPoints, NSTimeInterval totalSleepTime, NSTimeInterval totalBedTime))completion{
    
    NSDate *startDate = [self beginningOfTheDay:day];
    NSDate *endDate = [self endOfTheDay:day];
    
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSourceQuery *sleepSourceQuery = [[HKSourceQuery alloc] initWithSampleType:categoryType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        
        NSArray *acceptedSources = @[@"com.apple.Health"/*,@"com.aliphcom.upopen"*/]; //sleep data from apple health (added by user) and data from Jawbone wearable. //TODOX
        NSPredicate *sleepSourcePredicate = [NSPredicate predicateWithFormat:@"SELF.bundleIdentifier IN %@",acceptedSources]; //To get only data from
        NSArray  *filteredSources = [[sources allObjects] filteredArrayUsingPredicate:sleepSourcePredicate];
        
        if([filteredSources count] >= 1){
            NSSet *sourceSet = [NSSet setWithArray:filteredSources];
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSources:sourceSet];
            NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:[NSArray arrayWithObject:timeSortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                
                NSTimeInterval sleepYesterday = 0;//TODOX.
                NSTimeInterval sleepToday = 0;
                
                NSMutableArray *filteredResults = [NSMutableArray new];
                for (HKCategorySample *sample in results) {
                    if (sample.value == HKCategoryValueSleepAnalysisInBed) {// in bed for testing //TODOX
                        // comparing if the dataPoint ends today
                        if ([self beginningOfTheDay:sample.endDate] == [self beginningOfTheDay:day]) {
                            [filteredResults addObject:sample];
                            sleepToday += [self timeIntervalBetween:sample.startDate andDate:sample.endDate];
                        }
                    }
                }
                
                completion(filteredResults, sleepToday, sleepYesterday);//TODOX
            }];
            [self.healthStore executeQuery:query];
        }
    }];
    [self.healthStore executeQuery:sleepSourceQuery];
    
}

//Read ended sleep data between two data points.
- (void) readEndedSleepBetweenDate:(NSDate *)startDate andDate:(NSDate *)endDate withCompletion:(void (^)(NSArray *sleepDataPoints, NSTimeInterval sleepTime, NSTimeInterval bedTime, NSError *error)) completion{

    startDate = [self beginningOfTheDay:startDate];
    endDate = [self endOfTheDay:endDate];
    
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSourceQuery *sleepSourceQuery = [[HKSourceQuery alloc] initWithSampleType:categoryType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        
        NSArray *acceptedSources = @[@"com.apple.Health"/*,@"com.aliphcom.upopen"*/]; //sleep data from apple health (added by user) and data from Jawbone wearable.
        NSPredicate *sleepSourcePredicate = [NSPredicate predicateWithFormat:@"SELF.bundleIdentifier IN %@",acceptedSources]; //To get only data from
        NSArray  *filteredSources = [[sources allObjects] filteredArrayUsingPredicate:sleepSourcePredicate];
        
        if([filteredSources count] >= 1){
            NSSet *sourceSet = [NSSet setWithArray:filteredSources];
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSources:sourceSet];
            NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:[NSArray arrayWithObject:timeSortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                NSLog(@"Results: %@", results);
            }];
            [self.healthStore executeQuery:query];
        }
    }];
    [self.healthStore executeQuery:sleepSourceQuery];

}





// DEPRECATED
//-------------------------------------------------------------------
//-------------------------------------------------------------------


- (void) readSleepForDay:(NSDate *)day withCompletion:(void (^) (NSTimeInterval sleepTime, NSTimeInterval bedTime))completion{
    
    NSDate *startDate = [self beginningOfTheDay:[[NSDate date] dateByAddingTimeInterval:-86400]];
    NSDate *endDate = [self endOfTheDay:[NSDate date]];
    
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSourceQuery *sleepSourceQuery = [[HKSourceQuery alloc] initWithSampleType:categoryType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        
        NSArray *acceptedSources = @[@"com.apple.Health"/*,@"com.aliphcom.upopen"*/]; //sleep data from apple health (added by user) and data from Jawbone wearable.
        NSPredicate *sleepSourcePredicate = [NSPredicate predicateWithFormat:@"SELF.bundleIdentifier IN %@",acceptedSources]; //To get only data from
        NSArray  *tempResults = [[sources allObjects] filteredArrayUsingPredicate:sleepSourcePredicate];
        
        if([tempResults count] >= 1){
            NSSet *sourceSet = [NSSet setWithArray:tempResults];
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSources:sourceSet];
            NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:[NSArray arrayWithObject:timeSortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                
                NSTimeInterval sleepYesterday = 0;
                NSTimeInterval sleepToday = 0;
                
                for (HKCategorySample *sample in results) {
                    if (sample.value == HKCategoryValueSleepAnalysisInBed) {// in bed for testing
                        //comparing sample start date if it is yesterday
                        if ([self.calendar isDateInYesterday:sample.startDate]){
                            if ([self.calendar isDateInYesterday:sample.endDate]) {
                                NSLog(@"STARTED: YESTERDAY, FINISHED: YESTERDAY");
                                //Aqui hem de calcular les hores que sumarem al dia d'ahir
                                sleepYesterday += [sample.endDate timeIntervalSinceDate:sample.startDate];
                            }else if ([self.calendar isDateInToday:sample.endDate]){
                                NSLog(@"STARTED: YESTERDAY, FINISHED: TODAY");
                                //Aqui hem de calcular les hores que sumarem al dia d'avui
                                NSLog(@"Afegirem al yesterday... %f",[[self endOfTheDay:[NSDate dateWithTimeIntervalSinceNow:-86400]] timeIntervalSinceDate:sample.startDate]);//old way to calculate
                                sleepYesterday += [self timeIntervalBetween:sample.startDate andDate:[self endOfTheDay:sample.startDate]];//using new custom method
                                NSLog(@"Afegirem al today... %f",[sample.endDate timeIntervalSinceDate:[self beginningOfTheDay:[NSDate date]]]); //old way to calculate
                                sleepToday += [self timeIntervalBetween:[self beginningOfTheDay:[NSDate date]] andDate:sample.endDate];// using new custom method
                            }
                        }else if ([self.calendar isDateInToday:sample.startDate]){
                            NSLog(@"STARTED: TODAY, FINISHED: unknown");
                            //Aqui hem de calcular les hores que sumarem al dia d'avui
                            sleepToday += [self timeIntervalBetween:sample.startDate andDate:sample.endDate];
                        }
                    }
                }
                NSLog(@"SleepYesterday: %f",sleepYesterday);
                NSLog(@"SleepToday: %f",sleepToday);
                
                
                //not useful
                completion(sleepYesterday, sleepToday);
            }];
            [self.healthStore executeQuery:query];
        }
    }];
    [self.healthStore executeQuery:sleepSourceQuery];
}

- (void) readSleepForVariousDays:(NSDate *)day withCompletion:(void (^) (NSDictionary *days))completion{
    NSTimeInterval whenToStart = -86400 * 2;
    NSDate *startDate = [self beginningOfTheDay:[[NSDate date] dateByAddingTimeInterval:whenToStart]];
    NSDate *endDate = [self endOfTheDay:[NSDate date]];
    
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSourceQuery *sleepSourceQuery = [[HKSourceQuery alloc] initWithSampleType:categoryType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        
        NSArray *acceptedSources = @[@"com.apple.Health"/*,@"com.aliphcom.upopen"*/]; //sleep data from apple health (added by user) and data from Jawbone wearable.
        NSPredicate *sleepSourcePredicate = [NSPredicate predicateWithFormat:@"SELF.bundleIdentifier IN %@",acceptedSources]; //To get only data from
        NSArray  *tempResults = [[sources allObjects] filteredArrayUsingPredicate:sleepSourcePredicate];
        
        if([tempResults count] >= 1){
            NSSet *sourceSet = [NSSet setWithArray:tempResults];
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSources:sourceSet];
            NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:[NSArray arrayWithObject:timeSortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                
                
                NSMutableDictionary *days = [NSMutableDictionary new];
                for (HKCategorySample *sample in results) {
                    if (sample.value == HKCategoryValueSleepAnalysisInBed) {// in bed for testing
                        if ([self beginningOfTheDay:sample.startDate] == [self beginningOfTheDay:sample.endDate]) {
                            
                            NSTimeInterval sleepTimeInCurrentSample = [self timeIntervalBetween:sample.startDate andDate:sample.endDate];
                            
                            NSDate *dateRepresentingThisDay = [self beginningOfTheDay:sample.startDate];
                            
                            NSNumber *existingSleepDataOnThisDay = [days objectForKey:dateRepresentingThisDay];
                            if (existingSleepDataOnThisDay == nil) {
                                existingSleepDataOnThisDay = [NSNumber numberWithInteger:sleepTimeInCurrentSample];
                            }else{
                                existingSleepDataOnThisDay = [NSNumber numberWithInteger:([existingSleepDataOnThisDay integerValue] + sleepTimeInCurrentSample)];
                            }
                            [days setObject:existingSleepDataOnThisDay forKey:dateRepresentingThisDay];
                        }else{
                            //TODO
                            NSTimeInterval sleepTimeInPreviousDay = [self timeIntervalBetween:sample.startDate andDate:[self endOfTheDay:sample.startDate]];
                            NSTimeInterval sleepTimeInCurrentDay = [self timeIntervalBetween:[self beginningOfTheDay:sample.endDate] andDate:sample.endDate];
                            NSArray *arraySleepTimes = @[[NSNumber numberWithInteger:sleepTimeInPreviousDay],[NSNumber numberWithInteger:sleepTimeInCurrentDay]];
                            NSArray *arrayRepresentingDays = @[[self beginningOfTheDay:sample.startDate],[self beginningOfTheDay:sample.endDate]];
                            
                            for (int i = 0; i<[arrayRepresentingDays count]; i++) {
                                NSDate *dateRepresentingThisDay = [arrayRepresentingDays objectAtIndex:i];
                                NSLog(@"Date inside loop: %@",dateRepresentingThisDay);
                                NSNumber *existingSleepDataOnThisDay = [days objectForKey:dateRepresentingThisDay];
                                if (existingSleepDataOnThisDay == nil) {
                                    existingSleepDataOnThisDay = [arraySleepTimes objectAtIndex:i];
                                }else{
                                    existingSleepDataOnThisDay = [NSNumber numberWithInteger:([existingSleepDataOnThisDay integerValue] + [[arraySleepTimes objectAtIndex:i] integerValue])];
                                }
                                [days setObject:existingSleepDataOnThisDay forKey:dateRepresentingThisDay];
                            }
                        }
                    }
                }
                completion (days);
                
                //not useful
                //completion(sleepYesterday, sleepToday);
            }];
            [self.healthStore executeQuery:query];
        }
    }];
    [self.healthStore executeQuery:sleepSourceQuery];
}

- (NSTimeInterval) timeIntervalBetween:(NSDate *)startDate andDate:(NSDate *)endDate{
    return [endDate timeIntervalSinceDate:startDate];
}

//Read total sleep between two dates.
- (void) readSleepFromDate:(NSDate *)startDate toDate:(NSDate *) endDate withCompletion:(void (^)(NSTimeInterval sleepTime, NSTimeInterval bedTime, NSDate *startDate, NSDate *endDate, NSError *error)) completion{
    
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKCategoryType *categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    HKSourceQuery *sleepSourceQuery = [[HKSourceQuery alloc] initWithSampleType:categoryType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error) {
        
        NSArray *acceptedSources = @[@"com.apple.Health"/*,@"com.aliphcom.upopen"*/]; //sleep data from apple health (added by user) and data from Jawbone wearable.
        NSPredicate *sleepSourcePredicate = [NSPredicate predicateWithFormat:@"SELF.bundleIdentifier IN %@",acceptedSources]; //To get only data from
        NSArray  *tempResults = [[sources allObjects] filteredArrayUsingPredicate:sleepSourcePredicate];
        
        if([tempResults count] >= 1){
            NSSet *sourceSet = [NSSet setWithArray:tempResults];
            NSPredicate *sourcePredicate = [HKQuery predicateForObjectsFromSources:sourceSet];
            NSPredicate *stepPredicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            
            NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[sourcePredicate, stepPredicate]];
            
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:[NSArray arrayWithObject:timeSortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                NSLog(@"Results: %@", results);
                NSTimeInterval sleepTime = 0;
                NSTimeInterval bedTime = 0;
                
                for (HKCategorySample *sample in results) {
                    if (sample.value == HKCategoryValueSleepAnalysisAsleep) {
                        NSLog(@"Sample Asleep: %@",sample);
                        sleepTime += [sample.endDate timeIntervalSinceDate:sample.startDate];
                    }else if (sample.value == HKCategoryValueSleepAnalysisInBed){
                        NSLog(@"Sample BedTime: %@",sample);
                        bedTime += [sample.endDate timeIntervalSinceDate:sample.startDate];
                    }
                    [[NSUserDefaults standardUserDefaults] setObject:[self.dateFormatter stringFromDate:sample.endDate] forKey:@"lastSavedSleepDate"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                completion(sleepTime, bedTime, startDate, endDate, error);
            }];
            [self.healthStore executeQuery:query];
        }
    }];
    [self.healthStore executeQuery:sleepSourceQuery];
}

#pragma mark - Helper methods

- (NSDate *) beginningOfTheDay:(NSDate *)date{
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    [components setHour:00];
    [components setMinute:00];
    [components setSecond:00];
    
    NSDate *beginningOfTheDay = [gregorianCalendar dateFromComponents:components];
    return  beginningOfTheDay;
}

- (NSDate *) endOfTheDay:(NSDate *)date{
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
    NSDate *endOfTheDay = [gregorianCalendar dateFromComponents:components];
    return  endOfTheDay;

}

@end
