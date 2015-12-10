//
//  PreferencesWindow.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ZXingObjC/ZXingObjC.h>
#import "AWARESensorManager.h"

@interface PreferencesWindow : NSWindowController

-(instancetype) initWithSensorManager:(AWARESensorManager *) sensorManager awareStudy:(AWAREStudy *)study;

- (IBAction)pushedAwareButton:(id)sender;
- (IBAction)pushedSensorsView:(id)sender;
- (IBAction)pushedStudyButton:(id)sender;
- (IBAction)pushedTrashButton:(id)sender;
@property (strong) IBOutlet NSView *awareView;
@property (strong) IBOutlet NSView *studyView;
@property (strong) IBOutlet NSView *sensorsView;

/** AWARE View */
- (IBAction)pushedDoneButton:(id)sender;
@property (weak) IBOutlet NSTextField *deviceUuid;
@property (weak) IBOutlet NSTextField *syncInterval;
@property (weak) IBOutlet NSButton *debugState;
@property (weak) IBOutlet NSComboBox *deleteInterval;

/** AWARE Sensor View */
@property (weak) IBOutlet NSTextField *deviceState;
@property (weak) IBOutlet NSTextField *activeApp;
@property (weak) IBOutlet NSTextField *keyAction;
@property (weak) IBOutlet NSTextField *mouseLocation;
@property (weak) IBOutlet NSTextField *mouseClick;

/* Study View */
- (IBAction)pushedSelectQRcode:(id)sender;
- (IBAction)pushedTakeScreenshot:(id)sender;
@property (weak) IBOutlet NSTextField *studyId;
@property (weak) IBOutlet NSTextField *webserviceUrl;
@property (weak) IBOutlet NSTextField *mqttServerUrl;
@property (weak) IBOutlet NSTextField *mqttUserName;

@end
