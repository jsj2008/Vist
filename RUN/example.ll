; ModuleID = 'vist_module'
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.11.0"

define i64 @main() {
entry:
  %0 = tail call { i64 } @_Int_i64(i64 4), !stdlib.init !0
  tail call void @_print_S.i64({ i64 } { i64 3 })
  tail call void @_print_S.i64({ i64 } %0)
  ret i64 0
}

declare { i64 } @_Int_i64(i64)

declare void @_print_S.i64({ i64 })

!0 = !{!"stdlib.init"}
