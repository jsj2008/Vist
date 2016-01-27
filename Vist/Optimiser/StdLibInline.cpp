//
//  StdLibInline.cpp
//  Vist
//
//  Created by Josef Willsher on 24/01/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

#include "StdLibInline.hpp"
#include "Optimiser.hpp"

#include "llvm/PassManager.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/PassInfo.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Function.h"
#include "llvm/Pass.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm-c/BitReader.h"
#include "llvm/IR/CallSite.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/IPO/InlinerPass.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/ADT/ilist_node.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"

#include "LLVM.h"
#include "Intrinsic.hpp"

#include <stdio.h>
#include <iostream>


// useful instructions here: http://llvm.org/docs/WritingAnLLVMPass.html
// swift example here https://github.com/apple/swift/blob/master/lib/LLVMPasses/LLVMStackPromotion.cpp

#define DEBUG_TYPE "initialiser-pass"
using namespace llvm;

// MARK: StdLibInline pass decl

class StdLibInline : public FunctionPass {
    
    Module *stdLibModule;
    
    virtual bool runOnFunction(Function &F) override;
    
public:
    static char ID;
    
    StdLibInline() : FunctionPass(ID) {
        // FIXME: make a safer way of getting the directory path
        std::string path = "/Users/JoeWillsher/Developer/Vist/Vist/stdlib/stdlib.bc";
        auto b = MemoryBuffer::getFile(path.c_str());
        
        if (b.getError()) {
            stdLibModule = nullptr;
            printf("STANDARD LIBRARY NOT FOUND\nCould not run Inline-Stdlib optimiser pass\n\n");
            return;
        }
        
        MemoryBufferRef stdLibModuleBuffer = b.get().get()->getMemBufferRef();
        auto res = parseBitcodeFile(stdLibModuleBuffer, getGlobalContext());
        
        stdLibModule = res.get();
    }
    
//    ~StdLibInline() {
//        delete stdLibModule;
//    }
};

// we dont care about the ID -- make 0
char StdLibInline::ID = 0;



// MARK: pass setup

// defines `initializeStdLibInlinePassOnce(PassRegistry &Registry)` function
INITIALIZE_PASS_BEGIN(StdLibInline,
                      "initialiser-pass", "Vist initialiser folding pass",
                      false, false)
// implements `llvm::initializeStdLibInlinePass(PassRegistry &Registry)`
// function, declared in header adds it to the pass registry
INITIALIZE_PASS_END(StdLibInline,
                    "initialiser-pass", "Vist initialiser folding pass",
                    false, false)



// MARK: StdLibInline Functions

/// returns instance of the StdLibInline pass
FunctionPass *createStdLibInlinePass() {
    initializeStdLibInlinePass(*PassRegistry::getPassRegistry());
    return new StdLibInline();
}


/// Called on functions in module, this is where the optimisations happen
bool StdLibInline::runOnFunction(Function &function) {
    
    // flag for whether the pass changed anything
    bool changed = false;
    
    // we need a ref to the stdlib
    if (stdLibModule == nullptr)
        return false; // return if we don’t have it
    
    Module *module = function.getParent();
    LLVMContext &context = module->getContext();
    IRBuilder<> builder = IRBuilder<>(context);
    
    // id of the function call metadata we will optimise
    int initiID = LLVMMetadataID("stdlib.call.optim");
    uint index = 0; // current bb index
    
    // loops over blocks in function
    while (true) {
        
        BasicBlock *it = function.begin();  // `it` is our pointer to the current element
        it += index;                        // move to the indexth element
        BasicBlock &basicBlock = *it;       // reference to it
        
        if (index >= function.size())
            break;      // if we’re out of blocks break out of loop
        else
            ++index;    // otherwise iterate count for the next pass
        
        // For each instruction in the block
        for (Instruction &instruction : basicBlock) {
            
            // If its a function call
            if (auto *call = dyn_cast<CallInst>(&instruction)) {
                
                // which is a standardlib one
                MDNode *metadata = call->getMetadata(initiID);
                if (metadata == nullptr)
                    continue; // if isn’t a `stdlib.init` call
                
                // Run the stdlib inline pass
                
                // get info about caller and callee
                StringRef fnName = call->getCalledFunction()->getName();
                Type *returnType = call->getType();
                Function *stdLibCalledFunction = stdLibModule->getFunction(fnName);
                bool isVoidFunction = returnType->isVoidTy();
                
                if (stdLibCalledFunction == nullptr)
                    continue;
                

                // make copy of function (which we can mutate)
                ValueToValueMapTy VMap;
                Function *calledFunction = CloneFunction(stdLibCalledFunction, VMap, false);
                
                if (calledFunction == nullptr)
                    continue;
                
                // move builder to call
                builder.SetInsertPoint(call);

                // allocate the *return* value
                Value *returnValueStorage = nullptr;
                if (!isVoidFunction) {
                    returnValueStorage = builder.CreateAlloca(returnType);
                }
                
                // split the current bb, and do all temp work in `inlinedBlock`
                BasicBlock *rest = basicBlock.splitBasicBlock(call, Twine(basicBlock.getName() + ".rest"));
                BasicBlock *inlinedBlock = BasicBlock::Create(context, Twine("inlined." + fnName), &function, rest);
                call->removeFromParent();

                rest->replaceAllUsesWith(inlinedBlock); // move predecessors into `inlinedBlock`
                builder.SetInsertPoint(inlinedBlock);   // add IR code here
                
                // for block & instruction in the stdlib function’s definition
                for (BasicBlock &fnBlock : *calledFunction) {
                    for (Instruction &inst : fnBlock) {
                        
                        // if the instruction is a return, assign to
                        // the `returnValueStorage` and jump out of temp block
                        Instruction *newInst = inst.clone();
                        if (auto *ret = dyn_cast<ReturnInst>(newInst)) {
                            
                            if (!isVoidFunction) {
                                Value *res = ret->getReturnValue();
                                builder.CreateStore(res, returnValueStorage);
                            }
                            
                            builder.CreateBr(rest);
                        }
                        // if its a function, we need to make sure its declared in our module
                        else if (auto *call = dyn_cast<CallInst>(newInst)) {
                            
                            if (call->getCalledFunction()->isIntrinsic()) {
                                std::cout << call->getCalledFunction()->getName().data() << "\n";
                                
                                
                                
                                Function *intrinsic = getIntrinsic(call->getCalledFunction()->getName(),
                                                                   module,
                                                                   call->getOperand(0)->getType());
                                call->setCalledFunction(intrinsic);
                            }
                            else {
                                ValueToValueMapTy VMap;
                                Function *fnThisModule = CloneFunction(call->getCalledFunction(), VMap, false);
                                
                                module->getOrInsertFunction(fnThisModule->getName(),
                                                            fnThisModule->getFunctionType(),
                                                            fnThisModule->getAttributes());
                                
                                Function *newProto = module->getFunction(fnThisModule->getName());
                                
                                call->setCalledFunction(newProto);
                            }
                            
                            inst.replaceAllUsesWith(call);
                            builder.Insert(call, call->getName());
                        }
                        // otherwise add the inst to the inlined block
                        else {
                            inst.replaceAllUsesWith(newInst);
                            builder.Insert(newInst, newInst->getName());
                        }
                    }
                }
                
                // move out of `inlinedBlock`
                builder.SetInsertPoint(rest, rest->begin());
                
                // replace uses of %0, %1 in the function with the parameters passed into it
                uint i = 0;
                for (Argument &fnArg : calledFunction->args()) {
                    Value *calledArg = call->getOperand(i);
                    
                    fnArg.replaceAllUsesWith(calledArg);
                    i++;
                }
                
                // finalise -- store result in return val, and remove call from bb
                if (!isVoidFunction) {
                    Value *returnValue = builder.CreateLoad(returnValueStorage, fnName);
                    call->replaceAllUsesWith(returnValue);
                }
                call->dropAllReferences();
                
                // merge inlined block’s head with the predecessor block
                MergeBlockIntoPredecessor(inlinedBlock);
                
                // if exit can only come from one place, merge it in too
                if (rest->getUniquePredecessor()) {
                    MergeBlockIntoPredecessor(rest);
                }
                
                // reference to in module definition of stdlib function
                Function *proto = module->getFunction(fnName);
                if (proto->getNumUses() == 0) {
                    proto->removeFromParent();
                    proto->dropAllReferences();
                }
                
                // we have modified the function -- this tells the pass manager
                changed = true;
                // we want to iterate over the block again to make sure
                // the stuff we added and the stuff after it is optimised
                --index;
                // go back to do the block again
                break;
            }
            
        }
    }
    
    return changed;
}


/// Expose to the general optimiser function
void addStdLibInlinePass(const PassManagerBuilder &Builder, PassManagerBase &PM) {
    PM.add(createStdLibInlinePass());               // run my opt pass
    PM.add(createPromoteMemoryToRegisterPass());    // remove the extra load & store
}





