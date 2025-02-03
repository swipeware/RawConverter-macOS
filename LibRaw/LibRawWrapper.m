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
  libraw_data_t *rawContext;
}
@end


// Let's define the wrapper!
@implementation LibRawWrapper

- (instancetype)initWithFlags:(unsigned int)flags {
  self = [super init];
  if (self) {
    rawContext = libraw_init(flags);
    
    if (!rawContext) {
      NSLog(@"ERROR: libraw_init failed with flags: %u", flags);
      return nil;
    }
    
    NSLog(@"DEBUG: Successfully initialized libraw with flags: %u", flags);
  }
  return self;
}

- (void)dealloc {
  if (rawContext) {
    libraw_close(rawContext);
    NSLog(@"DEBUG: Successful dealloc");
  }
}

@end
