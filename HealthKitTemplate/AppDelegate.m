//
//  AppDelegate.m
//  HealthKitTemplate
//
//  Created by Sense Health on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "AppDelegate.h"
#import "HealthKitProvider.h"
#import <sys/sysctl.h>


static NSString* kHEALTHKIT_AUTHORIZATION = @"healthkit_authorization";

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
//        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
//    }
    
    // Override point for customization after application launch.
    //[[HealthKitProvider sharedInstance] startObservingStepChanges];
    //[self dateTesting];
    return YES;
}

- (BOOL) deviceHasMotionSensor{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    NSArray *devicesWithoutMotionSensor = @[@"iPhone6,1",@"iPhone6,2",@"iPhone7,1",@"iPhone7,2",@"iPhone8,1",@"iPhone8,2",@"x86_64",@"i386"];
    return [devicesWithoutMotionSensor containsObject:platform];
}

- (NSDate *) beginningOfTheDay:(NSDate *)date{
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *beginningOfTheDay = [gregorianCalendar dateFromComponents:components];
    NSLog(@"BEGINNING OF TODAY: %@",beginningOfTheDay);
    
    return  beginningOfTheDay;
//    NSDate *end = [beginningOfTheDay dateByAddingTimeInterval:3600*24];
//    NSLog(@"END OF TODAY: %@",end);
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
