import * as llvm from "llvm-node"

import context from './llvm-context'
import * as PT from './primitive-types'

// Native Types
export type TypeT =
  { t: llvm.StructType, properties: TypeT[] } |
  PT.IntT |
  PT.FloatT |
  PT.VoidT |
  PT.StringT
export function createType(properties: TypeT[], name?: string) : TypeT {
  let struct = llvm.StructType.create(context, name)
  let props = [PT.getInt32Type().t, ...properties.map((p) => llvm.PointerType.get(p.t, 0))]

  struct.setBody(props, false)

  return { t: struct, properties: props }
}

const Unit = createType([], "Unit")
export function getUnitType() : TypeT {
  return Unit
}
