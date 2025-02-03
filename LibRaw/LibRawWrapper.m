//
//  LibRawWrapper.m
//  LibRaw
//
//  Created by Ingemar Bergmark on 2025-02-02.
//

#import "LibRawWrapper.h"
#import "libraw.h"

// File level configuration
static NSString * const LIBRAW_DOMAIN = @"com.swipeware.LibRawWrapper";

static NSError *LibRawError(NSString *errorDescription) {
    NSError *error = [NSError errorWithDomain: LIBRAW_DOMAIN
                      code: 1001
                      userInfo: @{NSLocalizedDescriptionKey: errorDescription}];
    return error;
}


// Instance variables
@interface LibRawWrapper ()
{
  libraw_data_t *rawContext;
}
@end


// Let's define the wrapper!
@implementation LibRawWrapper

- (nullable instancetype)initWithError:(NSError **)errorHandler {
  self = [super init];
  if (self) {
    rawContext = libraw_init(0);
    
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

@end
