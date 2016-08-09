//
//  AuthorizationViewController.m
//  HealthKitTemplate
//
//  Created by Sense Health on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "AuthorizationViewController.h"
#import "HealthKitProvider.h"
#import <sys/sysctl.h>


@interface AuthorizationViewController ()

@property (nonatomic,weak) IBOutlet UILabel *registrationFeedback;

@end

@implementation AuthorizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _registrationFeedback.text = @"";
}

- (IBAction) healthIntegrationButtonSwitched:(UISwitch*)sender {
    
    if (sender.isOn) {
        
        NSArray *dataTypes = @[@"step_count",
                               @"walking_running",
                               @"cycling",
                               @"sleep_analysis"];
        
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorizationForDataTypes:dataTypes withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Authorization succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                });
            }
        }];
        
    }else{
        //disable HealthKit
    }
}

- (IBAction)stepCountsIntegrationButtonSwitched:(UISwitch*)sender{
    if (sender.isOn) {
        
        NSArray *dataTypes = @[@"step_count"];
        
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorizationForDataTypes:dataTypes withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Authorization succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                });
            }
        }];
        
    }else{
        //disable HealthKit
    }
}

- (IBAction)sleepAnalysisIntegrationButtonSwitched:(UISwitch*)sender{
    if (sender.isOn) {
        
        NSArray *dataTypes = @[@"sleep_analysis"];
        
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorizationForDataTypes:dataTypes withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Authorization succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                });
            }
        }];
        
    }else{
        //disable HealthKit
    }
}

- (IBAction)walkingIntegrationButtonSwitched:(UISwitch*)sender{
    if (sender.isOn) {
        
        NSArray *dataTypes = @[@"walking_running"];
        
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorizationForDataTypes:dataTypes withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Authorization succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                });
            }
        }];
        
    }else{
        //disable HealthKit
    }
}

#pragma mark - Helper methods.

/**
 *  Method used to know if a device has the Motion sensor. iPhone 5c and lower models doesn't have it, so the detection of steps, walking is not provided from 
 *  the iPhone itself. We will consider, at this point, to not use HealthKit for this models.
 *
 *  @returns bool whether the device has the motion or not.
 */

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


@end
