target triple = "xcore-xmos-elf"

declare i8 addrspace(1)* @llvm.xcore.getr.p1i8(i32) nounwind
declare void @llvm.xcore.freer.p1i8(i8 addrspace(1)* nocapture) nounwind
declare void @llvm.xcore.setc.p1i8(i8 addrspace(1)* nocapture, i32) nounwind
declare i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* nocapture) nounwind
declare void @llvm.xcore.setd.p1i8(i8 addrspace(1)* nocapture, i32) nounwind

define void @f() nounwind {
entry:
  ; Allocate  a timer
  %t = call i8 addrspace(1)* @llvm.xcore.getr.p1i8(i32 1)

  ; Unconditional timer input (t :> x)
  call void @llvm.xcore.setc.p1i8(i8 addrspace(1)* %t, i32 1) ; COND_NONE
  %x = call i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* %t)

  ; Conditional timer input (t when timerafter(x + 100) :> void)
  %y = add i32 %x, 100
  call void @llvm.xcore.setd.p1i8(i8 addrspace(1)* %t, i32 %y)
  call void @llvm.xcore.setc.p1i8(i8 addrspace(1)* %t, i32 9) ; COND_AFTER
  %z = call i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* %t)

  ; Free timer
  call void @llvm.xcore.freer.p1i8(i8 addrspace(1)* %t)

  ret void
}
