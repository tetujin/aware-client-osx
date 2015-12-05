//
//  PreferencesWindow.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindow : NSWindowController
- (IBAction)pushedAwareButton:(id)sender;
- (IBAction)pushedSensorsView:(id)sender;
- (IBAction)pushedStudyButton:(id)sender;
- (IBAction)pushedTrashButton:(id)sender;
@property (strong) IBOutlet NSView *awareView;
@property (strong) IBOutlet NSView *studyView;
@property (strong) IBOutlet NSView *sensorsView;


@end
