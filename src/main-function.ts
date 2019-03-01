import * as llvm from "llvm-node"

import context from './llvm-context'

import { T } from './types'
import { createConstant } from './constants'

export type Main = {
  mainBlock: llvm.BasicBlock,
  mainBuilder: llvm.IRBuilder,
  returnFromMain: (value: llvm.Value) => void,
  unitAlloca: llvm.AllocaInst
}

export function createMain(llvmModule: llvm.Module, scope: (main: Main) => void) : Main {
  let returnType = llvm.Type.getInt32Ty(context)
  let mainFuncType = llvm.FunctionType.get(returnType, false)
  // let mainFunc = llvmModule.getOrInsertFunction("main", mainFuncType)
  let mainFunc = llvm.Function.create(
    mainFuncType,
    llvm.LinkageTypes.ExternalLinkage,
    "main",
    llvmModule
  )

  let returnBlock = llvm.BasicBlock.create(context, "ReturnBlock", mainFunc)
  let returnBuilder = new llvm.IRBuilder(returnBlock)

  let mainBlock = llvm.BasicBlock.create(context, "MainBlock", mainFunc, returnBlock)
  let mainBuilder = new llvm.IRBuilder(mainBlock)

  let returnAlloca = mainBuilder.createAlloca(returnType, createConstant(1), "MainReturn")
  /* let returnLocation = */returnBuilder.createRet(returnBuilder.createLoad(returnAlloca))
  mainBuilder.createStore(createConstant(0), returnAlloca)

  let returned = false
  function returnFromMain(value: llvm.Value) : void {
    mainBuilder.createStore(value, returnAlloca)
    mainBuilder.createBr(returnBlock)
    returned = true
  }

  let unitType = T.getUnitType()
  let unitAlloca = mainBuilder.createAlloca(unitType.t, createConstant(1), "unit")
  mainBuilder.createStore(
    llvm.ConstantStruct.get(unitType.t as llvm.StructType, [createConstant(0)]),
    unitAlloca
  )

  let main = { mainBlock, mainBuilder, returnFromMain, unitAlloca }
  scope(main)
  if (!returned) returnFromMain(mainBuilder.createLoad(returnAlloca))

  return main
}
