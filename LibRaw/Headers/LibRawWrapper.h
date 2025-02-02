//
//  LibRawWrapper.h
//  LibRaw
//
//  Created by Ingemar Bergmark on 2025-02-02.
//

#ifndef LibRawWrapper_h
#define LibRawWrapper_h

#import <Foundation/Foundation.h>
//#import "libraw.h"

@interface LibRawWrapper : NSObject

///// The pointer to the libraw data structure.
//@property (nonatomic, assign, readonly) libraw_data_t *rawData;

/**
 Initializes the wrapper with the specified flags.

 @param flags An unsigned integer representing initialization flags.
 @return An instance of LibRawWrapper if initialization succeeds; otherwise, nil.
 */
- (instancetype)initWithFlags:(unsigned int)flags;

@end

#endif /* LibRawWrapper_h */
