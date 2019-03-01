import * as llvm from "llvm-node"

import context from './llvm-context'

export function createConstant(
  value: number,
  numberOfBits: number = 32,
  signed: boolean = true
) : llvm.Constant {
  return llvm.ConstantInt.get(context, value, numberOfBits, signed)
}

export function createConstantFloat(value: number) : llvm.Constant {
  return llvm.ConstantFP.get(context, value)
}
