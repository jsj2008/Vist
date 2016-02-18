//
//  StdLibInline.cpp
//  Vist
//
//  Created by Josef Willsher on 24/01/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

#include "StdLibInline.hpp"

#include "LLVM.h"
#include "Intrinsic.hpp"
#include "Optimiser.hpp"
#include "CreateType.hpp"
#include "Utils.h"

#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <iostream>
#include <iterator>
#include <vector>

// useful instructions here: http://llvm.org/docs/WritingAnLLVMPass.html
// swift example here https://github.com/apple/swift/blob/master/lib/LLVMPasses/LLVMStackPromotion.cpp

#define DEBUG_TYPE "initialiser-pass"

using namespace llvm;

// MARK: StdLibInline pass decl

// TODO: make a subclass of `Inliner`
// http://llvm.org/docs/doxygen/html/Inliner_8cpp_source.html#l00358
class StdLibInline: public FunctionPass {
    
    Module *stdLibModule;
    
    virtual bool runOnFunction(Function &F) override;
    virtual bool doFinalization(Module &) override;
    
public:
    static char ID;
    
    StdLibInline(): FunctionPass(ID) {
        // FIXME: make a safer way of getting the directory path
        std::string path = std::string(SOURCE_ROOT) + std::string("/Vist/stdlib/stdlib.bc");
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


// TODO: fix recursive bullshit i've done
// http://comments.gmane.org/gmane.comp.compilers.llvm.devel/31198
//
//First, you may be invalidating the iterator i by erasing the value
//inside the loop.  In my code, I almost always iterate through the
//instructions once and record them in a std::vector.  I think loop
//through the std::vector, processing the end element and then remove it
//from the std::vector.  It is less efficient but ensures no nasty
//iterator invalidation errors.
//


/// Called on functions in module, this is where the optimisations happen
bool StdLibInline::runOnFunction(Function &function) {
    
    // we need a ref to the stdlib
    if (stdLibModule == nullptr)
        return false; // return if we don’t have it
    
    Module *module = function.getParent();
    LLVMContext &context = module->getContext();
    IRBuilder<> builder = IRBuilder<>(context);
    
    // id of the function call metadata we will optimise
    int initiID = LLVMMetadataID("stdlib.call.optim");
    
    // loops over blocks in function
    for (BasicBlock &basicBlock: function) {
        
        // For each instruction in the block
        for (Instruction &instruction: basicBlock) {
            
            builder.SetInsertPoint(&instruction);
            
            auto *call = dyn_cast<CallInst>(&instruction);
            
            if (call == nullptr)
                continue;
            // If its a function call
            
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
            if (!isVoidFunction)
                returnValueStorage = builder.CreateAlloca(returnType);
            
            // split the current bb, and do all temp work in `inlinedBlock`
            BasicBlock *rest = basicBlock.splitBasicBlock(call, Twine("inlined." + calledFunction->getName() + "." + calledFunction->getEntryBlock().getName()));
            BasicBlock *inlinedBlock = BasicBlock::Create(context,
                                                          Twine("rest." + calledFunction->getName() + "." + calledFunction->getEntryBlock().getName()),
                                                          &function,
                                                          rest);
            
            // replace the target of the branch inst at the end of `basicBlock`
            // with the inlined block, not the rest.
            auto *brInst = dyn_cast<BranchInst>(&basicBlock.back());
            brInst->setSuccessor(0, inlinedBlock);
            
            // finalise -- store result in return val, and remove call from bb
            builder.SetInsertPoint(rest, rest->begin()); // start of `rest`
            Value *loadReturnValue = nullptr;
            if (!isVoidFunction) {
                loadReturnValue = builder.CreateLoad(returnValueStorage, fnName);
                call->replaceAllUsesWith(loadReturnValue);
            }
            
            // replace uses of %0, %1 in the function definition with the parameters passed into it
            unsigned i = 0;
            for (Argument &fnArg: calledFunction->args()) {
                Value *calledArg = call->getOperand(i);
                
                fnArg.mutateType(calledArg->getType()); // HERE
                fnArg.replaceAllUsesWith(calledArg);
                i++;
            }
            
            builder.SetInsertPoint(inlinedBlock);   // add IR code here
            
            basicBlock.replaceSuccessorsPhiUsesWith(rest); //
            
            
            unsigned fnBBcount = 0;
            // for block & instruction in the stdlib function’s definition
            for (BasicBlock &fnBlock: *calledFunction) {
                BasicBlock *currentBlock;
                
                if (fnBBcount == 0) // if its the first
                    currentBlock = inlinedBlock;
                else
                    currentBlock = BasicBlock::Create(context,
                                                      Twine("inlined." + calledFunction->getName() + "." + fnBlock.getName()),
                                                      &function,
                                                      rest);
                ++fnBBcount;
                
                builder.SetInsertPoint(currentBlock);
                
                fnBlock.replaceSuccessorsPhiUsesWith(currentBlock);
                fnBlock.replaceAllUsesWith(currentBlock);
                
                for (Instruction &inst: fnBlock) {
                    
                    // insert value instructions dont get types replaced, so we do it manually
                    if (auto *insertVal = dyn_cast<InsertValueInst>(&inst)) {
                        
                        if (auto undef = dyn_cast<UndefValue>(insertVal->getAggregateOperand())) {
                            
                            StructType *ty = dyn_cast<StructType>(undef->getType());
                            if (!ty->hasName())
                                break;
                            
                            StringRef name = ty->getName();
                            auto idx = name.rfind("."); // remove the .0 suffix
                            auto thisName = name.drop_back(name.size() - idx);
                            Type *undefType = getNamedType(thisName, module);
                            UndefValue *undefValue = UndefValue::get(undefType); // the undef val
                            
                            inst.setOperand(0, undefValue);
                        }
                    }
                    
                    // replace global types in stdlib with this module
                    if (StructType *ty = dyn_cast<StructType>(inst.getType()))
                        if (ty->hasName())
                            inst.mutateType(getNamedType(ty->getStructName(), module));
                    
                    // if the instruction is a return, assign to
                    // the `returnValueStorage` and jump out of temp block
                    Instruction *newInst = inst.clone();
                    newInst->setName(inst.getName());
                    
                    if (auto *ret = dyn_cast<ReturnInst>(newInst)) {
                        
                        if (!isVoidFunction) {
                            ret->getReturnValue()->mutateType(returnType);
                            builder.CreateStore(ret->getReturnValue(), returnValueStorage);
                        }
                        builder.CreateBr(rest);
                        ret->dropAllReferences();
                    }
                    
                    // if its a function, we need to make sure its declared in our module
                    else if (auto *call = dyn_cast<CallInst>(newInst)) {
                        
                        // if its an intrinsic we need to make sure its in this module
                        if (call->getCalledFunction()->isIntrinsic()) {
                            
                            Type *optionalFirstArgument = call->getNumOperands() == 1
                            ? nullptr // if no arguments, we are not overloading
                           : call->getOperand(0)->getType();
                            
                            Function *intrinsic = getIntrinsic(call->getCalledFunction()->getName(),
                                                               module,
                                                               optionalFirstArgument,
                                                               true);
                            call->setCalledFunction(intrinsic);
                        }
                        // otherwise we copy in the body
                        else {
                            ValueToValueMapTy VMap;
                            Function *fnThisModule = CloneFunction(call->getCalledFunction(), VMap, false);
                            
                            module->getOrInsertFunction(fnThisModule->getName(),
                                                        fnThisModule->getFunctionType(),
                                                        fnThisModule->getAttributes());
                            
                            Function *newProto = module->getFunction(fnThisModule->getName());
                            
                            call->setCalledFunction(newProto);
                        }
                        
                        builder.Insert(call, call->getName());
                        inst.replaceAllUsesWith(newInst);
                    }
                    // otherwise add the inst to the inlined block
                    else {
                        
                        // loop through operands
                        
                        builder.Insert(newInst, inst.getName());
                        inst.replaceAllUsesWith(newInst);
                    }
                }
            }
            
            // remove refs to calls and
            calledFunction->dropAllReferences();
            call->dropAllReferences();
            call->removeFromParent();
            
            // move out of `inlinedBlock`
            builder.SetInsertPoint(rest, rest->begin());
            
            // merge inlined block’s head with the predecessor block
            MergeBlockIntoPredecessor(inlinedBlock);
            
            // if exit can only come from one place, merge it in too
            if (rest->getSinglePredecessor())
                MergeBlockIntoPredecessor(rest);
            
            // reference to in module definition of stdlib function
            Function *proto = module->getFunction(fnName);
            if (proto->getNumUses() == 0) {
                proto->removeFromParent();
                proto->dropAllReferences();
            }
            
            // call on the rest of the function
            runOnFunction(function);
            return true;
        }
    }
    
    return false;
}


/// Expose to the general optimiser function
void addStdLibInlinePass(const PassManagerBuilder &Builder, PassManagerBase &PM) {
    PM.add(createStdLibInlinePass());               // run my opt pass
    PM.add(createPromoteMemoryToRegisterPass());    // remove the extra load & store
    PM.add(createCFGSimplificationPass());
}

bool StdLibInline::doFinalization(Module &module) {
    return true;
}




