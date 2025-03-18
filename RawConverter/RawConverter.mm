//
//  RawConverter.mm
//  RawConverter
//
//  Created by Ingemar Bergmark on 2025-02-02.
//

#import "RawConverter.h"
#include "libraw.h"
#include <ranges>

// Private internal class
namespace {

class RawConverterPrivate {
private:
  LibRaw rawConverter;
  
public:
  RawConverterPrivate() {
    NSLog(@"DEBUG: Successfully initialized RawConverter");
  }
  
  std::string getErrorMessageForErrorCode(int errorCode) {
    const char* errString = libraw_strerror(errorCode);
    return errString ? std::string(errString) : "Unknown libraw error code: " + std::to_string(errorCode);
  }
  
  void checkError(int errorCode) {
    if (errorCode != LIBRAW_SUCCESS) {
      throw std::runtime_error(getErrorMessageForErrorCode(errorCode));
    }
  }
    
  void createThumbWithRawFilePath(const std::string& rawFilePath, const std::string& thumbOutputPath) {
    // Prepare processor for the next thumb
    rawConverter.recycle();

    // Open and process thumb for the raw file
    checkError(rawConverter.open_file(rawFilePath.c_str()));
    checkError(rawConverter.unpack_thumb());
    checkError(rawConverter.dcraw_thumb_writer(thumbOutputPath.c_str()));
  }
  
  void adjustOutputParametersWithSettings(std::vector<std::string>& settings) {
    // Iterate over the settings array using an index so we can fetch subsequent values
    for (int i = 0; i < settings.size(); i++) {
      std::string& setting = settings[i];
      NSLog(@"DEBUG: Processing option: %@", [NSString stringWithUTF8String:setting.c_str()]);
      
      if (setting == "-T") { // Output TIFF
        rawConverter.output_params_ptr()->output_tiff = 1;
      }
      
      else if (setting == "-W") { // No auto bright
        rawConverter.output_params_ptr()->no_auto_bright = 1;
      }
      
      else if (setting == "-n") { // Noise threshold
        if (i + 1 >= settings.size()) {
          NSLog(@"Missing noise threshold value after -n");
          return;
        }
        i++; // advance to threshold value
        try {
          float threshold = std::stof(settings[i]);
          rawConverter.output_params_ptr()->threshold = threshold;
        }
        catch (const std::exception& e) {
          NSLog(@"Invalid noise threshold value: %s", settings[i].c_str());
          return;
        }
      }
      
      else if (setting == "-C") { // Red and blue magnification
        if (i + 1 >= settings.size()) {
          NSLog(@"Missing red and blue values after -C");
          return;
        }
        i++; // advance to the string with red and blue values
        std::string& partsStr = settings[i];
        std::vector<std::string> parts;
        // Split the string on spaces (assuming values are space-separated)
        for (auto&& part : std::views::split(partsStr, ' ')) {
          if (!part.empty()) { // Ignore empty parts
            parts.emplace_back(part.begin(), part.end());
          }
        }
        if (parts.size() < 2) {
          NSLog(@"Invalid red and blue values for -C");
          return;
        }
        try {
          double red = std::stod(parts[0]);
          if (red == 0) { red = 1; }  // Avoid division by zero
          double blue =  std::stod(parts[1]);
          if (blue == 0) { blue = 1; }
          rawConverter.output_params_ptr()->aber[0] = 1.0 / red;
          rawConverter.output_params_ptr()->aber[2] = 1.0 / blue;
        }
        catch (const std::exception& e) {
          NSLog(@"Invalid red/blue magnification values: %s", partsStr.c_str());
          return;
        }
      }
      
      else if (setting == "-H") { // Highlights
        if (i + 1 >= settings.size()) {
          NSLog(@"Missing highlight value after -H");
          return;
        }
        i++;
        std::string& highlightStr = settings[i];
        try {
          int highlight = std::stoi(highlightStr);
          rawConverter.output_params_ptr()->highlight = highlight;
        }
        catch (const std::exception& e) {
          NSLog(@"Invalid highlight value: %s", highlightStr.c_str());
          return;
        }
      }
      
      else if (setting == "-a") { // Auto white balance
        rawConverter.output_params_ptr()->use_auto_wb = 1;
      }
      
      else if (setting == "-w") { // Camera white balance
        rawConverter.output_params_ptr()->use_camera_wb = 1;
      }
      
      else if (setting == "-o") { // Color space
        if (i + 1 >= settings.size()) {
          NSLog(@"Missing colorspace value after -o");
          return;
        }
        i++;
        std::string& outputColorStr = settings[i];
        try{
          int outputColor = std::stoi(outputColorStr);
          rawConverter.output_params_ptr()->output_color = outputColor;
        }
        catch (const std::exception& e) {
          NSLog(@"Invalid colorspace value: %s", outputColorStr.c_str());
          return;
        }
      }
      
      else if (setting == "-q") { // Interpolation
        if (i + 1 >= settings.size()) {
          NSLog(@"Missing interpolation value after -q");
          return;
        }
        i++;
        std::string& interpolationStr = settings[i];
        try {
          int interpolation = std::stoi(interpolationStr);
          rawConverter.output_params_ptr()->user_qual = interpolation;
        }
        catch (const std::exception& e) {
          NSLog(@"Invalid interpolation value: %s", interpolationStr.c_str());
          return;
        }
      }
      
      else if (setting == "-m") { // Cleanup passes
        if (i + 1 >= settings.size()) {
          NSLog(@"Missing cleanup passes value after -m");
          return;
        }
        i++;
        std::string& cleanupStr = settings[i];
        try {
          int cleanupPasses = std::stoi(cleanupStr);
          rawConverter.output_params_ptr()->med_passes = cleanupPasses;
        }
        catch (const std::exception& e) {
          NSLog(@"Invalid cleanup passes value: %s", cleanupStr.c_str());
          return;
        }
      }
      
      else if (setting == "-f") { // Four colors
        rawConverter.output_params_ptr()->four_color_rgb = 1;
      }
      
      else if (setting == "-6") { // Sixteen bit
        rawConverter.output_params_ptr()->output_bps = 16;
      }
      
      else if (setting == "-b") { // Brightness
        if (i + 1 >= settings.size()) {
          NSLog(@"Missing brightness value after -b");
          return;
        }
        i++;
        std::string& brightnessStr = settings[i];
        try{
          float brightness = std::stof(brightnessStr);
          rawConverter.output_params_ptr()->bright = brightness;
        }
        catch (const std::exception& e) {
          NSLog(@"Invalid brightness value: %s", brightnessStr.c_str());
          return;
        }
      }
      
      else if (setting == "-g") { // Gamma
        if (i + 2 >= settings.size()) {
          NSLog(@"Missing gamma values after -g");
          return;
        }
        i++;
        std::string& gammaPowerStr = settings[i];
        std::string& gammaToeSlopeStr = settings[i+1];
        double gammaPower = std::stod(gammaPowerStr);
        if (gammaPower == 0) { gammaPower = 1; }
        double gammaToeSlope = std::stod(gammaToeSlopeStr);
        rawConverter.output_params_ptr()->gamm[0] = gammaPower;
        rawConverter.output_params_ptr()->gamm[2] = gammaToeSlope;
      }
      
      else {
        NSLog(@"Unknown setting %s", setting.c_str());
      }
    }
  }
  
  void convertRawToTiffWithRawFilePath(const std::string& rawFilePath, const std::string& tiffOutputPath,
                                       std::vector<std::string>& settings) {
    // Prepare the processor for the next image
    rawConverter.recycle();

    checkError(rawConverter.open_file(rawFilePath.c_str()));
    checkError(rawConverter.unpack());
    
    adjustOutputParametersWithSettings(settings);

    checkError(rawConverter.dcraw_process());
    checkError(rawConverter.dcraw_ppm_tiff_writer(tiffOutputPath.c_str()));
  }

}; // class
} // namespace


// ====================================================================================================================

// Instance variables
@interface RawConverter()
{
  std::unique_ptr<RawConverterPrivate> _privateImpl;
}
@end

// Let's define the wrapper!
@implementation RawConverter

// Utility functions
std::vector<std::string> convertNSArrayToVector(NSArray<NSString *> *settings) {
  std::vector<std::string> result;
  
  for (NSString *nsStr in settings) {
    if (nsStr) { // Ensure it's not nil
      result.emplace_back([nsStr UTF8String]);  // Convert and add to vector
    }
  }
  
  return result;
}

// Implementation
- (nullable instancetype)initWithError:(NSError **)errorHandler {
  self = [super init];
  if (self) {
    _privateImpl = std::make_unique<RawConverterPrivate>();
  }
  return self;
}

- (void)dealloc {
  NSLog(@"DEBUG: Successful RawConverter dealloc");
}

+ (NSString *)libRawVersion {
  return [NSString stringWithUTF8String:LibRaw::version()];
}

+ (NSInteger)cameraCount {
  return (NSInteger)LibRaw::cameraCount();
}

+ (NSArray<NSString *> *)supportedCameras {
  NSMutableArray<NSString *> *cameraArray = [NSMutableArray array];
  
  const char** supportedCameras = LibRaw::cameraList();
  if (!supportedCameras) return cameraArray; // Return an empty array if NULL
  
  for (int i = 0; supportedCameras[i] != nullptr; i++) {
    if (supportedCameras[i]) {
      NSString *cameraName = [NSString stringWithUTF8String:supportedCameras[i]];
      [cameraArray addObject:cameraName];
    }
  }
  
  return [cameraArray copy]; // Return an immutable NSArray
}

- (void)createThumbWithRawFilePath:(NSString *)rawFilePath
                   thumbOutputPath:(NSString *)thumbOutputPath
{
  if (!_privateImpl) {
    NSLog(@"DEBUG: Error: RawConverter instance is not initialized");
    return;
  }

  if (![[NSFileManager defaultManager] fileExistsAtPath:rawFilePath]) {
    NSLog(@"DEBUG: Raw file not found: %@", rawFilePath);
    return;
  }
    
  NSLog(@"DEBUG: Processing thumb file: %@", rawFilePath);
  _privateImpl->createThumbWithRawFilePath([rawFilePath UTF8String], [thumbOutputPath UTF8String]);
  NSLog(@"DEBUG: Successfully saved thumb to: %@", thumbOutputPath);
}

- (void)convertRawToTiffWithRawFilePath:(NSString *)rawFilePath
                         tiffOutputPath:(NSString *)tiffOutputPath
                               settings:(NSArray<NSString *> *)settings
{
  if (!_privateImpl) {
    NSLog(@"DEBUG: Error: RawConverter instance is not initialized");
    return;
  }

  if (![[NSFileManager defaultManager] fileExistsAtPath:rawFilePath]) {
    NSLog(@"DEBUG: Raw file not found: %@", rawFilePath);
    return;
  }

  NSLog(@"DEBUG: Processing raw file: %@", rawFilePath);
  std::vector<std::string> vectorSettings = convertNSArrayToVector(settings);
  _privateImpl->convertRawToTiffWithRawFilePath([rawFilePath UTF8String], [tiffOutputPath UTF8String], vectorSettings);
  NSLog(@"DEBUG: Successfully saved TIFF to: %@", tiffOutputPath);
}

@end
