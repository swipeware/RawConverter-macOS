//
//  LibRawWrapper.m
//  LibRaw
//
//  Created by Ingemar Bergmark on 2025-02-02.
//

#import "LibRawWrapper.h"
#import "libraw.h"

@implementation LibRawWrapper

// Internal data
libraw_data_t *rawData;


- (instancetype)initWithFlags:(unsigned int)flags {
  self = [super init];
  if (self) {
    rawData = libraw_init(flags);
    
    if (!rawData) {
      NSLog(@"ERROR: libraw_init failed with flags: %u", flags);
      return nil;
    }
    
    NSLog(@"DEBUG: Successfully initialized libraw with flags: %u", flags);
  }
  return self;
}

- (void)dealloc {
  if (rawData) {
    libraw_close(rawData);
    NSLog(@"DEBUG: Successful dealloc");
  }
}

@end
