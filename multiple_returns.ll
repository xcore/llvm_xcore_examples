target triple = "xcore-xmos-elf"
; A multiple return function in XC is represented by a function returning
; a struct in the LLVM IR.

; For example
; {int, int, int} f(int x, int y, int z) {
;   return {x, y, z};
; }
; compiles to:
define { i32, i32, i32 } @f(i32 %x, i32 %y, i32 %y) nounwind {
  %0 = insertvalue { i32, i32, i32 } undef, i32 %x, 0
  %1 = insertvalue { i32, i32, i32 } %0, i32 %y, 1
  %2 = insertvalue { i32, i32, i32 } %1, i32 %z, 2
  ret { i32, i32, i32 } %2
}

; void g() {
;   f(1, 2, 3);
; }
; compiles to
define void @g() nounwind {
  %0 = call { i32, i32, i32 } @f(i32 0, i32 1, i32 2)
  %1 = extractvalue { i32, i32, i32 } %0, 0
  %2 = extractvalue { i32, i32, i32 } %0, 1
  %3 = extractvalue { i32, i32, i32 } %0, 2
  ret void
}
