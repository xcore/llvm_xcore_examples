target triple = "xcore-xmos-elf"

declare i8 addrspace(1)* @llvm.xcore.getr.p1i8(i32) nounwind
declare i8 addrspace(1)* @llvm.xcore.getst.p1i8.p1i8(i8 addrspace(1)* nocapture) nounwind
declare void @llvm.xcore.initpc.p1i8(i8 addrspace(1)* nocapture, i8*) nounwind
declare void @llvm.xcore.initlr.p1i8(i8 addrspace(1)* nocapture, i8*) nounwind
declare void @llvm.xcore.initsp.p1i8(i8 addrspace(1)* nocapture, i8*) nounwind
declare void @llvm.xcore.tsetr.p1i8(i32, i8*, i8 addrspace(1)* nocapture) nounwind
declare void @llvm.xcore.msync.p1i8(i8 addrspace(1)* nocapture) nounwind
declare void @llvm.xcore.mjoin.p1i8(i8 addrspace(1)* nocapture) nounwind
declare void @llvm.xcore.freer.p1i8(i8 addrspace(1)* nocapture) nounwind
declare void @__child_cleanup() nounwind
declare void @a(i8 *) nounwind

; Consider this fragment of XC code:
;
; void f(char &x, char &y) {
;   par {
;     a(x); // runs on parent
;     a(y); // runs in child thread.
;   }
; }
;
;  This example can be compiled as follows:

define void @f(i8 *%x, i8 *%y) nounwind {
entry:
  ; Allocate some space for the child thread's stack.
  %child_stack = alloca i32, i32 100, align 4

  ; Allocate a synchronizer.
  %sync = call i8 addrspace(1)* @llvm.xcore.getr.p1i8(i32 3)

  ; Allocate a synchronized thread. We only allocate one thread in this example
  ; but we could allocate multiple threads if we wanted to.
  %thread = call i8 addrspace(1)* @llvm.xcore.getst.p1i8.p1i8(i8 addrspace(1)* %sync)

  ; Configure the thread so it starts executing @a
  call void @llvm.xcore.initpc.p1i8(i8 addrspace(1)* %thread, i8* bitcast (void (i8 *)* @a to i8*))

  ; Configure the thread so that when @a returns it jumps to __child_cleanup.
  ; __child_cleanup is a runtime library function does a ssync.
  call void @llvm.xcore.initlr.p1i8(i8 addrspace(1)* %thread, i8* bitcast (void ()* @__child_cleanup to i8*))

  ; Set the thread's stack pointer. The stack grows downwards so we must set the
  ; SP to the last word allocated.
  %sp = getelementptr i32* %child_stack, i32 99
  %sp_cast = bitcast i32* %sp to i8*
  call void @llvm.xcore.initsp.p1i8(i8 addrspace(1)* %thread, i8* %sp_cast)

  ; Set r0 of the child thread to the first argument of the function called
  ; in the child thread (ABI states that the first argument is passed in this
  ; register).
  call void @llvm.xcore.tsetr.p1i8(i32 0, i8* %y, i8 addrspace(1)* %thread)

  ; Start the threads
  call void @llvm.xcore.msync.p1i8(i8 addrspace(1)* %sync)

  ; Do work in the parent thread here...
  call void @a(i8 *%x) nounwind

  ; Wait until all threads have completed, then free the threads
  call void @llvm.xcore.mjoin.p1i8(i8 addrspace(1)* %sync)

  ; Free the synchronizer
  call void @llvm.xcore.freer.p1i8(i8 addrspace(1)* %sync)

  ret void
}

; If the statement in the par is not a function call the statement must be
; outlined into a function. Variables referenced from the par should be placed
; in a explictly managed structure instead of on the stack so that the child
; threads can be given access to these variables. For example:
;
; void f() {
;   int a = 1, b = 2;
;   par {
;     ...
;     a = b;
;   } 
; }
;
; is transformed into
;
; struct env {
;   int a;
;   int b;
; }
;
; static void child_thread(struct env *env) {
;   env.a = env.b;
; }
;
; void f() {
;   struct env;
;   env.a = 1;
;   env.b = 2;
;   par {
;     ...
;     child_thread(&env);
;   }
; }
;
