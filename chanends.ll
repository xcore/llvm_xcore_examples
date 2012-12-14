target triple = "xcore-xmos-elf"

declare i8 addrspace(1)* @llvm.xcore.getr.p1i8(i32) nounwind
declare void @llvm.xcore.setd.p1i8(i8 addrspace(1)* nocapture, i32) nounwind
declare void @llvm.xcore.out.p1i8(i8 addrspace(1)* nocapture, i32) nounwind
declare void @llvm.xcore.outt.p1i8(i8 addrspace(1)* nocapture, i32) nounwind
declare i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* nocapture) nounwind
declare i32 @llvm.xcore.int.p1i8(i8 addrspace(1)* nocapture) nounwind
declare void @llvm.xcore.freer.p1i8(i8 addrspace(1)* nocapture) nounwind
declare void @llvm.xcore.outct.p1i8(i8 addrspace(1)* nocapture, i32) nounwind
declare void @llvm.xcore.chkct.p1i8(i8 addrspace(1)* nocapture, i32) nounwind

; This function demonstrates how to create a channel by connecting two chanend
; resources.
define void @f() nounwind {
  ; Allocate two chanends
  %x = call i8 addrspace(1)* @llvm.xcore.getr.p1i8(i32 2)
  %y = call i8 addrspace(1)* @llvm.xcore.getr.p1i8(i32 2)

  ; Connect the two chanends
  %y_cast = ptrtoint i8 addrspace(1)* %y to i32
  call void @llvm.xcore.setd.p1i8(i8 addrspace(1)* %x, i32 %y_cast)
  %x_cast = ptrtoint i8 addrspace(1)* %x to i32
  call void @llvm.xcore.setd.p1i8(i8 addrspace(1)* %y, i32 %x_cast)

  ; Use chanends here...

  ; Free the chanends
  call void @llvm.xcore.freer.p1i8(i8 addrspace(1)* %x)
  call void @llvm.xcore.freer.p1i8(i8 addrspace(1)* %y)

  ret void
}

; This function demonstrates I/O on streaming chanends:
define void @g(i8 addrspace(1)* %chanend, i8 %x1, i16 %x2, i32 %x3) nounwind {
  ; Output 8-bit integer
  %x1_zext = zext i8 %x1 to i32
  tail call void @llvm.xcore.outt.p1i8(i8 addrspace(1)* %chanend, i32 %x1_zext)

  ; Output 16-bit integer
  %x2_zext = zext i16 %x2 to i32
  %x2_hi = lshr i32 %x2_zext, 8
  %x2_lo = and i32 %x2_zext, 255
  call void @llvm.xcore.outt.p1i8(i8 addrspace(1)* %chanend, i32 %x2_hi)
  call void @llvm.xcore.outt.p1i8(i8 addrspace(1)* %chanend, i32 %x2_lo)

  ; Output 32-bit integer
  call void @llvm.xcore.out.p1i8(i8 addrspace(1)* %chanend, i32 %x3)

  ; Input 8-bit integer
  %y1 = call i32 @llvm.xcore.int.p1i8(i8 addrspace(1)* %chanend) nounwind
  %y1_trunc = trunc i32 %y1 to i8

  ; Input 16-bit integer
  %y2_hi = call i32 @llvm.xcore.int.p1i8(i8 addrspace(1)* %chanend) nounwind
  %y2_lo = call i32 @llvm.xcore.int.p1i8(i8 addrspace(1)* %chanend) nounwind
  %y2_hi_shift = shl i32 %y2_hi, 8
  %y2 = or i32 %y2_hi, %y2_lo
  %y2_trunc = trunc i32 %y2 to i6

  ; Input 32-bit integer
  %y3 = call i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* %chanend) nounwind

  ret void
}

; This function outputs a 32-bit integer on a non streaming channel.
; See the ABI for more details.
define void @output(i8 addrspace(1)* %chanend, i32 %x) nounwind {
  ; Initial handshake (outct CT_END; chkct CT_END)
  call void @llvm.xcore.outct.p1i8(i8 addrspace(1)* %chanend, i32 1)
  call void @llvm.xcore.chkct.p1i8(i8 addrspace(1)* %chanend, i32 1)
  ; Do the actual output
  call void @llvm.xcore.out.p1i8(i8 addrspace(1)* %chanend, i32 %x)
  ; End the packet  (outct CT_END; chkct CT_END)
  call void @llvm.xcore.outct.p1i8(i8 addrspace(1)* %chanend, i32 1)
  call void @llvm.xcore.chkct.p1i8(i8 addrspace(1)* %chanend, i32 1)
  ret void
}

; This function inputs a 32-bit integer on a non streaming channel.
; See the ABI for more details.
define i32 @input(i8 addrspace(1)* %chanend, i32 %x) nounwind {
  ; Initial handshake (chkct CT_END; outct CT_END)
  call void @llvm.xcore.chkct.p1i8(i8 addrspace(1)* %chanend, i32 1)
  call void @llvm.xcore.outct.p1i8(i8 addrspace(1)* %chanend, i32 1)
  ; Do the actual output
  %result = call i32 @llvm.xcore.in.p1i8(i8 addrspace(1)* %chanend)
  ; End the packet (chkct CT_END; outct CT_END)
  call void @llvm.xcore.chkct.p1i8(i8 addrspace(1)* %chanend, i32 1)
  call void @llvm.xcore.outct.p1i8(i8 addrspace(1)* %chanend, i32 1)
  ret i32 %result
}
