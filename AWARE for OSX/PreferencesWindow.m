//
//  PreferencesWindow.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "PreferencesWindow.h"

@interface PreferencesWindow ()

@end

@implementation PreferencesWindow

- (instancetype)init
{
    self = [super initWithWindowNibName:@"PreferencesWindow"];
    if (self) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setPreferencesView:_awareView];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)pushedAwareButton:(id)sender {
    [self setPreferencesView:_awareView];
}

- (IBAction)pushedSensorsView:(id)sender {
    [self setPreferencesView:_sensorsView];
}

- (IBAction)pushedStudyButton:(id)sender {
    [self setPreferencesView:_studyView];
}

- (IBAction)pushedTrashButton:(id)sender {
    NSLog(@"Remove a study!");
}


- (void) setPreferencesView:(NSView *) newView {
//    NSToolbarItem *item = (NSToolbarItem *)sender;
    //    PreferencesViewType viewType = [item tag];

    
    NSWindow *window = [self window];
    NSView *contentView = [window contentView];
    NSArray *subviews = [contentView subviews];
    for(NSView *subview in subviews) [subview removeFromSuperview];
    
    //    [window setTitle:[item label]];
    
    NSRect windowFrame = [window frame];
    NSRect newWindowFrame = [window frameRectForContentRect:[newView frame]];
    newWindowFrame.origin.x = windowFrame.origin.x;
    newWindowFrame.origin.y = windowFrame.origin.y + windowFrame.size.height - newWindowFrame.size.height;
    [window setFrame:newWindowFrame display:YES animate:YES];
    
    [contentView addSubview:newView];
}

@end
