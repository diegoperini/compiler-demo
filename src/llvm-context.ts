import * as llvm from "llvm-node"

let context: llvm.LLVMContext = new llvm.LLVMContext

llvm.initializeAllTargetInfos()
llvm.initializeAllTargets()
llvm.initializeAllTargetMCs()
llvm.initializeAllAsmParsers()
llvm.initializeAllAsmPrinters()

export default context;
