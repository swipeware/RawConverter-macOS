//
//  RawConverter.h
//  RawConverter
//
//  Created by Ingemar Bergmark on 2025-02-02.
//

#ifndef RawConverter_h
#define RawConverter_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Public interface
@interface RawConverter : NSObject

// Initializers
- (instancetype)init NS_UNAVAILABLE; // Not needed as initWithError is the main initializer
- (nullable instancetype)initWithError:(NSError **)error NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init()) ;

// Static methods
+ (NSString*)libRawVersion;
+ (NSInteger)cameraCount;
+ (NSArray<NSString*>*)supportedCameras;

// Instance methods
- (void)convertRawToTiffWithRawFilePath:(NSString*)rawFilePath
                         tiffOutputPath:(NSString*)tiffOutputPath
                               settings:(NSArray<NSString*>*)settings;

- (void)createThumbWithRawFilePath:(NSString*)rawFilePath
                   thumbOutputPath:(NSString*)thumbOutputPath;

@end

NS_ASSUME_NONNULL_END

#endif /* RawConverter_h */
