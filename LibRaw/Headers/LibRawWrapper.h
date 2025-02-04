//
//  LibRawWrapper.h
//  LibRaw
//
//  Created by Ingemar Bergmark on 2025-02-02.
//

#ifndef LibRawWrapper_h
#define LibRawWrapper_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Public interface
@interface LibRawWrapper : NSObject

// Initializers
- (instancetype)init NS_UNAVAILABLE; // Not needed as initWithError is the main initializer
- (nullable instancetype)initWithError:(NSError **)error NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init()) ;

// Class methods
+ (NSString *)libRawVersion;
+ (int32_t)cameraCount;
+ (NSArray<NSString *> *)supportedCameras;
  
// Instance methods
- (BOOL)convertRawToTiffWithRawFilePath:(NSString *)rawFilePath
                         tiffOutputPath:(NSString *)tiffOutputPath
                               settings:(NSArray<NSString *> *)settings
                                  error:(NSError **)errorHandler;
@end

NS_ASSUME_NONNULL_END

#endif /* LibRawWrapper_h */
