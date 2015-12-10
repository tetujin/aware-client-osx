//
//  PreferencesWindow.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "PreferencesWindow.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWARESensor.h"
#import "AWARESensorManager.h"

@interface PreferencesWindow ()

@end

@implementation PreferencesWindow{
    AWARESensorManager *sensorManager;
    AWAREStudy *awareStudy;
    NSTimer* sensorViewRefreshTimer;
}

- (instancetype)initWithSensorManager:(AWARESensorManager* )manager awareStudy:(AWAREStudy *)study{
    self = [super initWithWindowNibName:@"PreferencesWindow"];
    if (self) {
        awareStudy = study;
        sensorManager = manager;
        sensorViewRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                                  target:self
                                                                selector:@selector(updateSensorView)
                                                                userInfo:nil
                                                                 repeats:true];
        [sensorViewRefreshTimer invalidate];
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
    [sensorViewRefreshTimer invalidate];
}

- (IBAction)pushedSensorsView:(id)sender {
    [self setPreferencesView:_sensorsView];
    sensorViewRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                              target:self
                                                            selector:@selector(updateSensorView)
                                                            userInfo:nil
                                                             repeats:true];
    [sensorViewRefreshTimer fire];
}

- (IBAction)pushedStudyButton:(id)sender {
    [self setPreferencesView:_studyView];
    [sensorViewRefreshTimer invalidate];
}

- (IBAction)pushedTrashButton:(id)sender {
    NSLog(@"delete the current AWARE study!");
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Do you delete the current AWARE study?";
//    alert.informativeText = [NSString stringWithFormat:@"You you want to jon the study? \n- %@", url];
    [alert addButtonWithTitle:@"YES"];
    [alert addButtonWithTitle:@"NO"];
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if ( result == 1000 ) {
//            AWAREStudy *awareStudy = [[AWAREStudy alloc] init];
            if ([awareStudy isAvailable]) {
                [awareStudy clearAllSetting];
                [self initAwareView];
                [self initSensorsView];
                [self initStudyView];
                [sensorManager stopAllSensors];
            }
        } else {
            
        }
    }];
}


- (void) setPreferencesView:(NSView *) newView {
    NSWindow *window = [self window];
    NSView *contentView = [window contentView];
    NSArray *subviews = [contentView subviews];
    for(NSView *subview in subviews) [subview removeFromSuperview];
    NSRect windowFrame = [window frame];
    NSRect newWindowFrame = [window frameRectForContentRect:[newView frame]];
    newWindowFrame.origin.x = windowFrame.origin.x;
    newWindowFrame.origin.y = windowFrame.origin.y + windowFrame.size.height - newWindowFrame.size.height;
    [window setFrame:newWindowFrame display:YES animate:YES];
    
    [contentView addSubview:newView];
    
    [self initAwareView];
    [self initSensorsView];
    [self initStudyView];
}

- (void) initAwareView {
//    AWAREStudy *awareStudy = [[AWAREStudy alloc] init];
    if ([awareStudy isAvailable]) {
        [_deviceUuid setStringValue:[awareStudy getMqttUserName]];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *syncInt = [userDefaults objectForKey:SETTING_SYNC_INT];
        if (syncInt != nil) {
            [_syncInterval setStringValue:syncInt ];
        }
        BOOL state = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        [_debugState setState:state];
        
        NSNumber *n = [userDefaults objectForKey:SETTING_DELETE_INT];
        if(n != nil){
            [_deleteInterval selectItemAtIndex:[n intValue]];
        }
    }
}


- (void) initSensorsView {
    
}



- (void) initStudyView {
//    AWAREStudy *awareStudy = [[AWAREStudy alloc] init];
    if ([awareStudy isAvailable]) {
        [_studyId setStringValue:[awareStudy getStudyId]];
        [_webserviceUrl setStringValue:[awareStudy getWebserviceServer]]
        ;
        [_mqttServerUrl setStringValue:[awareStudy getMqttServer]];
        [_mqttUserName setStringValue:[awareStudy getMqttUserName]];
    } else {
        [_studyId setStringValue:@"---"];
        [_webserviceUrl setStringValue:@"---"]
        ;
        [_mqttServerUrl setStringValue:@"---"];
        [_mqttUserName setStringValue:@"---"];
    }
}

/**
 * for AWARE View
 */

- (IBAction)pushedDoneButton:(id)sender {
//    AWAREStudy *awareStudy = [[AWAREStudy alloc] init];
    if ([awareStudy isAvailable]) {
        [self setAwareConfig];
    }
    [self initAwareView];
}


- (void) setAwareConfig{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* sync = [_syncInterval stringValue];
    BOOL debug = [_debugState state];
    NSNumber* delete = [NSNumber numberWithInteger:[_deleteInterval indexOfSelectedItem]];
    [userDefaults setObject:sync forKey:SETTING_SYNC_INT];
    [userDefaults setBool:debug forKey:SETTING_DEBUG_STATE];
    [userDefaults setObject:delete forKey:SETTING_DELETE_INT];
    // show alert
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Success";
    alert.informativeText = @"Study configuration is updated!";
    [alert addButtonWithTitle:@"OK"];
//    [alert addButtonWithTitle:@"Canel"];
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {

        double syncInterval = 60.0f;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *syncInt = [userDefaults objectForKey:SETTING_SYNC_INT];
        if (syncInt != nil) {
            syncInterval = [syncInt doubleValue] * 60.0f;
        }
        NSLog(@"Syncinterval = %f", syncInterval);
        [sensorManager startAllSensorsWithSyncInterval:syncInterval awareStudy:awareStudy];
    }];
    
}


/**
 * for SensorView
 */

- (void) updateSensorView {
//    NSLog(@"hello");
    _deviceState.stringValue = [sensorManager getLatestSensorData:SENSOR_PC_STATE];
    _activeApp.stringValue = [sensorManager getLatestSensorData:SENSOR_PC_APP];
    _keyAction.stringValue = [sensorManager getLatestSensorData:SENSOR_PC_KEYBOARD];
    _mouseClick.stringValue = [sensorManager getLatestSensorData:SENSOR_PC_MOUSE_CLICK];
    _mouseLocation.stringValue = [sensorManager getLatestSensorData:SENSOR_PC_MOUSE_LOCATION];
}


/**
 * for StudyView
 */

- (IBAction)pushedSelectQRcode:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    if([openDlg runModal] == NSModalResponseOK){
        NSString *selectedFileName = [openDlg filename];
//        NSLog(selectedFileName);
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:selectedFileName];
        if (image) {
            NSLog(@"======================== %f %f", image.size.height, image.size.width);
            NSString* url = [self decodeStaticImage:image];
            NSLog(@"url is %@.", url);
            [self checkConfirmationForStudy:url];
        }
    }
}

- (IBAction)pushedTakeScreenshot:(id)sender {
    // Get an URL in the QR code
    NSString* url = [self getTextFromQRCodeWithSchreenshot];
    [self checkConfirmationForStudy:url];
}

- (void) checkConfirmationForStudy:(NSString*)url{
    if (url) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"AWARE client detected a AWARE study URL";
        alert.informativeText = [NSString stringWithFormat:@"Do you join the study? \n- %@", url];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Canel"];
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            NSLog(@"%ld",result);
            if (result == 1000) {
                // Connect to a AWARE server and set a study information
//                AWAREStudy *awareStudy = [[AWAREStudy alloc] init];
                bool result = [awareStudy setStudyInformationWithURL:url];
                if(result){
                    NSAlert *alert = [NSAlert new];
                    alert.messageText = @"Thank you for joining the AWARE study!";
                    [alert addButtonWithTitle:@"OK"];
                    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
                        double syncInterval = 60.0f;
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        NSString *syncInt = [userDefaults objectForKey:SETTING_SYNC_INT];
                        if (syncInt != nil) {
                            syncInterval = [syncInt doubleValue] * 60.0f;
                        }
                        NSLog(@"Syncinterval = %f", syncInterval);
                        [sensorManager startAllSensorsWithSyncInterval:syncInterval awareStudy:awareStudy];
                    }];
                    [self initStudyView];
                }else{
                    NSAlert *alert = [NSAlert new];
                    alert.messageText = @"Error.";
                    [alert addButtonWithTitle:@"OK"];
                    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
                        
                    }];
                }
                
            }
        }];
    }else{
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"AWARE client could not detect a AWARE study URL";
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            
        }];
        
    }
}


//==========================================
- (NSString*) decodeStaticImage:(NSImage*) inImage{
    CGImageRef cgImage = [self makeCGImageFromNSImage:inImage];
    ZXCGImageLuminanceSource* source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:cgImage];
    ZXHybridBinarizer* binarizer = [ZXHybridBinarizer alloc];
    [binarizer initWithSource:source];
    ZXBinaryBitmap* bitmap  = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];
    ZXQRCodeReader* reader = [[ZXQRCodeReader alloc] init];
    ZXResult* result = [reader decode:bitmap error:nil];
//    NSLog(@"result is %@", result.text);
    return result.text;
}

// ----------------------------------------------------------------------------------------------

- (CGImageRef) makeCGImageFromNSImage:(NSImage*) inImage {
    CGImageRef              result;
    NSData*                 imagedata       = [inImage TIFFRepresentation];
    NSBitmapImageRep*       bitmaprep       = [NSBitmapImageRep imageRepWithData:imagedata];
    size_t                 rowBytes         = [bitmaprep bytesPerRow];
    size_t                 wid              = [bitmaprep pixelsWide];
    size_t                 hgt              = [bitmaprep pixelsHigh];
    size_t                 bpp              = [bitmaprep bitsPerPixel];
    size_t                  spp             = [bitmaprep samplesPerPixel];
    CGDataProviderRef       provider        = CGDataProviderCreateWithCFData((CFDataRef)imagedata);
    CGColorSpaceRef         colorspace      = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGBitmapInfo            bitsInfo        = kCGImageAlphaLast;
    result          = CGImageCreate(wid,hgt,spp,bpp,rowBytes,
                                    colorspace,bitsInfo,provider,NULL,NO,
                                    kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorspace);
    return(result);
}


- (NSString*) getTextFromQRCodeWithSchreenshot {
    NSString *resultStr = NULL;
    CGImageRef image = NULL;
    CVPixelBufferRef pixelBuffer = NULL;
    @autoreleasepool {
        image = CGDisplayCreateImage(kCGDirectMainDisplay);
        pixelBuffer = [self pixelBufferFromCGImage:image];
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        if(pixelBuffer){
            ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithBuffer:pixelBuffer];
            ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
            NSError *error = nil;
            ZXDecodeHints *hints = [ZXDecodeHints hints];
            [hints setTryHarder:YES];
            [hints setEncoding:NSUTF8StringEncoding];
            
            ZXMultiFormatReader *r = [ZXMultiFormatReader reader];
            ZXResult *zxResult = [r decode:bitmap
                                     hints:hints
                                     error:&error];
            
            if(zxResult){
                NSLog(@"%@", zxResult.text);
                resultStr = zxResult.text;
            }
        } else {
            NSLog(@"------");
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
        CGImageRelease(image);
    }
    return resultStr;
}


- (CGImageRef)nsImageToCGImageRef:(NSImage*)image;
{
    NSData * imageData = [image TIFFRepresentation];
    CGImageRef imageRef;
    if(!imageData) return nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    return imageRef;
}


-(CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image {
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameSize.width,
                                          frameSize.height,
                                          kCVPixelFormatType_32ARGB,
                                          CFBridgingRetain(options),
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipLast);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}



@end
