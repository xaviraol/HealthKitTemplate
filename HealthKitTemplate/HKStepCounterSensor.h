//
//  HKStepCounterSensor.h
//  SenseService
//
//  Created by Xavier Ramos Oliver on 28/06/16.
//
//

#import <Foundation/Foundation.h>

@interface HKStepCounterSensor : NSObject {
    
}

- (void) onStepsUpdate;
- (void) setTimeActiveOnBackgroundForStepCountSamples;


@end
