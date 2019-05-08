import * as llvm from "llvm-node"

import context from './llvm-context'
import * as el from './external-libs'
import { createModule } from './modules'
import { createMain, Main } from './main-function'
import { createConstant } from './constants'

// Debug log IR
export function logIR(llvmModule: llvm.Module) {
  console.log(llvmModule.print())
}

export function getIR(llvmModule: llvm.Module) {
  return llvmModule.print()
}

// Write bitcode to file
export function writeBitcodeToFile(llvmModule: llvm.Module, filePath: string) {
  try {
    llvm.verifyModule(llvmModule)
  } catch(e) {
    console.error(e)
  }

  llvm.writeBitcodeToFile(llvmModule, filePath)
}

// TODO : remove this eventually
function test() {
  let m = createModule("test")

  createMain(m, (main: Main) => {
    el.printf(
      "Hello öç.pğüşiı😄 😅 😆 😉 World! %d\n",
      [createConstant(123)],
      context,
      m,
      main.mainBuilder
    )
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
