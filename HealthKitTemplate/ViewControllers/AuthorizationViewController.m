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
@property (nonatomic,weak) IBOutlet UISwitch *generalSwitch;
@property (nonatomic,weak) IBOutlet UISwitch *stepCountSwitch;
@property (nonatomic,weak) IBOutlet UISwitch *walkingSwitch;
@property (nonatomic,weak) IBOutlet UISwitch *cyclingSwitch;
@property (nonatomic,weak) IBOutlet UISwitch *sleepSwitch;


@end

@implementation AuthorizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _registrationFeedback.text = @"";
    
    int allOfThem;
    if ([self getAuthorizationValueFor:@"step_count"]) {
        [_stepCountSwitch setOn:YES];
        allOfThem+=1;
    }
    if ([self getAuthorizationValueFor:@"walking_running"]) {
        [_walkingSwitch setOn:YES];
        allOfThem+=1;
    }
    if ([self getAuthorizationValueFor:@"cycling"]) {
        [_cyclingSwitch setOn:YES];
        allOfThem+=1;
    }
    if ([self getAuthorizationValueFor:@"sleep_analysis"]) {
        [_sleepSwitch setOn:YES];
        allOfThem+=1;
    }
    if (allOfThem == 4) {
        [_generalSwitch setOn:YES];
    }
    
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
                    [self saveToUserDefaultsAuthorizationFor:dataTypes];
                    [_sleepSwitch setOn:YES];
                    [_stepCountSwitch setOn:YES];
                    [_walkingSwitch setOn:YES];
                    [_cyclingSwitch setOn:YES];
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
                    [self saveToUserDefaultsAuthorizationFor:dataTypes];
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
                    [self saveToUserDefaultsAuthorizationFor:dataTypes];
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
                    [self saveToUserDefaultsAuthorizationFor:dataTypes];
                });
            }
        }];
        
    }else{
        //disable HealthKit
    }
}

- (IBAction)cyclingIntegrationButtonSwitched:(UISwitch*)sender{
    if (sender.isOn) {
        
        NSArray *dataTypes = @[@"cycling"];
        
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorizationForDataTypes:dataTypes withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Authorization succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                    [self saveToUserDefaultsAuthorizationFor:dataTypes];
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


- (void) saveToUserDefaultsAuthorizationFor:(NSArray *)dataTypes{
    
    for (int i = 0; i < dataTypes.count; i++) {
        NSString *stringKey = [NSString stringWithFormat:@"%@_authorization",dataTypes[i]];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:stringKey];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) getAuthorizationValueFor:(NSString *)dataType{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_authorization",dataType]];
}

@end
