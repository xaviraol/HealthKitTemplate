//
//  AuthorizationViewController.m
//  HealthKitTemplate
//
//  Created by Sense Health on 16/06/16.
//  Copyright © 2016 SenseHealth. All rights reserved.
//

#import "AuthorizationViewController.h"
#import "HealthKitProvider.h"

@interface AuthorizationViewController ()

@property (nonatomic,weak) IBOutlet UILabel *registrationFeedback;

@end

@implementation AuthorizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _registrationFeedback.text = @"";
}
- (void) viewDidAppear:(BOOL)animated{
    NSLog(@"[viewDidAppear] StepCount: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
    NSLog(@"[viewDidAppear] SleepAnalysis: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]]);
    NSLog(@"[viewDidAppear] Walking: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) healthIntegrationButtonSwitched:(UISwitch*)sender {
    
    if (sender.isOn) {
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorization:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"[healthIntegration] Succeeded! StepCount: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                NSLog(@"[viewDidLoad] Succeeded! SleepAnalysis: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]]);
                NSLog(@"[healthIntegration] Succeeded! Walking: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Authorization succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                });
            }else{
                NSLog(@"[healthIntegration] Failed! StepCount: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                NSLog(@"[viewDidLoad] Failed! SleepAnalysis: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]]);
                NSLog(@"[healthIntegration] Failed! Walking: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Authorization failed!"];
                    _registrationFeedback.textColor = [UIColor redColor];
                });
            }
        }];
    }else{
        //disable HealthKit
    }
}

- (IBAction)stepCountsIntegrationButtonSwitched:(UISwitch*)sender{
    if (sender.isOn) {
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorizationForHKDataQuantityType:@"HKStepCounter" withCompletion:^(BOOL success, NSError *error){
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"StepCount succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                    NSLog(@"[stepCountIntegration] Succeeded! StepCount: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                    NSLog(@"[stepCountIntegration] Succeeded! SleepAnalysis: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]]);
                     NSLog(@"[stepCountIntegration] Succeeded! Walking: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]]);
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"StepCount failed!"];
                    _registrationFeedback.textColor = [UIColor redColor];
                    NSLog(@"[stepCountIntegration] Failed! StepCount: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                    NSLog(@"[stepCountIntegration] Failed! SleepAnalysis: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]]);
                     NSLog(@"[stepCountIntegration] Failed! Walking: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]]);
                });
            }
        }];
    }
}

- (IBAction)sleepAnalysisIntegrationButtonSwitched:(UISwitch*)sender{
    if (sender.isOn) {
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorizationForHKDataCategoryType:@"HKSleepAnalysis" withCompletion:^(BOOL success, NSError *error){
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Sleep succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                    NSLog(@"[sleepAnalysisIntegration] Succeeded! StepCount: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                    NSLog(@"[sleepAnalysisIntegration] Succeeded! SleepAnalysis: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]]);
                    NSLog(@"[sleepAnalysisIntegration] Succeeded! Walking: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]]);
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Sleep failed!"];
                    _registrationFeedback.textColor = [UIColor redColor];
                    NSLog(@"[sleepAnalysisIntegration] Failed! StepCount: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                    NSLog(@"[sleepAnalysisIntegration] Failed! SleepAnalysis: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]]);
                    NSLog(@"[sleepAnalysisIntegration] Failed! Walking: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]]);
                });
            }
        }];
    }
}

- (IBAction)walkingIntegrationButtonSwitched:(UISwitch*)sender{
    if (sender.isOn) {
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorizationForHKDataQuantityType:@"HKWalking" withCompletion:^(BOOL success, NSError *error){
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Walking succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                    NSLog(@"[walkingIntegration] Succeeded! StepCount: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                    NSLog(@"[walkingIntegration] Succeeded! SleepAnalysis: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]]);
                    NSLog(@"[walkingIntegration] Succeeded! Walking: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Walking failed!"];
                    _registrationFeedback.textColor = [UIColor redColor];
                    NSLog(@"[walkingIntegration] Failed! StepCount: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                    NSLog(@"[walkingIntegration] Failed! SleepAnalysis: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis]]);
                    NSLog(@"[walkingIntegration] Failed! Walking: %ld",(long)[[HealthKitProvider sharedInstance].healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]);
                });
            }
        }];
    }
}
@end
