import * as llvm from "llvm-node"

let _printf: llvm.Constant = null
export function printf(
  str: string,
  args: llvm.Value[],
  context: llvm.LLVMContext,
  m: llvm.Module,
  builder: llvm.IRBuilder
) : llvm.CallInst {

  if (!_printf) {
    let printfType = llvm.FunctionType.get(
      llvm.Type.getInt32Ty(context),
      [llvm.PointerType.get(llvm.Type.getInt8Ty(context), 0)]
      , true
    )
    _printf = m.getOrInsertFunction("printf", printfType)
  }

  return builder.createCall(_printf as llvm.Constant, [builder.createGlobalStringPtr(str), ...args])
}
