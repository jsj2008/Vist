//
//  Optimiser.hpp
//  Vist
//
//  Created by Josef Willsher on 25/01/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

#ifndef Optimiser_hpp
#define Optimiser_hpp

#include "LLVM.h"

#ifdef __cplusplus
extern "C" {
#endif
        
    void performLLVMOptimisations(LLVMModuleRef __nonnull, int, bool);
    int LLVMMetadataID(const char * __nonnull String);
    
#ifdef __cplusplus
}
#endif

#endif /* Optimiser_hpp */
