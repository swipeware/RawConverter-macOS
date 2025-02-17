//
//  RawConverter.mm
//  RawConverter
//
//  Created by Ingemar Bergmark on 2025-02-02.
//

#import "RawConverter.h"
#include "libraw.h"
  
  
// File level configuration
static NSString * const LIBRAW_DOMAIN = @"com.swipeware.RawConverter";

static NSError *LibRawError(NSString *errorDescription) {
    NSError *error = [NSError errorWithDomain: LIBRAW_DOMAIN
                      code: 1001
                      userInfo: @{NSLocalizedDescriptionKey: errorDescription}];
    return error;
}


// Instance variables
@interface RawConverter ()
{
  libraw_data_t *rawContext;
}
@end


// Let's define the wrapper!
@implementation RawConverter

- (nullable instancetype)initWithError:(NSError **)errorHandler {
  self = [super init];
  if (self) {
    rawContext = libraw_init(0);
    NSLog(@"Context size: %lu", (unsigned long)sizeof(*rawContext));
    
    if (!rawContext) {
      if (errorHandler) {
        *errorHandler = LibRawError(@"ERROR: Failed to create LibRaw context");
      }
      return nil;
    }
    
    NSLog(@"DEBUG: Successfully initialized libraw");
  }
  return self;
}

- (void)dealloc {
  if (rawContext) {
    libraw_close(rawContext);
    NSLog(@"DEBUG: Successful dealloc");
  }
}

- (NSString *)getErrorMessageForErrorCode:(int32_t)errorCode {
  const char *cString = libraw_strerror(errorCode);
  if (cString == NULL) {
    return [NSString stringWithFormat:@"Unknown libraw error code: %d", errorCode];
  }
  return [NSString stringWithUTF8String:cString];
}

- (void)processError:(NSError **) errorHandler errorMessage:(NSString *)message {
  if (errorHandler) {
    *errorHandler = LibRawError(message);
  }
  else {
    NSLog(@"ERROR: %@", message);
  }
}

- (BOOL)openFile:(NSString *)filePath error:(NSError **)errorHandler {
  const char *cFilePath = [filePath UTF8String];
  
  int result = libraw_open_file(rawContext, cFilePath);
  
  if (result != LIBRAW_SUCCESS) {
    NSString *formatString = @"Failed to open file: %@";
    NSString *librawError = [self getErrorMessageForErrorCode:result];
    NSString *errorMessage = [NSString stringWithFormat:formatString, librawError];
    [self processError:errorHandler errorMessage:errorMessage];
    return NO;
  }
  
  return YES;
}

- (BOOL)ppmTiffWriter:(NSString *)outputPath error:(NSError **)errorHandler {
  const char *cOutputPath = [outputPath UTF8String];
  
  NSLog(@"Attempting to write TIFF to: %@", outputPath);
  int result = libraw_dcraw_ppm_tiff_writer(rawContext, cOutputPath);
  
  if (result != LIBRAW_SUCCESS) {
    NSString *formatString = @"Failed to save processed image to %@: %@";
    NSString *librawError = [self getErrorMessageForErrorCode:result];
    NSString *errorMessage = [NSString stringWithFormat:formatString, outputPath, librawError];
    [self processError:errorHandler errorMessage:errorMessage];
    return NO;
  }
  
  return YES;
}

- (BOOL)thumbWriter:(NSString *)outputPath error:(NSError **)errorHandler {
  const char *cOutputPath = [outputPath UTF8String];
  
  int result = libraw_dcraw_thumb_writer(rawContext, cOutputPath);
  
  if (result != LIBRAW_SUCCESS) {
    NSString *formatString = @"Failed to save processed thumbnail to %@: %@";
    NSString *librawError = [self getErrorMessageForErrorCode:result];
    NSString *errorMessage = [NSString stringWithFormat:formatString, outputPath, librawError];
    [self processError:errorHandler errorMessage:errorMessage];
    return NO;
  }
  
  return YES;
}

- (BOOL)unpack:(NSError **)errorHandler {
  int result = libraw_unpack(rawContext);
  
  if (result != LIBRAW_SUCCESS) {
    NSString *formatString = @"Failed to unpack raw file: %@";
    NSString *librawError = [self getErrorMessageForErrorCode:result];
    NSString *errorMessage = [NSString stringWithFormat:formatString, librawError];
    [self processError:errorHandler errorMessage:errorMessage];
    return NO;
  }
  
  return YES;
}

- (BOOL)unpackThumb:(NSError **)errorHandler {
  int result = libraw_unpack_thumb(rawContext);
  
  if (result != LIBRAW_SUCCESS) {
    NSString *formatString = @"Failed to unpack thumbnail for raw file: %@";
    NSString *librawError = [self getErrorMessageForErrorCode:result];
    NSString *errorMessage = [NSString stringWithFormat:formatString, librawError];
    [self processError:errorHandler errorMessage:errorMessage];
    return NO;
  }
  
  return YES;
}

- (BOOL)process:(NSError **)errorHandler {
  int result = libraw_dcraw_process(rawContext);
  
  if (result != LIBRAW_SUCCESS) {
    NSString *formatString = @"Failed to process raw file: %@";
    NSString *librawError = [self getErrorMessageForErrorCode:result];
    NSString *errorMessage = [NSString stringWithFormat:formatString, librawError];
    [self processError:errorHandler errorMessage:errorMessage];
    return NO;
  }
  return YES;
}

- (void)recycle {
  libraw_recycle(rawContext);
}

+ (NSString *)libRawVersion {
  return [NSString stringWithUTF8String:libraw_version()];
}

+ (int32_t)cameraCount {
  return libraw_cameraCount();
}

+ (NSArray<NSString *> *)supportedCameras {
  NSMutableArray<NSString *> *cameraList = [NSMutableArray array];
  
  const char **cameraListPtr = libraw_cameraList();
  if (cameraListPtr == NULL) {
    return cameraList; // If the pointer is NULL, return an empty array.
  }
  
  const char **currentPtr = cameraListPtr;
  
  // Iterate until a NULL pointer is encountered.
  while (*currentPtr != NULL) {
    // Convert the C string to an NSString.
    NSString *cameraName = [NSString stringWithUTF8String:*currentPtr];
    if (cameraName != nil) {
      [cameraList addObject:cameraName];
    }
    currentPtr++;
  }
  
  return [cameraList copy];
}

- (BOOL)adjustOutputParametersWithSettings:(NSArray<NSString *> *)settings error:(NSError **)errorHandler {
  // Iterate over the settings array using an index so we can fetch subsequent values
  for (NSUInteger i = 0; i < settings.count; i++) {
    NSString *setting = settings[i];
    NSLog(@"DEBUG: Processing option: %@", setting);
    if ([setting isEqualToString:@"-T"]) { // Output TIFF
      rawContext->params.output_tiff = (int)1;
    }
    else if ([setting isEqualToString:@"-W"]) { // No auto bright
      rawContext->params.no_auto_bright = (int)1;
    }
    else if ([setting isEqualToString:@"-n"]) { // Noise threshold
      if (i + 1 >= settings.count) {
        [self processError: errorHandler errorMessage:@"Missing noise threshold value after -n"];
        return NO;
      }
      i++; // advance to threshold value
      NSString *thresholdStr = settings[i];
      float threshold = [thresholdStr floatValue];
      rawContext->params.threshold = threshold;
    }
    else if ([setting isEqualToString:@"-C"]) { // Red and blue magnification
      if (i + 1 >= settings.count) {
        [self processError:errorHandler errorMessage:@"Missing red and blue values after -C"];
        return NO;
      }
      i++; // advance to the string with red and blue values
      NSString *partsStr = settings[i];
      // Split the string on spaces (assuming values are space-separated)
      NSArray<NSString *> *parts = [partsStr componentsSeparatedByString:@" "];
      if (parts.count < 2) {
        [self processError:errorHandler errorMessage:@"Invalid red and blue values for -C"];
        return NO;
      }
      double red = [parts[0] doubleValue];
      if (red == 0) { red = 1; }  // Avoid division by zero
      double blue = [parts[1] doubleValue];
      if (blue == 0) { blue = 1; }
      rawContext->params.aber[0] = 1.0 / red;
      rawContext->params.aber[2] = 1.0 / blue;
    }
    else if ([setting isEqualToString:@"-H"]) { // Highlights
      if (i + 1 >= settings.count) {
        [self processError:errorHandler errorMessage:@"Missing highlight value after -H"];
        return NO;
      }
      i++;
      NSString *highlightStr = settings[i];
      int32_t highlight = [highlightStr intValue];
      rawContext->params.highlight = highlight;
    }
    else if ([setting isEqualToString:@"-a"]) { // Auto white balance
      rawContext->params.use_auto_wb = 1;
    }
    else if ([setting isEqualToString:@"-w"]) { // Camera white balance
      rawContext->params.use_camera_wb = 1;
    }
    else if ([setting isEqualToString:@"-o"]) { // Color space
      if (i + 1 >= settings.count) {
        [self processError:errorHandler errorMessage:@"Missing color space value after -o"];
        return NO;
      }
      i++;
      NSString *outputColorStr = settings[i];
      int32_t outputColor = [outputColorStr intValue];
      rawContext->params.output_color = outputColor;
    }
    else if ([setting isEqualToString:@"-q"]) { // Interpolation
      if (i + 1 >= settings.count) {
        [self processError:errorHandler errorMessage:@"Missing interpolation value after -q"];
        return NO;
      }
      i++;
      NSString *interpStr = settings[i];
      int32_t interpolation = [interpStr intValue];
      rawContext->params.user_qual = interpolation;
    }
    else if ([setting isEqualToString:@"-m"]) { // Cleanup passes
      if (i + 1 >= settings.count) {
        [self processError:errorHandler errorMessage:@"Missing cleanup passes value after -m"];
        return NO;
      }
      i++;
      NSString *cleanupStr = settings[i];
      int32_t cleanupPasses = [cleanupStr intValue];
      rawContext->params.med_passes = cleanupPasses;
    }
    else if ([setting isEqualToString:@"-f"]) { // Four colors
      rawContext->params.four_color_rgb = 1;
    }
    else if ([setting isEqualToString:@"-6"]) { // Sixteen bit
      rawContext->params.output_bps = 16;
    }
    else if ([setting isEqualToString:@"-b"]) { // Brightness
      if (i + 1 >= settings.count) {
        [self processError:errorHandler errorMessage:@"Missing brightness value after -b"];
        return NO;
      }
      i++;
      NSString *brightnessStr = settings[i];
      float brightness = [brightnessStr floatValue];
      rawContext->params.bright = brightness;
    }
    else if ([setting isEqualToString:@"-g"]) { // Gamma
      if (i + 2 >= settings.count) {
        [self processError:errorHandler errorMessage:@"Missing gamma values after -g"];
        return NO;
      }
      i++;
      NSString *gammaPowerStr = settings[i];
      double gammaPower = [gammaPowerStr doubleValue];
      if (gammaPower == 0) { gammaPower = 1; }
      rawContext->params.gamm[0] = 1.0 / gammaPower;
      i++;
      NSString *gammaToeSlopeStr = settings[i];
      double gammaToeSlope = [gammaToeSlopeStr doubleValue];
      rawContext->params.gamm[2] = gammaToeSlope;
    }
    else {
      NSString *errorMessage = [NSString stringWithFormat:@"Unknown setting: %@", setting];
      [self processError:errorHandler errorMessage:errorMessage];
      return NO;
    }
  }
  
  return YES;
}

- (BOOL)convertRawToTiffWithRawFilePath:(NSString *)rawFilePath
                         tiffOutputPath:(NSString *)tiffOutputPath
                               settings:(NSArray<NSString *> *)settings
                            error:(NSError **)errorHandler
{
  // Check if the raw file exists
  if (![[NSFileManager defaultManager] fileExistsAtPath:rawFilePath]) {
    NSString *errorMessage = [NSString stringWithFormat:@"Raw file not found %@", rawFilePath];
    [self processError:errorHandler errorMessage:errorMessage];
    return NO;
  }
  
  NSLog(@"DEBUG: %@", [NSString stringWithFormat:@"Processing raw file: %@", rawFilePath]);
  
  // Prepare the processor for the next image
  [self recycle];
  
  [self openFile:rawFilePath error:errorHandler];
  [self unpack:errorHandler];
  
  [self adjustOutputParametersWithSettings:settings error:errorHandler];
  
  [self process:errorHandler];
  [self ppmTiffWriter:tiffOutputPath error:errorHandler];
  
  NSLog(@"%@", [NSString stringWithFormat:@"Successfully saved TIFF to: %@", tiffOutputPath]);
  return YES;
}

- (BOOL)createThumbWithRawFilePath:(NSString *)rawFilePath
                    thumbOutputPath:(NSString *)thumbOutputPath
                             error:(NSError **)errorHandler
{
  // Check if the raw file exists
  if (![[NSFileManager defaultManager] fileExistsAtPath:rawFilePath]) {
    NSString *errorMessage = [NSString stringWithFormat:@"Raw file not found %@", rawFilePath];
    [self processError:errorHandler errorMessage:errorMessage];
    return NO;
  }
  
  NSLog(@"DEBUG: %@", [NSString stringWithFormat:@"Processing thumb file: %@", rawFilePath]);
  
  // Prepare processor for the next thumb
  [self recycle];
  
  // Open and proces thumb for the raw file
  [self openFile:rawFilePath error:errorHandler];
  [self unpackThumb:errorHandler];
  [self thumbWriter:thumbOutputPath error:errorHandler];
  
  NSLog(@"DEBUG: %@", [NSString stringWithFormat:@"Successfully saved thumb to: %@", thumbOutputPath]);
  return YES;
}

@end
