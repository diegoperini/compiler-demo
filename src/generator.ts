import * as llvm from "llvm-node"
import 'coffeescript/register'
import * as el from './external-libs'
import './util'

// Context
let context = new llvm.LLVMContext
llvm.initializeAllTargetInfos()
llvm.initializeAllTargets()
llvm.initializeAllTargetMCs()
llvm.initializeAllAsmParsers()
llvm.initializeAllAsmPrinters()

// Native Types
type IntT = { t: llvm.Type, signed: boolean }
let Int8Type = llvm.Type.getInt8Ty(context)
export function getInt8Type() : IntT {
  return { t: Int8Type, signed: true }
}
let Int16Type = llvm.Type.getInt16Ty(context)
export function getInt16Type() : IntT {
  return { t: Int16Type, signed: true }
}
let Int32Type = llvm.Type.getInt32Ty(context)
export function getInt32Type() : IntT {
  return { t: Int32Type, signed: true }
}
let Int64Type = llvm.Type.getInt64Ty(context)
export function getInt64Type() : IntT {
  return { t: Int64Type, signed: true }
}

let Uint8Type = llvm.Type.getInt8Ty(context)
export function getUInt8Type() : IntT {
  return { t: Uint8Type, signed: false }
}
let Uint16Type = llvm.Type.getInt16Ty(context)
export function getUInt16Type() : IntT {
  return { t: Uint16Type, signed: false }
}
let Uint32Type = llvm.Type.getInt32Ty(context)
export function getUInt32Type() : IntT {
  return { t: Uint32Type, signed: false }
}
let Uint64Type = llvm.Type.getInt64Ty(context)
export function getUInt64Type() : IntT {
  return { t: Uint64Type, signed: false }
}

let Float16Type = llvm.Type.getHalfTy(context)
export function getFloat16Type() : { t: llvm.Type } {
  return { t: Float16Type }
}
type FloatT = { t: llvm.Type }
let Float32Type = llvm.Type.getFloatTy(context)
export function getFloat32Type() : FloatT {
  return { t: Float32Type }
}
let Float64Type = llvm.Type.getDoubleTy(context)
export function getFloat64Type() : FloatT {
  return { t: Float64Type }
}

type BoolT = { t: llvm.Type, bool: boolean }
let BoolType = llvm.Type.getInt8Ty(context)
export function getBoolType() : BoolT {
  return { t: BoolType, bool: true }
}

type VoidT = { t: llvm.Type }
let VoidType = llvm.Type.getVoidTy(context)
export function getVoidType() : VoidT {
  return { t: VoidType }
}

type StringT = { t: llvm.Type }
let StringType = llvm.Type.getInt8Ty(context)
export function getStringType() : StringT {
  return { t: llvm.PointerType.get(StringType, 0) }
}

type TypeT = { t: llvm.StructType, properties: TypeT[] } | IntT | FloatT | VoidT | StringT
export function createType(properties: TypeT[], name?: string) : TypeT {
  let struct = llvm.StructType.create(context, name)
  let props = [getInt32Type().t, ...properties.map((p) => llvm.PointerType.get(p.t, 0))]

  struct.setBody(props, false)

  return { t: struct, properties: props }
}

const Unit = createType([], "Unit")
export function getUnitType() : TypeT {
  return Unit
}

// Scopes
export function createModule(name: string) : llvm.Module {
  let m = new llvm.Module(name, context)
  m.targetTriple = "x86_64-apple-darwin17.7.0"

  let target = llvm.TargetRegistry.lookupTarget(m.targetTriple)
  let targetMachine = target.createTargetMachine(m.targetTriple, "generic")
  m.dataLayout = targetMachine.createDataLayout()

  return m
}

// Functions
type Main = { mainBlock: llvm.BasicBlock, mainBuilder: llvm.IRBuilder, mainReturnAlloca: llvm.AllocaInst, unitAlloca: llvm.AllocaInst }
export function createMain(llvmModule: llvm.Module, scope: (main: Main) => void) : Main {
  let intType = llvm.Type.getInt32Ty(context)
  let mainFuncType = llvm.FunctionType.get(intType, false)
  let mainFunc = llvmModule.getOrInsertFunction("main", mainFuncType)
  let mainBlock = llvm.BasicBlock.create(context, "", mainFunc as llvm.Function)
  let mainBuilder = new llvm.IRBuilder(mainBlock)

  let mainReturnAlloca = mainBuilder.createAlloca(intType, createConstant(1), "mainReturn")
  mainBuilder.createStore(createConstant(0), mainReturnAlloca)
  let unitType = getUnitType()
  let unitAlloca = mainBuilder.createAlloca(unitType.t, createConstant(1), "unit")
  mainBuilder.createStore(llvm.ConstantStruct.get(unitType.t as llvm.StructType, [createConstant(0)]), unitAlloca)

  let main = { mainBlock, mainBuilder, mainReturnAlloca, unitAlloca }
  scope(main)

  mainBuilder.createRet(mainBuilder.createLoad(mainReturnAlloca))
  return main
}

type Function = { block: llvm.BasicBlock, builder: llvm.IRBuilder, returnAlloca: llvm.AllocaInst }
export function createFunction(llvmModule: llvm.Module, returnType: llvm.Type, params: TypeT, name: string, scope: (func: Function) => void) : Function {
  let funcType = llvm.FunctionType.get(returnType, [params.t], false)
  let func = llvm.Function.create(funcType, llvm.LinkageTypes.PrivateLinkage, name, llvmModule)
  let block = llvm.BasicBlock.create(context, "", func)
  let builder = new llvm.IRBuilder(block)
  let returnAlloca = builder.createAlloca(returnType, createConstant(1), name + "Return")

  let funcStruct = { block, builder, returnAlloca }
  scope(funcStruct)

  builder.createRet(builder.createLoad(returnAlloca))
  return funcStruct
}

// Values
export function createConstant(value: number, numberOfBits: number = 32, signed: boolean = true) : llvm.Constant {
  return llvm.ConstantInt.get(context, value, numberOfBits, signed)
}

export function createConstantFloat(value: number) : llvm.Constant {
  return llvm.ConstantFP.get(context, value)
}

// Debug log IR
export function logIR(llvmModule: llvm.Module) {
  console.log(llvmModule.print())
}

// Write bitcode to file
export function writeBitcodeToFile(llvmModule: llvm.Module, filePath: string) {
  llvm.writeBitcodeToFile(llvmModule, filePath)
}

function test() {
  let m = createModule("test")

  // let printfType = llvm.FunctionType.get(llvm.Type.getInt32Ty(context), [getStringType().t], true)
  // let printf = m.getOrInsertFunction("printf", printfType)

  createMain(m, (main: Main) => {
    el.printf("Hello öç.pğüşiı😄 😅 😆 😉 World! %d\n",  [createConstant(123)], context, m, main.mainBuilder)

    // createFunction(m, getInt32Type().t, getUnitType(), "testFunc", (func: Function) => {
    //   func.builder.createStore(createConstant(42), func.returnAlloca)
    // })

  })

  logIR(m)
  writeBitcodeToFile(m, "./lol.bit")

  // Bash:
  // =====
  // ts-node src/generator.ts
  // llc -o lol.a lol.bit
  // as lol.a -o lol.o
  // ld -e _main -macosx_version_min 10.13 -arch x86_64 lol.o -lSystem -o lol
  // otool -tvV lol

  // ts-node src/generator.ts && llc -o lol.a lol.bit && cat lol.a && as lol.a -o lol.o && ld -e _main -macosx_version_min 10.13 -arch x86_64 lol.o -lSystem -o lol && ./lol && otool -tvV lol && rm lol*

  // ts-node src/generator.ts
  // llc -filetype=obj -o lol.o lol.bit
  // clang lol.o -o lol
  // otool -tvV lol
}

// test()
