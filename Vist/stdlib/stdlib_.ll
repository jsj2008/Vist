; ModuleID = 'vist_module'
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.11.0"

%Int.st = type { i64 }
%Int32.st = type { i32 }
%Bool.st = type { i1 }
%Double.st = type { double }
%Range.st = type { %Int.st, %Int.st }

@.str = private unnamed_addr constant [6 x i8] c"%lli\0A\00", align 1
@.str1 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
@.str2 = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1
@.str3 = private unnamed_addr constant [6 x i8] c"true\0A\00", align 1
@.str4 = private unnamed_addr constant [7 x i8] c"false\0A\00", align 1

; Function Attrs: noinline ssp uwtable
define void @-Uprint_i64(i64 %i) #0 {
  %1 = alloca i64, align 8
  store i64 %i, i64* %1, align 8
  %2 = load i64* %1, align 8
  %3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([6 x i8]* @.str, i32 0, i32 0), i64 %2)
  ret void
}

declare i32 @printf(i8*, ...) #1

; Function Attrs: noinline ssp uwtable
define void @-Uprint_i32(i32 %i) #0 {
  %1 = alloca i32, align 4
  store i32 %i, i32* %1, align 4
  %2 = load i32* %1, align 4
  %3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str1, i32 0, i32 0), i32 %2)
  ret void
}

; Function Attrs: noinline ssp uwtable
define void @-Uprint_f64(double %d) #0 {
  %1 = alloca double, align 8
  store double %d, double* %1, align 8
  %2 = load double* %1, align 8
  %3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str2, i32 0, i32 0), double %2)
  ret void
}

; Function Attrs: noinline ssp uwtable
define void @-Uprint_f32(float %d) #0 {
  %1 = alloca float, align 4
  store float %d, float* %1, align 4
  %2 = load float* %1, align 4
  %3 = fpext float %2 to double
  %4 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str2, i32 0, i32 0), double %3)
  ret void
}

; Function Attrs: noinline ssp uwtable
define void @-Uprint_b(i1 zeroext %b) #0 {
  %1 = alloca i8, align 1
  %2 = zext i1 %b to i8
  store i8 %2, i8* %1, align 1
  %3 = load i8* %1, align 1
  %4 = trunc i8 %3 to i1
  br i1 %4, label %5, label %7

; <label>:5                                       ; preds = %0
  %6 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([6 x i8]* @.str3, i32 0, i32 0))
  br label %9

; <label>:7                                       ; preds = %0
  %8 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([7 x i8]* @.str4, i32 0, i32 0))
  br label %9

; <label>:9                                       ; preds = %7, %5
  ret void
}

; Function Attrs: alwaysinline
define %Int.st @Int_i64(i64 %v) #2 {
entry:
  %Int = alloca %Int.st
  %Int.value.ptr = getelementptr inbounds %Int.st* %Int, i32 0, i32 0
  store i64 %v, i64* %Int.value.ptr
  %Int1 = load %Int.st* %Int
  ret %Int.st %Int1
}

; Function Attrs: alwaysinline
define %Int.st @Int_() #2 {
entry:
  %Int = alloca %Int.st
  %0 = call %Int.st @Int_i64(i64 0), !stdlib.call.optim !2
  %v = alloca %Int.st
  store %Int.st %0, %Int.st* %v
  %v.value.ptr = getelementptr inbounds %Int.st* %v, i32 0, i32 0
  %1 = load i64* %v.value.ptr
  %Int.value.ptr = getelementptr inbounds %Int.st* %Int, i32 0, i32 0
  store i64 %1, i64* %Int.value.ptr
  %Int1 = load %Int.st* %Int
  ret %Int.st %Int1
}

; Function Attrs: alwaysinline
define %Int.st @Int_i641(i64 %"$0") #2 {
entry:
  %Int = alloca %Int.st
  %Int.value.ptr = getelementptr inbounds %Int.st* %Int, i32 0, i32 0
  store i64 %"$0", i64* %Int.value.ptr
  %Int1 = load %Int.st* %Int
  ret %Int.st %Int1
}

; Function Attrs: alwaysinline
define %Int32.st @Int32_i32(i32 %v) #2 {
entry:
  %Int32 = alloca %Int32.st
  %Int32.value.ptr = getelementptr inbounds %Int32.st* %Int32, i32 0, i32 0
  store i32 %v, i32* %Int32.value.ptr
  %Int321 = load %Int32.st* %Int32
  ret %Int32.st %Int321
}

; Function Attrs: alwaysinline
define %Int32.st @Int32_i322(i32 %"$0") #2 {
entry:
  %Int32 = alloca %Int32.st
  %Int32.value.ptr = getelementptr inbounds %Int32.st* %Int32, i32 0, i32 0
  store i32 %"$0", i32* %Int32.value.ptr
  %Int321 = load %Int32.st* %Int32
  ret %Int32.st %Int321
}

; Function Attrs: alwaysinline
define %Bool.st @Bool_b(i1 %v) #2 {
entry:
  %Bool = alloca %Bool.st
  %Bool.value.ptr = getelementptr inbounds %Bool.st* %Bool, i32 0, i32 0
  store i1 %v, i1* %Bool.value.ptr
  %Bool1 = load %Bool.st* %Bool
  ret %Bool.st %Bool1
}

; Function Attrs: alwaysinline
define %Bool.st @Bool_() #2 {
entry:
  %Bool = alloca %Bool.st
  %0 = call %Bool.st @Bool_b(i1 false), !stdlib.call.optim !2
  %b = alloca %Bool.st
  store %Bool.st %0, %Bool.st* %b
  %b.value.ptr = getelementptr inbounds %Bool.st* %b, i32 0, i32 0
  %1 = load i1* %b.value.ptr
  %Bool.value.ptr = getelementptr inbounds %Bool.st* %Bool, i32 0, i32 0
  store i1 %1, i1* %Bool.value.ptr
  %Bool1 = load %Bool.st* %Bool
  ret %Bool.st %Bool1
}

; Function Attrs: alwaysinline
define %Bool.st @Bool_b3(i1 %"$0") #2 {
entry:
  %Bool = alloca %Bool.st
  %Bool.value.ptr = getelementptr inbounds %Bool.st* %Bool, i32 0, i32 0
  store i1 %"$0", i1* %Bool.value.ptr
  %Bool1 = load %Bool.st* %Bool
  ret %Bool.st %Bool1
}

; Function Attrs: alwaysinline
define %Double.st @Double_f64(double %v) #2 {
entry:
  %Double = alloca %Double.st
  %Double.value.ptr = getelementptr inbounds %Double.st* %Double, i32 0, i32 0
  store double %v, double* %Double.value.ptr
  %Double1 = load %Double.st* %Double
  ret %Double.st %Double1
}

; Function Attrs: alwaysinline
define %Double.st @Double_f644(double %"$0") #2 {
entry:
  %Double = alloca %Double.st
  %Double.value.ptr = getelementptr inbounds %Double.st* %Double, i32 0, i32 0
  store double %"$0", double* %Double.value.ptr
  %Double1 = load %Double.st* %Double
  ret %Double.st %Double1
}

; Function Attrs: alwaysinline
define %Range.st @Range_Int_Int(%Int.st %"$0", %Int.st %"$1") #2 {
entry:
  %Range = alloca %Range.st
  %Range.start.ptr = getelementptr inbounds %Range.st* %Range, i32 0, i32 0
  store %Int.st %"$0", %Int.st* %Range.start.ptr
  %Range.end.ptr = getelementptr inbounds %Range.st* %Range, i32 0, i32 1
  store %Int.st %"$1", %Int.st* %Range.end.ptr
  %Range1 = load %Range.st* %Range
  ret %Range.st %Range1
}

; Function Attrs: alwaysinline
define %Range.st @Range_Int_Int5(%Int.st %"$0", %Int.st %"$1") #2 {
entry:
  %Range = alloca %Range.st
  %Range.start.ptr = getelementptr inbounds %Range.st* %Range, i32 0, i32 0
  store %Int.st %"$0", %Int.st* %Range.start.ptr
  %Range.end.ptr = getelementptr inbounds %Range.st* %Range, i32 0, i32 1
  store %Int.st %"$1", %Int.st* %Range.end.ptr
  %Range1 = load %Range.st* %Range
  ret %Range.st %Range1
}

; Function Attrs: alwaysinline
define void @print_Int(%Int.st %a) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  call void @-Uprint_i64(i64 %0)
  ret void
}

; Function Attrs: alwaysinline
define void @print_Int32(%Int32.st %a) #2 {
entry:
  %a.value = extractvalue %Int32.st %a, 0
  %a.value1 = alloca i32
  store i32 %a.value, i32* %a.value1
  %0 = load i32* %a.value1
  call void @-Uprint_i32(i32 %0)
  ret void
}

; Function Attrs: alwaysinline
define void @print_Bool(%Bool.st %a) #2 {
entry:
  %a.value = extractvalue %Bool.st %a, 0
  %a.value1 = alloca i1
  store i1 %a.value, i1* %a.value1
  %0 = load i1* %a.value1
  call void @-Uprint_b(i1 %0)
  ret void
}

; Function Attrs: alwaysinline
define void @print_Double(%Double.st %a) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  call void @-Uprint_f64(double %0)
  ret void
}

; Function Attrs: alwaysinline
define %Bool.st @-Uexpect_Bool_Bool(%Bool.st %val, %Bool.st %assume) #2 {
entry:
  %val.value = extractvalue %Bool.st %val, 0
  %val.value1 = alloca i1
  store i1 %val.value, i1* %val.value1
  %0 = load i1* %val.value1
  %assume.value = extractvalue %Bool.st %assume, 0
  %assume.value2 = alloca i1
  store i1 %assume.value, i1* %assume.value2
  %1 = load i1* %assume.value2
  %2 = call i1 @llvm.expect.i1(i1 %0, i1 %1)
  %Bool_res = call %Bool.st @Bool_b(i1 %2)
  ret %Bool.st %Bool_res
}

; Function Attrs: nounwind readnone
declare i1 @llvm.expect.i1(i1, i1) #3

; Function Attrs: alwaysinline noreturn
define void @fatalError_() #4 {
entry:
  call void @llvm.trap()
  ret void
}

; Function Attrs: noreturn nounwind
declare void @llvm.trap() #5

; Function Attrs: alwaysinline
define void @assert_Bool(%Bool.st %"$0") #2 {
entry:
  %0 = call %Bool.st @Bool_b(i1 true), !stdlib.call.optim !2
  %_expect_res = call %Bool.st @-Uexpect_Bool_Bool(%Bool.st %"$0", %Bool.st %0)
  %1 = extractvalue %Bool.st %_expect_res, 0
  br i1 %1, label %then.0, label %cont.0

cont.stmt:                                        ; preds = %else.1, %then.0
  ret void

cont.0:                                           ; preds = %entry
  br label %else.1

then.0:                                           ; preds = %entry
  br label %cont.stmt

else.1:                                           ; preds = %cont.0
  call void @llvm.trap()
  br label %cont.stmt
}

; Function Attrs: alwaysinline
define void @condFail_b(i1 %cond) #2 {
entry:
  %Bool_res = call %Bool.st @Bool_b(i1 %cond)
  %0 = call %Bool.st @Bool_b(i1 false), !stdlib.call.optim !2
  %_expect_res = call %Bool.st @-Uexpect_Bool_Bool(%Bool.st %Bool_res, %Bool.st %0)
  %1 = extractvalue %Bool.st %_expect_res, 0
  br i1 %1, label %then.0, label %cont.stmt

cont.stmt:                                        ; preds = %entry, %then.0
  ret void

then.0:                                           ; preds = %entry
  call void @llvm.trap()
  br label %cont.stmt
}

; Function Attrs: alwaysinline
define %Int.st @-P_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %add_res = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %0, i64 %1)
  %v = alloca { i64, i1 }
  store { i64, i1 } %add_res, { i64, i1 }* %v
  %v.1.ptr = getelementptr inbounds { i64, i1 }* %v, i32 0, i32 1
  %2 = load i1* %v.1.ptr
  call void @condFail_b(i1 %2)
  %v.0.ptr = getelementptr inbounds { i64, i1 }* %v, i32 0, i32 0
  %3 = load i64* %v.0.ptr
  %Int_res = call %Int.st @Int_i64(i64 %3)
  ret %Int.st %Int_res
}

; Function Attrs: nounwind readnone
declare { i64, i1 } @llvm.sadd.with.overflow.i64(i64, i64) #3

; Function Attrs: alwaysinline
define %Int.st @-M_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %sub_res = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %0, i64 %1)
  %v = alloca { i64, i1 }
  store { i64, i1 } %sub_res, { i64, i1 }* %v
  %v.1.ptr = getelementptr inbounds { i64, i1 }* %v, i32 0, i32 1
  %2 = load i1* %v.1.ptr
  call void @condFail_b(i1 %2)
  %v.0.ptr = getelementptr inbounds { i64, i1 }* %v, i32 0, i32 0
  %3 = load i64* %v.0.ptr
  %Int_res = call %Int.st @Int_i64(i64 %3)
  ret %Int.st %Int_res
}

; Function Attrs: nounwind readnone
declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64) #3

; Function Attrs: alwaysinline
define %Int.st @-A_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %mul_res = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %0, i64 %1)
  %v = alloca { i64, i1 }
  store { i64, i1 } %mul_res, { i64, i1 }* %v
  %v.1.ptr = getelementptr inbounds { i64, i1 }* %v, i32 0, i32 1
  %2 = load i1* %v.1.ptr
  call void @condFail_b(i1 %2)
  %v.0.ptr = getelementptr inbounds { i64, i1 }* %v, i32 0, i32 0
  %3 = load i64* %v.0.ptr
  %Int_res = call %Int.st @Int_i64(i64 %3)
  ret %Int.st %Int_res
}

; Function Attrs: nounwind readnone
declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64) #3

; Function Attrs: alwaysinline
define %Bool.st @-E-E_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %cmp_eq_res = icmp eq i64 %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_eq_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @"!-E_Int_Int"(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %cmp_neq_res = icmp ne i64 %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_neq_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Int.st @-D_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %0 = call %Int.st @Int_i64(i64 0), !stdlib.call.optim !2
  %"!=.res" = call %Bool.st @"!-E_Int_Int"(%Int.st %b, %Int.st %0)
  call void @assert_Bool(%Bool.st %"!=.res")
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %1 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %2 = load i64* %b.value2
  %div_res = udiv i64 %1, %2
  %Int_res = call %Int.st @Int_i64(i64 %div_res)
  ret %Int.st %Int_res
}

; Function Attrs: alwaysinline
define %Int.st @"%_Int_Int"(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %rem_res = urem i64 %0, %1
  %Int_res = call %Int.st @Int_i64(i64 %rem_res)
  ret %Int.st %Int_res
}

; Function Attrs: alwaysinline
define %Bool.st @-L_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %cmp_lt_res = icmp slt i64 %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_lt_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @-L-E_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %cmp_lte_res = icmp sle i64 %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_lte_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @-G-E_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %cmp_gte_res = icmp sge i64 %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_gte_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @-G_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %cmp_gt_res = icmp sgt i64 %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_gt_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Int.st @-L-L_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %shl_res = shl i64 %0, %1
  %Int_res = call %Int.st @Int_i64(i64 %shl_res)
  ret %Int.st %Int_res
}

; Function Attrs: alwaysinline
define %Int.st @-G-G_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %shr_res = ashr i64 %0, %1
  %Int_res = call %Int.st @Int_i64(i64 %shr_res)
  ret %Int.st %Int_res
}

; Function Attrs: alwaysinline
define %Int.st @-T-N_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %and_res = and i64 %0, %1
  %Int_res = call %Int.st @Int_i64(i64 %and_res)
  ret %Int.st %Int_res
}

; Function Attrs: alwaysinline
define %Int.st @-T-O_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %or_res = or i64 %0, %1
  %Int_res = call %Int.st @Int_i64(i64 %or_res)
  ret %Int.st %Int_res
}

; Function Attrs: alwaysinline
define %Int.st @-T-R_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %a.value = extractvalue %Int.st %a, 0
  %a.value1 = alloca i64
  store i64 %a.value, i64* %a.value1
  %0 = load i64* %a.value1
  %b.value = extractvalue %Int.st %b, 0
  %b.value2 = alloca i64
  store i64 %b.value, i64* %b.value2
  %1 = load i64* %b.value2
  %xor_res = xor i64 %0, %1
  %Int_res = call %Int.st @Int_i64(i64 %xor_res)
  ret %Int.st %Int_res
}

; Function Attrs: alwaysinline
define %Bool.st @-N-N_Bool_Bool(%Bool.st %a, %Bool.st %b) #2 {
entry:
  %a.value = extractvalue %Bool.st %a, 0
  %a.value1 = alloca i1
  store i1 %a.value, i1* %a.value1
  %0 = load i1* %a.value1
  %b.value = extractvalue %Bool.st %b, 0
  %b.value2 = alloca i1
  store i1 %b.value, i1* %b.value2
  %1 = load i1* %b.value2
  %cmp_and_res = and i1 %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_and_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @-O-O_Bool_Bool(%Bool.st %a, %Bool.st %b) #2 {
entry:
  %a.value = extractvalue %Bool.st %a, 0
  %a.value1 = alloca i1
  store i1 %a.value, i1* %a.value1
  %0 = load i1* %a.value1
  %b.value = extractvalue %Bool.st %b, 0
  %b.value2 = alloca i1
  store i1 %b.value, i1* %b.value2
  %1 = load i1* %b.value2
  %cmp_or_res = or i1 %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_or_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Double.st @-P_Double_Double(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %add_res = fadd double %0, %1
  %Double_res = call %Double.st @Double_f64(double %add_res)
  ret %Double.st %Double_res
}

; Function Attrs: alwaysinline
define %Double.st @-M_Double_Double(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %sub_res = fsub double %0, %1
  %Double_res = call %Double.st @Double_f64(double %sub_res)
  ret %Double.st %Double_res
}

; Function Attrs: alwaysinline
define %Double.st @-A_Double_Double(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %mul_res = fmul double %0, %1
  %Double_res = call %Double.st @Double_f64(double %mul_res)
  ret %Double.st %Double_res
}

; Function Attrs: alwaysinline
define %Double.st @-D_Double_Double(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %div_res = fdiv double %0, %1
  %Double_res = call %Double.st @Double_f64(double %div_res)
  ret %Double.st %Double_res
}

; Function Attrs: alwaysinline
define %Double.st @"%_Double_Double"(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %rem_res = frem double %0, %1
  %Double_res = call %Double.st @Double_f64(double %rem_res)
  ret %Double.st %Double_res
}

; Function Attrs: alwaysinline
define %Bool.st @-L_Double_Double(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %cmp_lt_res = fcmp olt double %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_lt_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @-L-E_Double_Double(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %cmp_lte_res = fcmp ole double %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_lte_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @-G_Double_Double(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %cmp_gt_res = fcmp ogt double %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_gt_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @-G-E_Double_Double(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %cmp_gte_res = fcmp oge double %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_gte_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @-E-E_Double_Double(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %cmp_eq_res = fcmp oeq double %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_eq_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Bool.st @"!-E_Double_Double"(%Double.st %a, %Double.st %b) #2 {
entry:
  %a.value = extractvalue %Double.st %a, 0
  %a.value1 = alloca double
  store double %a.value, double* %a.value1
  %0 = load double* %a.value1
  %b.value = extractvalue %Double.st %b, 0
  %b.value2 = alloca double
  store double %b.value, double* %b.value2
  %1 = load double* %b.value2
  %cmp_neq_res = fcmp one double %0, %1
  %Bool_res = call %Bool.st @Bool_b(i1 %cmp_neq_res)
  ret %Bool.st %Bool_res
}

; Function Attrs: alwaysinline
define %Range.st @..._Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %Range_res = call %Range.st @Range_Int_Int(%Int.st %a, %Int.st %b)
  ret %Range.st %Range_res
}

; Function Attrs: alwaysinline
define %Range.st @..-L_Int_Int(%Int.st %a, %Int.st %b) #2 {
entry:
  %0 = call %Int.st @Int_i64(i64 1), !stdlib.call.optim !2
  %-.res = call %Int.st @-M_Int_Int(%Int.st %b, %Int.st %0)
  %Range_res = call %Range.st @Range_Int_Int(%Int.st %a, %Int.st %-.res)
  ret %Range.st %Range_res
}

attributes #0 = { noinline ssp uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+ssse3,+cx16,+sse,+sse2,+sse3" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+ssse3,+cx16,+sse,+sse2,+sse3" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { alwaysinline }
attributes #3 = { nounwind readnone }
attributes #4 = { alwaysinline noreturn }
attributes #5 = { noreturn nounwind }

!llvm.ident = !{!0}
!llvm.module.flags = !{!1}

!0 = !{!"Apple LLVM version 7.0.2 (clang-700.1.81)"}
!1 = !{i32 1, !"PIC Level", i32 2}
!2 = !{!"stdlib.call.optim"}
