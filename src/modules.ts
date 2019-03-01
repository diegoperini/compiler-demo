import * as llvm from "llvm-node"

import context from './llvm-context'

export function createModule(name: string) : llvm.Module {
  let m = new llvm.Module(name, context)
  m.targetTriple = "x86_64-apple-darwin17.7.0"

  let target = llvm.TargetRegistry.lookupTarget(m.targetTriple)
  let targetMachine = target.createTargetMachine(m.targetTriple, "generic")
  m.dataLayout = targetMachine.createDataLayout()

  return m
}
