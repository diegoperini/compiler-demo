import * as llvm from "llvm-node"

// Context
let context = new llvm.LLVMContext

// Native Types
let Int8Type = llvm.Type.getInt8Ty(context)
function getInt8Type() : { t:llvm.Type, signed: boolean } {
  return { t: Int8Type, signed: true }
}
let Int16Type = llvm.Type.getInt16Ty(context)
function getInt16Type() : { t:llvm.Type, signed: boolean } {
  return { t: Int16Type, signed: true }
}
let Int32Type = llvm.Type.getInt32Ty(context)
function getInt32Type() : { t:llvm.Type, signed: boolean } {
  return { t: Int32Type, signed: true }
}
let Int64Type = llvm.Type.getInt64Ty(context)
function getInt64Type() : { t:llvm.Type, signed: boolean } {
  return { t: Int64Type, signed: true }
}

let Uint8Type = llvm.Type.getInt8Ty(context)
function getUint8Type() : { t:llvm.Type, signed: boolean } {
  return { t: Uint8Type, signed: false }
}
let Uint16Type = llvm.Type.getInt16Ty(context)
function getUint16Type() : { t:llvm.Type, signed: boolean } {
  return { t: Uint16Type, signed: false }
}
let Uint32Type = llvm.Type.getInt32Ty(context)
function getUint32Type() : { t:llvm.Type, signed: boolean } {
  return { t: Uint32Type, signed: false }
}
let Uint64Type = llvm.Type.getInt64Ty(context)
function getUint64Type() : { t:llvm.Type, signed: boolean } {
  return { t: Uint64Type, signed: false }
}

// TODO : add Float16Type once getHalfTy() is in the API
// let Float16Type = llvm.Type.getFloatTy(context)
// function getFloat16Type() : { t: llvm.Type } {
//   return { t: Float16Type }
// }
let Float32Type = llvm.Type.getFloatTy(context)
function getFloat32Type() : { t: llvm.Type } {
  return { t: Float32Type }
}
let Float64Type = llvm.Type.getDoubleTy(context)
function getFloat64Type() : { t: llvm.Type } {
  return { t: Float64Type }
}

let BoolType = llvm.Type.getInt8Ty(context)
function getBoolType() : { t: llvm.Type, bool: boolean } {
  return { t: BoolType, bool: true }
}

let VoidType = llvm.Type.getVoidTy(context)
function getVoidType() : { t: llvm.Type, bool: boolean } {
  return { t: VoidType, bool: true }
}

let StringType = llvm.Type.getInt8Ty(context)
function getStringType(count: number) : { t: llvm.Type, count: number } {
  return { t: llvm.ArrayType.get(StringType, count), count: count }
}

// Scopes
function createModule(name: string) {
  return new llvm.Module(name, context)
}

function createMain(llvmModule: llvm.Module) : { mainBlock: llvm.BasicBlock, mainBuilder: llvm.IRBuilder, mainReturnAlloca: llvm.AllocaInst} {
  let intType = llvm.Type.getInt32Ty(context)
  let mainFuncType = llvm.FunctionType.get(intType, false)
  let mainFunc = llvmModule.getOrInsertFunction("main", mainFuncType)
  let mainBlock = llvm.BasicBlock.create(context, "", mainFunc as llvm.Function)
  let mainBuilder = new llvm.IRBuilder(mainBlock)
  let mainReturnAlloca = mainBuilder.createAlloca(intType)

  mainBuilder.createStore(createConstant(2), mainReturnAlloca)
  mainBuilder.createRet(mainBuilder.createLoad(mainReturnAlloca))

  return { mainBlock, mainBuilder, mainReturnAlloca }
}

// Values
function createConstant(value: number) : llvm.Value {
  return llvm.ConstantInt.get(context, value)
}

// Debug log IR
function logIR(llvmModule: llvm.Module) {
  console.log(llvmModule.print())
}

// Write bitcode to file
function writeBitcodeToFile(llvmModule: llvm.Module, filePath: string) {
  llvm.writeBitcodeToFile(llvmModule, filePath)
}

function test() {
  let m = createModule("test")
  let main = createMain(m)

  logIR(m)
  writeBitcodeToFile(m, "./lol.bit")

  // Bash:
  // =====
  // ts-node src/llvm-demo.ts
  // llc -o lol.asm lol.bit
  // llvm-as -i lol lol.asm
}

test()
