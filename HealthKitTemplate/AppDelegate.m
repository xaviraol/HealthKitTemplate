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
    UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];

    NSLog(@"AUTHORIZATION STATE: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
//    NSArray *quantityTypesUsedInApp = @[HKQuantityTypeIdentifierStepCount];
//    
//    for (NSString *identifier in quantityTypesUsedInApp) {
//        
//        HKQuantityType *sampleType = [HKQuantityType quantityTypeForIdentifier:identifier];
//        NSSet *requestSampleUnit = [NSSet setWithObject:sampleType];
//        
//        [[HealthKitProvider sharedInstance].healthStore preferredUnitsForQuantityTypes:requestSampleUnit completion:^(NSDictionary *preferredUnits, NSError *error) {
//            
//            if (!error) {
//                
//                HKUnit *unit = [preferredUnits objectForKey:sampleType];
//                NSLog(@"%@ : %@", sampleType.identifier, unit.unitString);
//                //sampleType enabled for read
//                
//            } else {
//                
//                switch (error.code) {
//                    case 5:
//                        
//                        NSLog(@"%@ access denied", sampleType.identifier);
//                        //sampleType denied for read
//                        break;
//                        
//                    default:
//                        NSLog(@"request preffered quantity types error: %@", error);
//                        break;
//                }
//                
//                
//            }
//            
//        }];
//    }

    NSLog(@"CumulativeSteps = %@",[[NSUserDefaults standardUserDefaults] valueForKey:@"cumulativeSteps"]);
    return YES;
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
