; ModuleID = 'stdlib.ll'
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.11.0"

%Bool = type { i1 }
%Int = type { i64 }
%Double = type { double }
%Range = type { %Int, %Int }
%Int32 = type { i32 }
%String = type { i8*, i64 }

@.str = private unnamed_addr constant [6 x i8] c"%lli\0A\00", align 1
@.str1 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
@.str2 = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1
@.str3 = private unnamed_addr constant [6 x i8] c"true\0A\00", align 1
@.str4 = private unnamed_addr constant [7 x i8] c"false\0A\00", align 1

; Function Attrs: noinline nounwind ssp uwtable
define void @vist-Uprint_ti64(i64 %i) #0 {
entry:
  %call = tail call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([6 x i8]* @.str, i64 0, i64 0), i64 %i)
  ret void
}

; Function Attrs: nounwind
declare i32 @printf(i8* nocapture readonly, ...) #1

; Function Attrs: noinline nounwind ssp uwtable
define void @vist-Uprint_ti32(i32 %i) #0 {
entry:
  %call = tail call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str1, i64 0, i64 0), i32 %i)
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define void @vist-Uprint_tf64(double %d) #0 {
entry:
  %call = tail call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str2, i64 0, i64 0), double %d)
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define void @vist-Uprint_tf32(float %d) #0 {
entry:
  %conv = fpext float %d to double
  %call = tail call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str2, i64 0, i64 0), double %conv)
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define void @vist-Uprint_tb(i1 zeroext %b) #0 {
entry:
  %cond = select i1 %b, i8* getelementptr inbounds ([6 x i8]* @.str3, i64 0, i64 0), i8* getelementptr inbounds ([7 x i8]* @.str4, i64 0, i64 0)
  %call = tail call i32 (i8*, ...)* @printf(i8* %cond)
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define void @vist-Uprint_top(i8* nocapture readonly %str) #0 {
entry:
  %puts = tail call i32 @puts(i8* %str)
  ret void
}

; Function Attrs: nounwind readnone
define %Bool @-L_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = icmp slt i64 %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Bool @-E-E_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = icmp eq i64 %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Bool @-Uexpect_tBoolBool(%Bool %val, %Bool %assume) #2 {
entry:
  ret %Bool %val
}

; Function Attrs: nounwind readnone
define %Int @Int_ti64(i64 %"$0") #2 {
entry:
  %.fca.0.insert = insertvalue %Int undef, i64 %"$0", 0
  ret %Int %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Double @-P_tDoubleDouble(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = fadd double %0, %1
  %.fca.0.insert = insertvalue %Double undef, double %2, 0
  ret %Double %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Int @-G-G_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = ashr i64 %0, %1
  %.fca.0.insert = insertvalue %Int undef, i64 %2, 0
  ret %Int %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Double @Double_tf64(double %"$0") #2 {
entry:
  %.fca.0.insert = insertvalue %Double undef, double %"$0", 0
  ret %Double %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Double @Double_tDouble(%Double %val) #2 {
entry:
  ret %Double %val
}

; Function Attrs: nounwind readnone
define %Bool @-N-N_tBoolBool(%Bool %a, %Bool %b) #2 {
entry:
  %0 = extractvalue %Bool %a, 0
  %1 = extractvalue %Bool %b, 0
  %2 = and i1 %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Int @-T-O_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = or i64 %1, %0
  %.fca.0.insert = insertvalue %Int undef, i64 %2, 0
  ret %Int %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Int @-C_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = srem i64 %0, %1
  %.fca.0.insert = insertvalue %Int undef, i64 %2, 0
  ret %Int %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Range @Range_tRange(%Range %val) #2 {
entry:
  %0 = extractvalue %Range %val, 0
  %.fca.0.extract = extractvalue %Int %0, 0
  %1 = extractvalue %Range %val, 1
  %.fca.0.extract1 = extractvalue %Int %1, 0
  %.fca.0.0.insert = insertvalue %Range undef, i64 %.fca.0.extract, 0, 0
  %.fca.1.0.insert = insertvalue %Range %.fca.0.0.insert, i64 %.fca.0.extract1, 1, 0
  ret %Range %.fca.1.0.insert
}

; Function Attrs: nounwind readnone
define %Bool @Bool_tBool(%Bool %val) #2 {
entry:
  ret %Bool %val
}

; Function Attrs: nounwind
define void @print_tDouble(%Double %a) #3 {
entry:
  %0 = extractvalue %Double %a, 0
  tail call void @vist-Uprint_tf64(double %0)
  ret void
}

; Function Attrs: nounwind readnone
define %Bool @-E-E_tDoubleDouble(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = fcmp oeq double %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: noreturn nounwind
define void @fatalError_t() #4 {
entry:
  tail call void @llvm.trap()
  unreachable
}

; Function Attrs: nounwind readnone
define %Range @-D-D-D_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %a.fca.0.extract = extractvalue %Int %a, 0
  %b.fca.0.extract = extractvalue %Int %b, 0
  %.fca.0.0.insert = insertvalue %Range undef, i64 %a.fca.0.extract, 0, 0
  %.fca.1.0.insert = insertvalue %Range %.fca.0.0.insert, i64 %b.fca.0.extract, 1, 0
  ret %Range %.fca.1.0.insert
}

; Function Attrs: nounwind readnone
define %Int32 @Int32_ti32(i32 %"$0") #2 {
entry:
  %.fca.0.insert = insertvalue %Int32 undef, i32 %"$0", 0
  ret %Int32 %.fca.0.insert
}

; Function Attrs: nounwind
define %Int @-M_tIntInt(%Int %a, %Int %b) #3 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = tail call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %0, i64 %1)
  %3 = extractvalue { i64, i1 } %2, 1
  br i1 %3, label %-.trap, label %entry.cont

entry.cont:                                       ; preds = %entry
  %4 = extractvalue { i64, i1 } %2, 0
  %.fca.0.insert = insertvalue %Int undef, i64 %4, 0
  ret %Int %.fca.0.insert

-.trap:                                           ; preds = %entry
  tail call void @llvm.trap()
  unreachable
}

; Function Attrs: nounwind readnone
define %Bool @"!-E_tDoubleDouble"(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = fcmp one double %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Double @-C_tDoubleDouble(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = frem double %0, %1
  %.fca.0.insert = insertvalue %Double undef, double %2, 0
  ret %Double %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Int @-T-N_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = and i64 %1, %0
  %.fca.0.insert = insertvalue %Int undef, i64 %2, 0
  ret %Int %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Bool @-L-E_tDoubleDouble(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = fcmp ole double %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Double @-D_tDoubleDouble(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = fdiv double %0, %1
  %.fca.0.insert = insertvalue %Double undef, double %2, 0
  ret %Double %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Bool @Bool_tb(i1 %"$0") #2 {
entry:
  %.fca.0.insert = insertvalue %Bool undef, i1 %"$0", 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Bool @-L-E_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = icmp sle i64 %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind
define %Range @-D-D-L_tIntInt(%Int %a, %Int %b) #3 {
entry:
  %0 = extractvalue %Int %b, 0
  %1 = tail call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %0, i64 1) #3
  %2 = extractvalue { i64, i1 } %1, 1
  br i1 %2, label %-.trap.i, label %-M_tIntInt.exit

-.trap.i:                                         ; preds = %entry
  tail call void @llvm.trap() #3
  unreachable

-M_tIntInt.exit:                                  ; preds = %entry
  %3 = extractvalue { i64, i1 } %1, 0
  %a.fca.0.extract = extractvalue %Int %a, 0
  %.fca.0.0.insert = insertvalue %Range undef, i64 %a.fca.0.extract, 0, 0
  %.fca.1.0.insert = insertvalue %Range %.fca.0.0.insert, i64 %3, 1, 0
  ret %Range %.fca.1.0.insert
}

; Function Attrs: nounwind readnone
define %Bool @Bool_t() #2 {
entry:
  ret %Bool zeroinitializer
}

; Function Attrs: nounwind
define void @print_tBool(%Bool %a) #3 {
entry:
  %0 = extractvalue %Bool %a, 0
  tail call void @vist-Uprint_tb(i1 %0)
  ret void
}

; Function Attrs: nounwind readnone
define %Double @-A_tDoubleDouble(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = fmul double %0, %1
  %.fca.0.insert = insertvalue %Double undef, double %2, 0
  ret %Double %.fca.0.insert
}

; Function Attrs: nounwind
define void @print_tString(%String %a) #3 {
entry:
  %0 = extractvalue %String %a, 0
  tail call void @vist-Uprint_top(i8* %0)
  ret void
}

; Function Attrs: nounwind
define void @print_tInt(%Int %a) #3 {
entry:
  %0 = extractvalue %Int %a, 0
  tail call void @vist-Uprint_ti64(i64 %0)
  ret void
}

; Function Attrs: nounwind
define %Int @-A_tIntInt(%Int %a, %Int %b) #3 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = tail call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %0, i64 %1)
  %3 = extractvalue { i64, i1 } %2, 1
  br i1 %3, label %"*.trap", label %entry.cont

entry.cont:                                       ; preds = %entry
  %4 = extractvalue { i64, i1 } %2, 0
  %.fca.0.insert = insertvalue %Int undef, i64 %4, 0
  ret %Int %.fca.0.insert

"*.trap":                                         ; preds = %entry
  tail call void @llvm.trap()
  unreachable
}

; Function Attrs: nounwind readnone
define %Bool @-G-E_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = icmp sge i64 %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Int @-L-L_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = shl i64 %0, %1
  %.fca.0.insert = insertvalue %Int undef, i64 %2, 0
  ret %Int %.fca.0.insert
}

; Function Attrs: nounwind
define %String @String_topi64(i8* nocapture readonly %ptr, i64 %count) #3 {
entry:
  %0 = trunc i64 %count to i32
  %1 = tail call i8* @malloc(i32 %0)
  tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %ptr, i64 %count, i32 1, i1 false)
  %.fca.0.insert = insertvalue %String undef, i8* %1, 0
  %.fca.1.insert = insertvalue %String %.fca.0.insert, i64 %count, 1
  ret %String %.fca.1.insert
}

; Function Attrs: nounwind
define void @assert_tBool(%Bool %"$0") #3 {
entry:
  %0 = extractvalue %Bool %"$0", 0
  br i1 %0, label %exit, label %else.1

else.1:                                           ; preds = %entry
  tail call void @llvm.trap()
  unreachable

exit:                                             ; preds = %entry
  ret void
}

; Function Attrs: nounwind readnone
define %Int @-T-R_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = xor i64 %1, %0
  %.fca.0.insert = insertvalue %Int undef, i64 %2, 0
  ret %Int %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Int @Int_tInt(%Int %val) #2 {
entry:
  ret %Int %val
}

; Function Attrs: nounwind readnone
define %Bool @-G_tDoubleDouble(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = fcmp ogt double %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Int32 @Int32_tInt32(%Int32 %val) #2 {
entry:
  ret %Int32 %val
}

; Function Attrs: nounwind
define void @print_tInt32(%Int32 %a) #3 {
entry:
  %0 = extractvalue %Int32 %a, 0
  tail call void @vist-Uprint_ti32(i32 %0)
  ret void
}

; Function Attrs: nounwind readnone
define %Int @Int_t() #2 {
entry:
  ret %Int zeroinitializer
}

; Function Attrs: nounwind readnone
define %Bool @-G_tIntInt(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = icmp sgt i64 %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Range @Range_tIntInt(%Int %"$0", %Int %"$1") #2 {
entry:
  %"$0.fca.0.extract" = extractvalue %Int %"$0", 0
  %"$1.fca.0.extract" = extractvalue %Int %"$1", 0
  %.fca.0.0.insert = insertvalue %Range undef, i64 %"$0.fca.0.extract", 0, 0
  %.fca.1.0.insert = insertvalue %Range %.fca.0.0.insert, i64 %"$1.fca.0.extract", 1, 0
  ret %Range %.fca.1.0.insert
}

; Function Attrs: nounwind readnone
define %Bool @"!-E_tIntInt"(%Int %a, %Int %b) #2 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = icmp ne i64 %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind
define %Int @-D_tIntInt(%Int %a, %Int %b) #3 {
entry:
  %0 = extractvalue %Int %b, 0
  %1 = icmp eq i64 %0, 0
  br i1 %1, label %else.1.i, label %assert_tBool.exit

else.1.i:                                         ; preds = %entry
  tail call void @llvm.trap() #3
  unreachable

assert_tBool.exit:                                ; preds = %entry
  %2 = extractvalue %Int %a, 0
  %3 = sdiv i64 %2, %0
  %.fca.0.insert = insertvalue %Int undef, i64 %3, 0
  ret %Int %.fca.0.insert
}

; Function Attrs: nounwind readnone
define %Bool @-G-E_tDoubleDouble(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = fcmp oge double %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: nounwind
define %Int @-P_tIntInt(%Int %a, %Int %b) #3 {
entry:
  %0 = extractvalue %Int %a, 0
  %1 = extractvalue %Int %b, 0
  %2 = tail call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %0, i64 %1)
  %3 = extractvalue { i64, i1 } %2, 1
  br i1 %3, label %"+.trap", label %entry.cont

entry.cont:                                       ; preds = %entry
  %4 = extractvalue { i64, i1 } %2, 0
  %.fca.0.insert = insertvalue %Int undef, i64 %4, 0
  ret %Int %.fca.0.insert

"+.trap":                                         ; preds = %entry
  tail call void @llvm.trap()
  unreachable
}

; Function Attrs: nounwind readnone
define %Bool @-L_tDoubleDouble(%Double %a, %Double %b) #2 {
entry:
  %0 = extractvalue %Double %a, 0
  %1 = extractvalue %Double %b, 0
  %2 = fcmp olt double %0, %1
  %.fca.0.insert = insertvalue %Bool undef, i1 %2, 0
  ret %Bool %.fca.0.insert
}

; Function Attrs: noreturn nounwind
declare void @llvm.trap() #4

; Function Attrs: nounwind readnone
declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64) #2

; Function Attrs: nounwind readnone
declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64) #2

; Function Attrs: nounwind
declare noalias i8* @malloc(i32) #3

; Function Attrs: nounwind
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture, i8* nocapture readonly, i64, i32, i1) #3

; Function Attrs: nounwind readnone
declare { i64, i1 } @llvm.sadd.with.overflow.i64(i64, i64) #2

; Function Attrs: nounwind
declare i32 @puts(i8* nocapture readonly) #3

; Function Attrs: nounwind readnone
define %Double @-M_tDoubleDouble(%Double, %Double) #2 {
  %3 = extractvalue %Double %0, 0
  %4 = extractvalue %Double %1, 0
  %5 = fadd double %3, %4
  %.fca.0.insert.i = insertvalue %Double undef, double %5, 0
  ret %Double %.fca.0.insert.i
}

; Function Attrs: nounwind readnone
define %Bool @-O-O_tBoolBool(%Bool, %Bool) #2 {
  %3 = extractvalue %Bool %0, 0
  %4 = extractvalue %Bool %1, 0
  %5 = and i1 %3, %4
  %.fca.0.insert.i = insertvalue %Bool undef, i1 %5, 0
  ret %Bool %.fca.0.insert.i
}

attributes #0 = { noinline nounwind ssp uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone }
attributes #3 = { nounwind }
attributes #4 = { noreturn nounwind }

!llvm.ident = !{!0}
!llvm.module.flags = !{!1}

!0 = !{!"clang version 3.6.2 (tags/RELEASE_362/final)"}
!1 = !{i32 1, !"PIC Level", i32 2}
