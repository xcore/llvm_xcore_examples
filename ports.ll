target triple = "xcore-xmos-elf"

declare void @llvm.xcore.out.p1i8(i8 addrspace(1)* nocapture, i32) nounwind
declare void @llvm.xcore.setc.p1i8(i8 addrspace(1)* nocapture, i32) nounwind
declare i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* nocapture) nounwind
declare void @llvm.xcore.setd.p1i8(i8 addrspace(1)* nocapture, i32) nounwind

; Global port declaration
@p = constant i8 addrspace(1)* inttoptr (i32 66048 to i8 addrspace(1)*)

; Constructor to turn on port before main
define internal void @p.ctor() nounwind {
entry:
  %p = load i8 addrspace(1)** @p
  call void @llvm.xcore.setc.p1i8(i8 addrspace(1)* %p, i32 8) ; INUSE_ON
  ret void
}

@llvm.global_ctors = appending global [1 x { i32, void ()* }] [{ i32, void ()* } { i32 65535, void ()* @p.ctor }]


define void @f() nounwind {
  %p = load i8 addrspace(1)** @p

  ; Simple port output p <: 0
  call void @llvm.xcore.out.p1i8(i8 addrspace(1)* %p, i32 0)

  ; Simple port input p :> int
  call void @llvm.xcore.setc.p1i8(i8 addrspace(1)* %p, i32 1) ; COND_NONE
  %a = call i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* %p)

  ; Conditional port input p when pinseq(10) :> int
  call void @llvm.xcore.setd.p1i8(i8 addrspace(1)* %p, i32 10)
  call void @llvm.xcore.setc.p1i8(i8 addrspace(1)* %p, i32 17) ; COND_EQ
  %b = call i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* %p)

  ; Many more combinations are possible. There are various intrinsics for 
  ; setting port times, getting timestamps, etc. The intrinsics map 1-1 to
  ; xCORE instructions so the best thing to do is read the xCORE
  ; architecture manual.
 
  ret void
}
