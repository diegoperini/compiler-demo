import * as llvm from "llvm-node"

import context from './llvm-context'

export type IntT = { t: llvm.Type, signed: boolean }
const Int8Type = llvm.Type.getInt8Ty(context)
export function getInt8Type() : IntT {
  return { t: Int8Type, signed: true }
}
const Int16Type = llvm.Type.getInt16Ty(context)
export function getInt16Type() : IntT {
  return { t: Int16Type, signed: true }
}
const Int32Type = llvm.Type.getInt32Ty(context)
export function getInt32Type() : IntT {
  return { t: Int32Type, signed: true }
}
const Int64Type = llvm.Type.getInt64Ty(context)
export function getInt64Type() : IntT {
  return { t: Int64Type, signed: true }
}

const Uint8Type = llvm.Type.getInt8Ty(context)
export function getUInt8Type() : IntT {
  return { t: Uint8Type, signed: false }
}
const Uint16Type = llvm.Type.getInt16Ty(context)
export function getUInt16Type() : IntT {
  return { t: Uint16Type, signed: false }
}
const Uint32Type = llvm.Type.getInt32Ty(context)
export function getUInt32Type() : IntT {
  return { t: Uint32Type, signed: false }
}
const Uint64Type = llvm.Type.getInt64Ty(context)
export function getUInt64Type() : IntT {
  return { t: Uint64Type, signed: false }
}

const Float16Type = llvm.Type.getHalfTy(context)
export function getFloat16Type() : { t: llvm.Type } {
  return { t: Float16Type }
}
export type FloatT = { t: llvm.Type }
const Float32Type = llvm.Type.getFloatTy(context)
export function getFloat32Type() : FloatT {
  return { t: Float32Type }
}
const Float64Type = llvm.Type.getDoubleTy(context)
export function getFloat64Type() : FloatT {
  return { t: Float64Type }
}

export type BoolT = { t: llvm.Type, bool: boolean }
const BoolType = llvm.Type.getInt8Ty(context)
export function getBoolType() : BoolT {
  return { t: BoolType, bool: true }
}

export type VoidT = { t: llvm.Type }
const VoidType = llvm.Type.getVoidTy(context)
export function getVoidType() : VoidT {
  return { t: VoidType }
}

export type StringT = { t: llvm.Type }
const StringType = llvm.Type.getInt8Ty(context)
export function getStringType() : StringT {
  return { t: llvm.PointerType.get(StringType, 0) }
}
