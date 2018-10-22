import * as llvm from "llvm-node"

let context = new llvm.LLVMContext
let llvmModule = new llvm.Module('test', context)
let intType = llvm.Type.getInt32Ty(context)
let mainFuncType = llvm.FunctionType.get(intType, false)
let mainFunc = llvmModule.getOrInsertFunction("main", mainFuncType)
let mainBlock = llvm.BasicBlock.create(context, "", mainFunc as llvm.Function)
let mainBuilder = new llvm.IRBuilder(mainBlock)

mainBuilder.createRetVoid()

console.log(llvmModule.print())
// llvm.writeBitcodeToFile(llvmModule, './lol.exe')
