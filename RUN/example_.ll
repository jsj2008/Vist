; ModuleID = 'vist_module'
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.11.0"

@.str = private unnamed_addr constant [6 x i8] c"%lli\0A\00", align 1
@.str1 = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1
@.str2 = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1
@.str3 = private unnamed_addr constant [6 x i8] c"true\0A\00", align 1
@.str4 = private unnamed_addr constant [7 x i8] c"false\0A\00", align 1

; Function Attrs: noinline ssp uwtable
define void @"_$print_i64"(i64 %i) #0 {
  %1 = alloca i64, align 8
  store i64 %i, i64* %1, align 8
  %2 = load i64* %1, align 8
  %3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([6 x i8]* @.str, i32 0, i32 0), i64 %2)
  ret void
}

declare i32 @printf(i8*, ...) #1

; Function Attrs: noinline ssp uwtable
define void @"_$print_i32"(i32 %i) #0 {
  %1 = alloca i32, align 4
  store i32 %i, i32* %1, align 4
  %2 = load i32* %1, align 4
  %3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str1, i32 0, i32 0), i32 %2)
  ret void
}

; Function Attrs: noinline ssp uwtable
define void @"_$print_f64"(double %d) #0 {
  %1 = alloca double, align 8
  store double %d, double* %1, align 8
  %2 = load double* %1, align 8
  %3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str2, i32 0, i32 0), double %2)
  ret void
}

; Function Attrs: noinline ssp uwtable
define void @"_$print_f32"(float %d) #0 {
  %1 = alloca float, align 4
  store float %d, float* %1, align 4
  %2 = load float* %1, align 4
  %3 = fpext float %2 to double
  %4 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str2, i32 0, i32 0), double %3)
  ret void
}

; Function Attrs: noinline ssp uwtable
define void @"_$print_b"(i1 zeroext %b) #0 {
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
define { i64 } @_Int_S.i64({ i64 } %o) #2 {
entry:
  %0 = alloca { i64 }
  %value = extractvalue { i64 } %o, 0
  %value_ptr = getelementptr inbounds { i64 }* %0, i32 0, i32 0
  store i64 %value, i64* %value_ptr
  %1 = load { i64 }* %0
  ret { i64 } %1
}

; Function Attrs: alwaysinline
define { i64 } @_Int_i64(i64 %v) #2 {
entry:
  %0 = alloca { i64 }
  %value_ptr = getelementptr inbounds { i64 }* %0, i32 0, i32 0
  store i64 %v, i64* %value_ptr
  %1 = load { i64 }* %0
  ret { i64 } %1
}

; Function Attrs: alwaysinline
define { i64 } @_Int_() #2 {
entry:
  %0 = alloca { i64 }
  %1 = call { i64 } @_Int_i64(i64 0)
  %2 = alloca { i64 }
  store { i64 } %1, { i64 }* %2
  %value_ptr = getelementptr inbounds { i64 }* %2, i32 0, i32 0
  %value = load i64* %value_ptr
  %value_ptr1 = getelementptr inbounds { i64 }* %0, i32 0, i32 0
  store i64 %value, i64* %value_ptr1
  %3 = load { i64 }* %0
  ret { i64 } %3
}

; Function Attrs: alwaysinline
define { i1 } @_Bool_S.b({ i1 } %o) #2 {
entry:
  %0 = alloca { i1 }
  %value = extractvalue { i1 } %o, 0
  %value_ptr = getelementptr inbounds { i1 }* %0, i32 0, i32 0
  store i1 %value, i1* %value_ptr
  %1 = load { i1 }* %0
  ret { i1 } %1
}

; Function Attrs: alwaysinline
define { i1 } @_Bool_b(i1 %v) #2 {
entry:
  %0 = alloca { i1 }
  %value_ptr = getelementptr inbounds { i1 }* %0, i32 0, i32 0
  store i1 %v, i1* %value_ptr
  %1 = load { i1 }* %0
  ret { i1 } %1
}

; Function Attrs: alwaysinline
define { i1 } @_Bool_() #2 {
entry:
  %0 = alloca { i1 }
  %1 = call { i1 } @_Bool_b(i1 false)
  %2 = alloca { i1 }
  store { i1 } %1, { i1 }* %2
  %value_ptr = getelementptr inbounds { i1 }* %2, i32 0, i32 0
  %value = load i1* %value_ptr
  %value_ptr1 = getelementptr inbounds { i1 }* %0, i32 0, i32 0
  store i1 %value, i1* %value_ptr1
  %3 = load { i1 }* %0
  ret { i1 } %3
}

; Function Attrs: alwaysinline
define { double } @_Double_S.f64({ double } %o) #2 {
entry:
  %0 = alloca { double }
  %value = extractvalue { double } %o, 0
  %value_ptr = getelementptr inbounds { double }* %0, i32 0, i32 0
  store double %value, double* %value_ptr
  %1 = load { double }* %0
  ret { double } %1
}

; Function Attrs: alwaysinline
define { double } @_Double_f64(double %v) #2 {
entry:
  %0 = alloca { double }
  %value_ptr = getelementptr inbounds { double }* %0, i32 0, i32 0
  store double %v, double* %value_ptr
  %1 = load { double }* %0
  ret { double } %1
}

; Function Attrs: alwaysinline
define { { i64 }, { i64 } } @_Range_S.i64_S.i64({ i64 } %"$0", { i64 } %"$1") #2 {
entry:
  %0 = alloca { { i64 }, { i64 } }
  %start_ptr = getelementptr inbounds { { i64 }, { i64 } }* %0, i32 0, i32 0
  store { i64 } %"$0", { i64 }* %start_ptr
  %end_ptr = getelementptr inbounds { { i64 }, { i64 } }* %0, i32 0, i32 1
  store { i64 } %"$1", { i64 }* %end_ptr
  %1 = load { { i64 }, { i64 } }* %0
  ret { { i64 }, { i64 } } %1
}

; Function Attrs: alwaysinline
define void @_print_S.i64({ i64 } %a) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  call void @"_$print_i64"(i64 %value)
  ret void
}

; Function Attrs: alwaysinline
define void @_print_S.b({ i1 } %a) #2 {
entry:
  %value = extractvalue { i1 } %a, 0
  call void @"_$print_b"(i1 %value)
  ret void
}

; Function Attrs: alwaysinline
define void @_print_S.f64({ double } %a) #2 {
entry:
  %value = extractvalue { double } %a, 0
  call void @"_$print_f64"(double %value)
  ret void
}

; Function Attrs: alwaysinline noreturn
define void @_fatalError_() #3 {
entry:
  call void @llvm.trap()
  ret void
}

; Function Attrs: noreturn nounwind
declare void @llvm.trap() #4

; Function Attrs: alwaysinline
define void @_assert_S.b({ i1 } %"$0") #2 {
entry:
  %value = extractvalue { i1 } %"$0", 0
  br i1 %value, label %then0, label %cont0

cont:                                             ; preds = %else1, %then0
  ret void

cont0:                                            ; preds = %entry
  br label %else1

then0:                                            ; preds = %entry
  br label %cont

else1:                                            ; preds = %cont0
  call void @llvm.trap()
  br label %cont
}

; Function Attrs: alwaysinline
define void @_condFail_b(i1 %"$0") #2 {
entry:
  %Bool_res = call { i1 } @_Bool_b(i1 %"$0")
  %value = extractvalue { i1 } %Bool_res, 0
  br i1 %value, label %then0, label %cont

cont:                                             ; preds = %then0, %entry
  ret void

then0:                                            ; preds = %entry
  call void @llvm.trap()
  br label %cont
}

; Function Attrs: alwaysinline
define { i64 } @"_+_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %add_res = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %value, i64 %value1)
  %0 = alloca { i64, i1 }
  store { i64, i1 } %add_res, { i64, i1 }* %0
  %"1_ptr" = getelementptr inbounds { i64, i1 }* %0, i32 0, i32 1
  %"1" = load i1* %"1_ptr"
  call void @_condFail_b(i1 %"1")
  %"0_ptr" = getelementptr inbounds { i64, i1 }* %0, i32 0, i32 0
  %"0" = load i64* %"0_ptr"
  %Int_res = call { i64 } @_Int_i64(i64 %"0")
  ret { i64 } %Int_res
}

; Function Attrs: nounwind readnone
declare { i64, i1 } @llvm.sadd.with.overflow.i64(i64, i64) #5

; Function Attrs: alwaysinline
define { i64 } @_-_S.i64_S.i64({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %sub_res = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %value, i64 %value1)
  %0 = alloca { i64, i1 }
  store { i64, i1 } %sub_res, { i64, i1 }* %0
  %"1_ptr" = getelementptr inbounds { i64, i1 }* %0, i32 0, i32 1
  %"1" = load i1* %"1_ptr"
  call void @_condFail_b(i1 %"1")
  %"0_ptr" = getelementptr inbounds { i64, i1 }* %0, i32 0, i32 0
  %"0" = load i64* %"0_ptr"
  %Int_res = call { i64 } @_Int_i64(i64 %"0")
  ret { i64 } %Int_res
}

; Function Attrs: nounwind readnone
declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64) #5

; Function Attrs: alwaysinline
define { i64 } @"_*_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %mul_res = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %value, i64 %value1)
  %0 = alloca { i64, i1 }
  store { i64, i1 } %mul_res, { i64, i1 }* %0
  %"1_ptr" = getelementptr inbounds { i64, i1 }* %0, i32 0, i32 1
  %"1" = load i1* %"1_ptr"
  call void @_condFail_b(i1 %"1")
  %"0_ptr" = getelementptr inbounds { i64, i1 }* %0, i32 0, i32 0
  %"0" = load i64* %"0_ptr"
  %Int_res = call { i64 } @_Int_i64(i64 %"0")
  ret { i64 } %Int_res
}

; Function Attrs: nounwind readnone
declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64) #5

; Function Attrs: alwaysinline
define { i64 } @"_/_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %div_res = udiv i64 %value, %value1
  %Int_res = call { i64 } @_Int_i64(i64 %div_res)
  ret { i64 } %Int_res
}

; Function Attrs: alwaysinline
define { i64 } @"_%_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %rem_res = urem i64 %value, %value1
  %Int_res = call { i64 } @_Int_i64(i64 %rem_res)
  ret { i64 } %Int_res
}

; Function Attrs: alwaysinline
define { i1 } @"_<_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %cmp_lt_res = icmp slt i64 %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_lt_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_<=_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %cmp_lte_res = icmp sle i64 %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_lte_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_>_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %cmp_gt_res = icmp sgt i64 %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_gt_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_>=_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %cmp_gte_res = icmp sge i64 %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_gte_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_==_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %cmp_eq_res = icmp eq i64 %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_eq_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_!=_S.i64_S.i64"({ i64 } %a, { i64 } %b) #2 {
entry:
  %value = extractvalue { i64 } %a, 0
  %value1 = extractvalue { i64 } %b, 0
  %cmp_neq_res = icmp ne i64 %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_neq_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_&&_S.b_S.b"({ i1 } %a, { i1 } %b) #2 {
entry:
  %value = extractvalue { i1 } %a, 0
  %value1 = extractvalue { i1 } %b, 0
  %cmp_and_res = and i1 %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_and_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_||_S.b_S.b"({ i1 } %a, { i1 } %b) #2 {
entry:
  %value = extractvalue { i1 } %a, 0
  %value1 = extractvalue { i1 } %b, 0
  %cmp_or_res = or i1 %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_or_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { double } @"_+_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %add_res = fadd double %value, %value1
  %Double_res = call { double } @_Double_f64(double %add_res)
  ret { double } %Double_res
}

; Function Attrs: alwaysinline
define { double } @_-_S.f64_S.f64({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %sub_res = fsub double %value, %value1
  %Double_res = call { double } @_Double_f64(double %sub_res)
  ret { double } %Double_res
}

; Function Attrs: alwaysinline
define { double } @"_*_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %mul_res = fmul double %value, %value1
  %Double_res = call { double } @_Double_f64(double %mul_res)
  ret { double } %Double_res
}

; Function Attrs: alwaysinline
define { double } @"_/_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %div_res = fdiv double %value, %value1
  %Double_res = call { double } @_Double_f64(double %div_res)
  ret { double } %Double_res
}

; Function Attrs: alwaysinline
define { double } @"_%_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %rem_res = frem double %value, %value1
  %Double_res = call { double } @_Double_f64(double %rem_res)
  ret { double } %Double_res
}

; Function Attrs: alwaysinline
define { i1 } @"_<_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %cmp_lt_res = fcmp olt double %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_lt_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_<=_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %cmp_lte_res = fcmp ole double %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_lte_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_>_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %cmp_gt_res = fcmp ogt double %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_gt_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_>=_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %cmp_gte_res = fcmp oge double %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_gte_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_==_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %cmp_eq_res = fcmp oeq double %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_eq_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { i1 } @"_!=_S.f64_S.f64"({ double } %a, { double } %b) #2 {
entry:
  %value = extractvalue { double } %a, 0
  %value1 = extractvalue { double } %b, 0
  %cmp_neq_res = fcmp one double %value, %value1
  %Bool_res = call { i1 } @_Bool_b(i1 %cmp_neq_res)
  ret { i1 } %Bool_res
}

; Function Attrs: alwaysinline
define { { i64 }, { i64 } } @_..._S.i64_S.i64({ i64 } %"$0", { i64 } %"$1") #2 {
entry:
  %Range_res = call { { i64 }, { i64 } } @_Range_S.i64_S.i64({ i64 } %"$0", { i64 } %"$1")
  ret { { i64 }, { i64 } } %Range_res
}

; Function Attrs: alwaysinline
define { { i64 }, { i64 } } @"_..<_S.i64_S.i64"({ i64 } %"$0", { i64 } %"$1") #2 {
entry:
  %0 = call { i64 } @_Int_i64(i64 1)
  %-_res = call { i64 } @_-_S.i64_S.i64({ i64 } %"$1", { i64 } %0)
  %Range_res = call { { i64 }, { i64 } } @_Range_S.i64_S.i64({ i64 } %"$0", { i64 } %-_res)
  ret { { i64 }, { i64 } } %Range_res
}

define i64 @main() {
entry:
  %0 = call { i64 } @_Int_i64(i64 1)
  %1 = alloca { i64 }
  store { i64 } %0, { i64 }* %1
  %2 = call { i64 } @_Int_i64(i64 2)
  %3 = alloca { i64 }
  store { i64 } %2, { i64 }* %3
  %4 = call { i64 } @_Int_i64(i64 1)
  %a = load { i64 }* %1
  %add_res = call { i64 } @_add_S.i64_S.i64({ i64 } %4, { i64 } %a)
  %b = load { i64 }* %3
  %add_res1 = call { i64 } @_add_S.i64_S.i64({ i64 } %add_res, { i64 } %b)
  %5 = alloca { i64 }
  store { i64 } %add_res1, { i64 }* %5
  %u = load { i64 }* %5
  call void @_print_S.i64({ i64 } %u)
  ret i64 0
}

define { i64 } @_add_S.i64_S.i64({ i64 } %"$0", { i64 } %"$1") {
entry:
  %"+_res" = call { i64 } @"_+_S.i64_S.i64"({ i64 } %"$0", { i64 } %"$1")
  ret { i64 } %"+_res"
}

attributes #0 = { noinline ssp uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+ssse3,+cx16,+sse,+sse2,+sse3" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+ssse3,+cx16,+sse,+sse2,+sse3" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { alwaysinline }
attributes #3 = { alwaysinline noreturn }
attributes #4 = { noreturn nounwind }
attributes #5 = { nounwind readnone }

!llvm.ident = !{!0}
!llvm.module.flags = !{!1}

!0 = !{!"Apple LLVM version 7.0.2 (clang-700.1.81)"}
!1 = !{i32 1, !"PIC Level", i32 2}
