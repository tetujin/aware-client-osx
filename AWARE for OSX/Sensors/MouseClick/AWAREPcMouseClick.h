//
//  AWAREPcMouse.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <Cocoa/Cocoa.h>

static id monitorLeftMouseDown;
static id monitorRightMouseDown;
static id monitorKeyDown;

@interface AWAREPcMouseClick : AWARESensor <AWARESensorDelegate>

@end
