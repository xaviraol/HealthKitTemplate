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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) healthIntegrationButtonSwitched:(UISwitch*)sender {
    
    if (sender.isOn) {
        [[HealthKitProvider sharedInstance] requestHealthKitAuthorization:^(BOOL success, NSError *error) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _registrationFeedback.text = [NSString stringWithFormat:@"Authorization succeded!"];
                    _registrationFeedback.textColor = [UIColor greenColor];
                });
            }else{
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
@end
