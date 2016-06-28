//
//  AppDelegate.m
//  HealthKitTemplate
//
//  Created by Sense Health on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "AppDelegate.h"
#import "HealthKitProvider.h"


static NSString* kHEALTHKIT_AUTHORIZATION = @"healthkit_authorization";

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    //TODO: Right now we only check if we have an authorization for some kind of data, but nos specifically the one which we'll use.
    HKQuantityType *stepCountType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    [[HealthKitProvider sharedInstance].healthStore enableBackgroundDeliveryForType:stepCountType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error) {}];
    
    HKQuery *query = [[HKObserverQuery alloc] initWithSampleType:stepCountType predicate:nil updateHandler:
                      ^void(HKObserverQuery *query, HKObserverQueryCompletionHandler completionHandler, NSError *error)
                      {
                          //If we don't call the completion handler right away, Apple gets mad. They'll try sending us the same notification here 3 times on a back-off algorithm.  The preferred method is we just call the completion handler.  Makes me wonder why they even HAVE a completionHandler if we're expected to just call it right away...
                          if (completionHandler) {
                              completionHandler();
                          }
                          //HANDLE DATA HERE
                          NSLog(@"nova dada afegida!");
                      }];
    [[HealthKitProvider sharedInstance].healthStore executeQuery:query];
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    NSLog(@"Background fetch started...");
    
    //---do background fetch here---
    // You have up to 30 seconds to perform the fetch
    
    BOOL downloadSuccessful = YES;
    
    if (downloadSuccessful) {
        //---set the flag that data is successfully downloaded---
        completionHandler(UIBackgroundFetchResultNewData);
    } else {
        //---set the flag that download is not successful---
        completionHandler(UIBackgroundFetchResultFailed);
    }
    
    NSLog(@"Background fetch completed...");
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
