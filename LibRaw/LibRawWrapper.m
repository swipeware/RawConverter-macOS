//
//  LibRawWrapper.m
//  LibRaw
//
//  Created by Ingemar Bergmark on 2025-02-02.
//

#import "LibRawWrapper.h"
#import "libraw.h"

@implementation LibRawWrapper

- (instancetype)initWithFlags:(unsigned int)flags {
  self = [super init];
//  if (self) {
//    // Initialize libraw using the provided flags.
//    _rawData = libraw_init(flags);
//    
//    if (!_rawData) {
//      NSLog(@"Error: libraw_init failed with flags: %u", flags);
//      // Initialization failed, so return nil.
//      return nil;
//    }
//    
//    NSLog(@"Successfully initialized libraw with flags: %u", flags);
//  }
  return self;
}

- (void)dealloc {
//  // Clean up the libraw data structure if it was successfully created.
//  if (_rawData) {
//    libraw_close(_rawData);
//  }
  
#if !__has_feature(objc_arc)
  [super dealloc];
#endif
}

@end
