import * as llvm from "llvm-node"

import context from './llvm-context'
import { TypeT } from './types'
import { createConstant } from './constants'

export type Function = {
  block: llvm.BasicBlock,
  builder: llvm.IRBuilder,
  returnFromFunction: (value: llvm.Value) => void
}

export function createFunction(
  llvmModule: llvm.Module,
  returnType: llvm.Type,
  params: TypeT,
  name: string,
  scope: (func: Function) => void
) : Function {
  let funcType = llvm.FunctionType.get(returnType, [params.t], false)
  let func = llvm.Function.create(funcType, llvm.LinkageTypes.PrivateLinkage, name, llvmModule)

  let returnBlock = llvm.BasicBlock.create(context, "ReturnBlock", func)
  let returnBuilder = new llvm.IRBuilder(returnBlock)

  let block = llvm.BasicBlock.create(context, name + "Block", func, returnBlock)
  let builder = new llvm.IRBuilder(block)

  let returnAlloca = builder.createAlloca(returnType, createConstant(1), name + "Return")
  /* let returnLocation = */returnBuilder.createRet(returnBuilder.createLoad(returnAlloca))
  // TODO : store initialized valie in returnAlloca

  let returned = false
  function returnFromFunction(value: llvm.Value) : void {
    builder.createStore(value, returnAlloca)
    builder.createBr(returnBlock)
    returned = true
  }

  let funcStruct = { block, builder, returnFromFunction }
  scope(funcStruct)
  if (!returned) returnFromFunction(builder.createLoad(returnAlloca))
  return funcStruct
}
