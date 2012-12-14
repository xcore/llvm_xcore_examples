target triple = "xcore-xmos-elf"

declare i8* @llvm.xcore.checkevent(i8*) nounwind
declare void @llvm.xcore.clre() nounwind
declare void @llvm.xcore.setc.p1i8(i8 addrspace(1)* nocapture, i32) nounwind
declare void @llvm.xcore.setv.p1i8(i8 addrspace(1)* nocapture, i8*) nounwind
declare void @llvm.xcore.eeu.p1i8(i8 addrspace(1)* nocapture) nounwind
declare i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* nocapture) nounwind
declare i8* @llvm.xcore.waitevent() nounwind readonly

; void f(streaming chanend c) {
;   select {
;   case c :> int x:
;     return x;
;   }
; }
define i32 @f(i8 addrspace(1)* nocapture %c) nounwind {
entry:
  ; Disable events on all resources owned by the thread.
  call void @llvm.xcore.clre()
  ; Set resource vector to the address of the case.
  call void @llvm.xcore.setv.p1i8(i8 addrspace(1)* %c, i8* blockaddress(@f, %selectcase))
  ; Enable events on the resource
  call void @llvm.xcore.eeu.p1i8(i8 addrspace(1)* %c)
  ; Wait for an event on one of the resources. Conceptually
  ; llvm.xcore.waitevent() enables events and returns the value of the vector
  ; associated with resource that is ready. If no resources are ready it will
  ; wait until a resource becomes ready. The result of the intrinsic must be
  ; used as the operand of an indirect branch. When the backend generates code
  ; it enables events but doesn't emit a branch instruction - the branch is
  ; done in hardware when the event is taken.
  %addr = call i8* @llvm.xcore.waitevent()
  indirectbr i8* %addr, [label %selectcase]

selectcase:
  ; Complete the input
  %x = call i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* %c)
  ret i32 %x
}

; void g(streaming chanend c) {
;   select {
;   case c :> int x:
;     return x;
;   default:
;     return 0;
;   }
; }
define i32 @g(i8 addrspace(1)* nocapture %c) nounwind {
entry:
  ; Disable events on all resources owned by the thread.
  call void @llvm.xcore.clre()
  ; Set resource vector to the address of the case.
  call void @llvm.xcore.setv.p1i8(i8 addrspace(1)* %c, i8* blockaddress(@f, %selectcase))
  ; Enable events on the resource
  call void @llvm.xcore.eeu.p1i8(i8 addrspace(1)* %c)
  ; Check for events on the resources. If no resources are ready then the
  ; address given as an operand is returned. Like llvm.xcore.waitevent() the
  ; result of the intrinsic must be used as the operand of an indirect branch.
  %addr = call i8* @llvm.xcore.checkevent(i8* blockaddress(@g, %defaultcase))
  indirectbr i8* %addr, [label %selectcase, label %defaultcase]

selectcase:
  ; Complete the input
  %x = call i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* %c)
  ret i32 %x

defaultcase:
  ret i32 0
}
