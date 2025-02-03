//
//  LibRawWrapper.m
//  LibRaw
//
//  Created by Ingemar Bergmark on 2025-02-02.
//

#import "LibRawWrapper.h"
#import "libraw.h"

// Instance variables
@interface LibRawWrapper ()
{
  libraw_data_t *rawData;
}
@end


// Let's define the wrapper!
@implementation LibRawWrapper

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
