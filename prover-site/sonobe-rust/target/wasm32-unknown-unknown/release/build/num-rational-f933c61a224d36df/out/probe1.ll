; ModuleID = 'probe1.b316f6013465d776-cgu.0'
source_filename = "probe1.b316f6013465d776-cgu.0"
target datalayout = "e-m:e-p:32:32-p10:8:8-p20:8:8-i64:64-n32:64-S128-ni:1:10:20"
target triple = "wasm32-unknown-unknown"

%"core::fmt::rt::Argument<'_>" = type { %"core::fmt::rt::ArgumentType<'_>" }
%"core::fmt::rt::ArgumentType<'_>" = type { [1 x i32], ptr }

@alloc_8df0580a595a87d56789d20c7318e185 = private unnamed_addr constant <{ [166 x i8] }> <{ [166 x i8] c"unsafe precondition(s) violated: ptr::copy_nonoverlapping requires that both pointer arguments are aligned and non-null and the specified memory ranges do not overlap" }>, align 1
@0 = private unnamed_addr constant <{ [4 x i8], [4 x i8] }> <{ [4 x i8] zeroinitializer, [4 x i8] undef }>, align 4
@alloc_91c7fa63c3cfeaa3c795652d5cf060e4 = private unnamed_addr constant <{ [12 x i8] }> <{ [12 x i8] c"invalid args" }>, align 1
@alloc_961fd82c18500a61bf8f6d7be21ce6b0 = private unnamed_addr constant <{ ptr, [4 x i8] }> <{ ptr @alloc_91c7fa63c3cfeaa3c795652d5cf060e4, [4 x i8] c"\0C\00\00\00" }>, align 4
@alloc_f93ec54d5f8967ace27e16fb5cbd0974 = private unnamed_addr constant <{ [75 x i8] }> <{ [75 x i8] c"/rustc/129f3b9964af4d4a709d1383930ade12dfe7c081/library/core/src/fmt/mod.rs" }>, align 1
@alloc_c996d719b03b70d75fd3f485b4b6e56f = private unnamed_addr constant <{ ptr, [12 x i8] }> <{ ptr @alloc_f93ec54d5f8967ace27e16fb5cbd0974, [12 x i8] c"K\00\00\00U\01\00\00\0D\00\00\00" }>, align 4
@alloc_d4d2a2a8539eafc62756407d946babb3 = private unnamed_addr constant <{ [110 x i8] }> <{ [110 x i8] c"unsafe precondition(s) violated: ptr::read_volatile requires that the pointer argument is aligned and non-null" }>, align 1
@alloc_20b3d155afd5c58c42e598b7e6d186ef = private unnamed_addr constant <{ [93 x i8] }> <{ [93 x i8] c"unsafe precondition(s) violated: NonNull::new_unchecked requires that the pointer is non-null" }>, align 1
@alloc_773eb6089c5345b558b6e9b46acd32c7 = private unnamed_addr constant <{ [80 x i8] }> <{ [80 x i8] c"/rustc/129f3b9964af4d4a709d1383930ade12dfe7c081/library/core/src/alloc/layout.rs" }>, align 1
@alloc_1badb795fc013c5a391ae9dae4e3a137 = private unnamed_addr constant <{ ptr, [12 x i8] }> <{ ptr @alloc_773eb6089c5345b558b6e9b46acd32c7, [12 x i8] c"P\00\00\00\C3\01\00\00)\00\00\00" }>, align 4
@alloc_763310d78c99c2c1ad3f8a9821e942f3 = private unnamed_addr constant <{ [61 x i8] }> <{ [61 x i8] c"is_nonoverlapping: `size_of::<T>() * count` overflows a usize" }>, align 1
@alloc_fad0cd83b7d1858a846a172eb260e593 = private unnamed_addr constant <{ [42 x i8] }> <{ [42 x i8] c"is_aligned_to: align is not a power-of-two" }>, align 1
@alloc_b498cf0a06cafe1ad822ab5dde97c8c0 = private unnamed_addr constant <{ ptr, [4 x i8] }> <{ ptr @alloc_fad0cd83b7d1858a846a172eb260e593, [4 x i8] c"*\00\00\00" }>, align 4
@alloc_ceda132f29d7566153090be3080ad0f8 = private unnamed_addr constant <{ [81 x i8] }> <{ [81 x i8] c"/rustc/129f3b9964af4d4a709d1383930ade12dfe7c081/library/core/src/ptr/const_ptr.rs" }>, align 1
@alloc_2f85c3373aac8b285ea093821a4ea7c0 = private unnamed_addr constant <{ ptr, [12 x i8] }> <{ ptr @alloc_ceda132f29d7566153090be3080ad0f8, [12 x i8] c"Q\00\00\00R\06\00\00\0D\00\00\00" }>, align 4
@__rust_no_alloc_shim_is_unstable = external dso_local global i8
@alloc_68ac15728a1e6ba4743b718936db7fdf = private unnamed_addr constant <{ ptr, [4 x i8] }> <{ ptr inttoptr (i32 1 to ptr), [4 x i8] zeroinitializer }>, align 4
@alloc_83ea17bf0c4f4a5a5a13d3ae7955acd0 = private unnamed_addr constant <{ [4 x i8] }> zeroinitializer, align 4

; core::intrinsics::copy_nonoverlapping::precondition_check
; Function Attrs: inlinehint nounwind
define internal void @_ZN4core10intrinsics19copy_nonoverlapping18precondition_check17h8d7e88ff352b7e3cE(ptr %src, ptr %dst, i32 %size, i32 %align, i32 %count) unnamed_addr #0 {
start:
; call core::ub_checks::is_aligned_and_not_null
  %_6 = call zeroext i1 @_ZN4core9ub_checks23is_aligned_and_not_null17hef179d5138129189E(ptr %src, i32 %align) #10
  br i1 %_6, label %bb2, label %bb7

bb7:                                              ; preds = %bb6, %bb2, %start
; call core::panicking::panic_nounwind
  call void @_ZN4core9panicking14panic_nounwind17h16e38f5a9ff4ae2cE(ptr align 1 @alloc_8df0580a595a87d56789d20c7318e185, i32 166) #11
  unreachable

bb2:                                              ; preds = %start
; call core::ub_checks::is_aligned_and_not_null
  %_7 = call zeroext i1 @_ZN4core9ub_checks23is_aligned_and_not_null17hef179d5138129189E(ptr %dst, i32 %align) #10
  br i1 %_7, label %bb4, label %bb7

bb4:                                              ; preds = %bb2
; call core::ub_checks::is_nonoverlapping::runtime
  %_9 = call zeroext i1 @_ZN4core9ub_checks17is_nonoverlapping7runtime17h53575b493436527bE(ptr %src, ptr %dst, i32 %size, i32 %count) #10
  br i1 %_9, label %bb5, label %bb6

bb6:                                              ; preds = %bb4
  br label %bb7

bb5:                                              ; preds = %bb4
  ret void
}

; core::intrinsics::unlikely
; Function Attrs: nounwind
define internal zeroext i1 @_ZN4core10intrinsics8unlikely17hfc625fb68bc4cbe9E(i1 zeroext %b) unnamed_addr #1 {
start:
  ret i1 %b
}

; core::fmt::Arguments::new_v1
; Function Attrs: inlinehint nounwind
define internal void @_ZN4core3fmt9Arguments6new_v117h9cb1fbba51a4b191E(ptr sret([24 x i8]) align 4 %_0, ptr align 4 %pieces.0, i32 %pieces.1, ptr align 4 %args.0, i32 %args.1) unnamed_addr #0 {
start:
  %_9 = alloca [24 x i8], align 4
  %_3 = icmp ult i32 %pieces.1, %args.1
  br i1 %_3, label %bb3, label %bb1

bb1:                                              ; preds = %start
  %_7 = add i32 %args.1, 1
  %_6 = icmp ugt i32 %pieces.1, %_7
  br i1 %_6, label %bb2, label %bb4

bb3:                                              ; preds = %bb2, %start
  store ptr @alloc_961fd82c18500a61bf8f6d7be21ce6b0, ptr %_9, align 4
  %0 = getelementptr inbounds i8, ptr %_9, i32 4
  store i32 1, ptr %0, align 4
  %1 = load ptr, ptr @0, align 4
  %2 = load i32, ptr getelementptr inbounds (i8, ptr @0, i32 4), align 4
  %3 = getelementptr inbounds i8, ptr %_9, i32 16
  store ptr %1, ptr %3, align 4
  %4 = getelementptr inbounds i8, ptr %3, i32 4
  store i32 %2, ptr %4, align 4
  %5 = getelementptr inbounds i8, ptr %_9, i32 8
  store ptr inttoptr (i32 4 to ptr), ptr %5, align 4
  %6 = getelementptr inbounds i8, ptr %5, i32 4
  store i32 0, ptr %6, align 4
; call core::panicking::panic_fmt
  call void @_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE(ptr align 4 %_9, ptr align 4 @alloc_c996d719b03b70d75fd3f485b4b6e56f) #11
  unreachable

bb4:                                              ; preds = %bb1
  store ptr %pieces.0, ptr %_0, align 4
  %7 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %pieces.1, ptr %7, align 4
  %8 = load ptr, ptr @0, align 4
  %9 = load i32, ptr getelementptr inbounds (i8, ptr @0, i32 4), align 4
  %10 = getelementptr inbounds i8, ptr %_0, i32 16
  store ptr %8, ptr %10, align 4
  %11 = getelementptr inbounds i8, ptr %10, i32 4
  store i32 %9, ptr %11, align 4
  %12 = getelementptr inbounds i8, ptr %_0, i32 8
  store ptr %args.0, ptr %12, align 4
  %13 = getelementptr inbounds i8, ptr %12, i32 4
  store i32 %args.1, ptr %13, align 4
  ret void

bb2:                                              ; preds = %bb1
  br label %bb3
}

; core::ops::function::FnOnce::call_once
; Function Attrs: inlinehint nounwind
define internal void @_ZN4core3ops8function6FnOnce9call_once17h437fe8a52b010fedE(ptr sret([12 x i8]) align 4 %_0, ptr align 1 %0, i32 %1) unnamed_addr #0 {
start:
  %_2 = alloca [8 x i8], align 4
  store ptr %0, ptr %_2, align 4
  %2 = getelementptr inbounds i8, ptr %_2, i32 4
  store i32 %1, ptr %2, align 4
  %3 = load ptr, ptr %_2, align 4
  %4 = getelementptr inbounds i8, ptr %_2, i32 4
  %5 = load i32, ptr %4, align 4
; call alloc::str::<impl alloc::borrow::ToOwned for str>::to_owned
  call void @"_ZN5alloc3str56_$LT$impl$u20$alloc..borrow..ToOwned$u20$for$u20$str$GT$8to_owned17h9dfbd0d7b7b5c01fE"(ptr sret([12 x i8]) align 4 %_0, ptr align 1 %3, i32 %5) #10
  ret void
}

; core::ptr::read_volatile::precondition_check
; Function Attrs: inlinehint nounwind
define internal void @_ZN4core3ptr13read_volatile18precondition_check17h211ca38c4a8880f7E(ptr %addr, i32 %align) unnamed_addr #0 {
start:
; call core::ub_checks::is_aligned_and_not_null
  %_3 = call zeroext i1 @_ZN4core9ub_checks23is_aligned_and_not_null17hef179d5138129189E(ptr %addr, i32 %align) #10
  br i1 %_3, label %bb2, label %bb3

bb3:                                              ; preds = %start
; call core::panicking::panic_nounwind
  call void @_ZN4core9panicking14panic_nounwind17h16e38f5a9ff4ae2cE(ptr align 1 @alloc_d4d2a2a8539eafc62756407d946babb3, i32 110) #11
  unreachable

bb2:                                              ; preds = %start
  ret void
}

; core::ptr::drop_in_place<alloc::string::String>
; Function Attrs: nounwind
define dso_local void @"_ZN4core3ptr42drop_in_place$LT$alloc..string..String$GT$17hecd313b61134291eE"(ptr align 4 %_1) unnamed_addr #1 {
start:
; call core::ptr::drop_in_place<alloc::vec::Vec<u8>>
  call void @"_ZN4core3ptr46drop_in_place$LT$alloc..vec..Vec$LT$u8$GT$$GT$17h5df3580edf686b22E"(ptr align 4 %_1) #10
  ret void
}

; core::ptr::drop_in_place<alloc::vec::Vec<u8>>
; Function Attrs: nounwind
define dso_local void @"_ZN4core3ptr46drop_in_place$LT$alloc..vec..Vec$LT$u8$GT$$GT$17h5df3580edf686b22E"(ptr align 4 %_1) unnamed_addr #1 {
start:
; call <alloc::vec::Vec<T,A> as core::ops::drop::Drop>::drop
  call void @"_ZN70_$LT$alloc..vec..Vec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17h32f26574fa0666e9E"(ptr align 4 %_1) #10
; call core::ptr::drop_in_place<alloc::raw_vec::RawVec<u8>>
  call void @"_ZN4core3ptr53drop_in_place$LT$alloc..raw_vec..RawVec$LT$u8$GT$$GT$17h4e4fb7d0c6b123dbE"(ptr align 4 %_1) #10
  ret void
}

; core::ptr::drop_in_place<alloc::raw_vec::RawVec<u8>>
; Function Attrs: nounwind
define dso_local void @"_ZN4core3ptr53drop_in_place$LT$alloc..raw_vec..RawVec$LT$u8$GT$$GT$17h4e4fb7d0c6b123dbE"(ptr align 4 %_1) unnamed_addr #1 {
start:
; call <alloc::raw_vec::RawVec<T,A> as core::ops::drop::Drop>::drop
  call void @"_ZN77_$LT$alloc..raw_vec..RawVec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17h5be054742a362ee5E"(ptr align 4 %_1) #10
  ret void
}

; core::ptr::non_null::NonNull<T>::new_unchecked::precondition_check
; Function Attrs: inlinehint nounwind
define internal void @"_ZN4core3ptr8non_null16NonNull$LT$T$GT$13new_unchecked18precondition_check17h407ebade46cee789E"(ptr %ptr) unnamed_addr #0 {
start:
  %_4 = ptrtoint ptr %ptr to i32
  %0 = icmp eq i32 %_4, 0
  br i1 %0, label %bb1, label %bb2

bb1:                                              ; preds = %start
; call core::panicking::panic_nounwind
  call void @_ZN4core9panicking14panic_nounwind17h16e38f5a9ff4ae2cE(ptr align 1 @alloc_20b3d155afd5c58c42e598b7e6d186ef, i32 93) #11
  unreachable

bb2:                                              ; preds = %start
  ret void
}

; core::alloc::layout::Layout::array::inner
; Function Attrs: inlinehint nounwind
define internal { i32, i32 } @_ZN4core5alloc6layout6Layout5array5inner17h0a9bdb0a48d75578E(i32 %element_size, i32 %align, i32 %n) unnamed_addr #0 {
start:
  %_18 = alloca [4 x i8], align 4
  %_13 = alloca [4 x i8], align 4
  %_9 = alloca [8 x i8], align 4
  %_0 = alloca [8 x i8], align 4
  %0 = icmp eq i32 %element_size, 0
  br i1 %0, label %bb5, label %bb1

bb5:                                              ; preds = %bb4, %start
  %array_size = mul nuw i32 %element_size, %n
  store i32 %align, ptr %_18, align 4
  %_19 = load i32, ptr %_18, align 4
  %_20 = icmp uge i32 %_19, 1
  %_21 = icmp ule i32 %_19, -2147483648
  %_22 = and i1 %_20, %_21
  %1 = getelementptr inbounds i8, ptr %_9, i32 4
  store i32 %array_size, ptr %1, align 4
  store i32 %_19, ptr %_9, align 4
  %2 = load i32, ptr %_9, align 4
  %3 = getelementptr inbounds i8, ptr %_9, i32 4
  %4 = load i32, ptr %3, align 4
  store i32 %2, ptr %_0, align 4
  %5 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %4, ptr %5, align 4
  br label %bb6

bb1:                                              ; preds = %start
  store i32 %align, ptr %_13, align 4
  %_14 = load i32, ptr %_13, align 4
  %_15 = icmp uge i32 %_14, 1
  %_16 = icmp ule i32 %_14, -2147483648
  %_17 = and i1 %_15, %_16
  %_11 = sub i32 %_14, 1
  %_6 = sub i32 2147483647, %_11
  %_7 = icmp eq i32 %element_size, 0
  %6 = call i1 @llvm.expect.i1(i1 %_7, i1 false)
  br i1 %6, label %panic, label %bb2

bb2:                                              ; preds = %bb1
  %_5 = udiv i32 %_6, %element_size
  %_4 = icmp ugt i32 %n, %_5
  br i1 %_4, label %bb3, label %bb4

panic:                                            ; preds = %bb1
; call core::panicking::panic_const::panic_const_div_by_zero
  call void @_ZN4core9panicking11panic_const23panic_const_div_by_zero17h22ae5ed81ae7585cE(ptr align 4 @alloc_1badb795fc013c5a391ae9dae4e3a137) #11
  unreachable

bb4:                                              ; preds = %bb2
  br label %bb5

bb3:                                              ; preds = %bb2
  %7 = load i32, ptr @0, align 4
  %8 = load i32, ptr getelementptr inbounds (i8, ptr @0, i32 4), align 4
  store i32 %7, ptr %_0, align 4
  %9 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %8, ptr %9, align 4
  br label %bb6

bb6:                                              ; preds = %bb3, %bb5
  %10 = load i32, ptr %_0, align 4
  %11 = getelementptr inbounds i8, ptr %_0, i32 4
  %12 = load i32, ptr %11, align 4
  %13 = insertvalue { i32, i32 } poison, i32 %10, 0
  %14 = insertvalue { i32, i32 } %13, i32 %12, 1
  ret { i32, i32 } %14
}

; core::alloc::layout::Layout::dangling
; Function Attrs: inlinehint nounwind
define internal ptr @_ZN4core5alloc6layout6Layout8dangling17h2d10d34492bbdc0bE(ptr align 4 %self) unnamed_addr #0 {
start:
  %_5 = alloca [4 x i8], align 4
  %_0 = alloca [4 x i8], align 4
  %self1 = load i32, ptr %self, align 4
  store i32 %self1, ptr %_5, align 4
  %_6 = load i32, ptr %_5, align 4
  %_7 = icmp uge i32 %_6, 1
  %_8 = icmp ule i32 %_6, -2147483648
  %_9 = and i1 %_7, %_8
  %ptr = getelementptr i8, ptr null, i32 %_6
  br label %bb1

bb1:                                              ; preds = %start
; call core::ptr::non_null::NonNull<T>::new_unchecked::precondition_check
  call void @"_ZN4core3ptr8non_null16NonNull$LT$T$GT$13new_unchecked18precondition_check17h407ebade46cee789E"(ptr %ptr) #10
  br label %bb3

bb3:                                              ; preds = %bb1
  store ptr %ptr, ptr %_0, align 4
  %0 = load ptr, ptr %_0, align 4
  ret ptr %0
}

; core::option::Option<T>::map_or_else
; Function Attrs: inlinehint nounwind
define dso_local void @"_ZN4core6option15Option$LT$T$GT$11map_or_else17h9a2ec9ca42c8b158E"(ptr sret([12 x i8]) align 4 %_0, ptr align 1 %0, i32 %1, ptr align 4 %default) unnamed_addr #0 {
start:
  %_7 = alloca [8 x i8], align 4
  %self = alloca [8 x i8], align 4
  store ptr %0, ptr %self, align 4
  %2 = getelementptr inbounds i8, ptr %self, i32 4
  store i32 %1, ptr %2, align 4
  %3 = load ptr, ptr %self, align 4
  %4 = ptrtoint ptr %3 to i32
  %5 = icmp eq i32 %4, 0
  %_4 = select i1 %5, i32 0, i32 1
  %6 = icmp eq i32 %_4, 0
  br i1 %6, label %bb2, label %bb3

bb2:                                              ; preds = %start
; call alloc::fmt::format::{{closure}}
  call void @"_ZN5alloc3fmt6format28_$u7b$$u7b$closure$u7d$$u7d$17h14105c7911711c9eE"(ptr sret([12 x i8]) align 4 %_0, ptr align 4 %default) #10
  br label %bb6

bb3:                                              ; preds = %start
  %t.0 = load ptr, ptr %self, align 4
  %7 = getelementptr inbounds i8, ptr %self, i32 4
  %t.1 = load i32, ptr %7, align 4
  store ptr %t.0, ptr %_7, align 4
  %8 = getelementptr inbounds i8, ptr %_7, i32 4
  store i32 %t.1, ptr %8, align 4
  %9 = load ptr, ptr %_7, align 4
  %10 = getelementptr inbounds i8, ptr %_7, i32 4
  %11 = load i32, ptr %10, align 4
; call core::ops::function::FnOnce::call_once
  call void @_ZN4core3ops8function6FnOnce9call_once17h437fe8a52b010fedE(ptr sret([12 x i8]) align 4 %_0, ptr align 1 %9, i32 %11) #10
  br label %bb7

bb6:                                              ; preds = %bb7, %bb2
  ret void

bb7:                                              ; preds = %bb3
  br label %bb6

bb1:                                              ; No predecessors!
  unreachable
}

; core::ub_checks::is_nonoverlapping::runtime
; Function Attrs: inlinehint nounwind
define internal zeroext i1 @_ZN4core9ub_checks17is_nonoverlapping7runtime17h53575b493436527bE(ptr %src, ptr %dst, i32 %size, i32 %count) unnamed_addr #0 {
start:
  %0 = alloca [1 x i8], align 1
  %diff = alloca [4 x i8], align 4
  %_9 = alloca [8 x i8], align 4
  %src_usize = ptrtoint ptr %src to i32
  %dst_usize = ptrtoint ptr %dst to i32
  %1 = call { i32, i1 } @llvm.umul.with.overflow.i32(i32 %size, i32 %count)
  %_15.0 = extractvalue { i32, i1 } %1, 0
  %_15.1 = extractvalue { i32, i1 } %1, 1
  %2 = call i1 @llvm.expect.i1(i1 %_15.1, i1 false)
  %3 = zext i1 %2 to i8
  store i8 %3, ptr %0, align 1
  %4 = load i8, ptr %0, align 1
  %_12 = trunc i8 %4 to i1
  br i1 %_12, label %bb2, label %bb3

bb3:                                              ; preds = %start
  %5 = getelementptr inbounds i8, ptr %_9, i32 4
  store i32 %_15.0, ptr %5, align 4
  store i32 1, ptr %_9, align 4
  %6 = getelementptr inbounds i8, ptr %_9, i32 4
  %size1 = load i32, ptr %6, align 4
  %_22 = icmp ult i32 %src_usize, %dst_usize
  br i1 %_22, label %bb4, label %bb5

bb2:                                              ; preds = %start
; call core::panicking::panic_nounwind
  call void @_ZN4core9panicking14panic_nounwind17h16e38f5a9ff4ae2cE(ptr align 1 @alloc_763310d78c99c2c1ad3f8a9821e942f3, i32 61) #11
  unreachable

bb5:                                              ; preds = %bb3
  %7 = sub i32 %src_usize, %dst_usize
  store i32 %7, ptr %diff, align 4
  br label %bb6

bb4:                                              ; preds = %bb3
  %8 = sub i32 %dst_usize, %src_usize
  store i32 %8, ptr %diff, align 4
  br label %bb6

bb6:                                              ; preds = %bb4, %bb5
  %_11 = load i32, ptr %diff, align 4
  %_0 = icmp uge i32 %_11, %size1
  ret i1 %_0
}

; core::ub_checks::is_aligned_and_not_null
; Function Attrs: inlinehint nounwind
define internal zeroext i1 @_ZN4core9ub_checks23is_aligned_and_not_null17hef179d5138129189E(ptr %ptr, i32 %align) unnamed_addr #0 {
start:
  %0 = alloca [4 x i8], align 4
  %_6 = alloca [24 x i8], align 4
  %_0 = alloca [1 x i8], align 1
  %_4 = ptrtoint ptr %ptr to i32
  %1 = icmp eq i32 %_4, 0
  br i1 %1, label %bb1, label %bb2

bb1:                                              ; preds = %start
  store i8 0, ptr %_0, align 1
  br label %bb3

bb2:                                              ; preds = %start
  %2 = call i32 @llvm.ctpop.i32(i32 %align)
  store i32 %2, ptr %0, align 4
  %_8 = load i32, ptr %0, align 4
  %3 = icmp eq i32 %_8, 1
  br i1 %3, label %bb4, label %bb5

bb3:                                              ; preds = %bb4, %bb1
  %4 = load i8, ptr %_0, align 1
  %5 = trunc i8 %4 to i1
  ret i1 %5

bb4:                                              ; preds = %bb2
  %_12 = sub i32 %align, 1
  %_11 = and i32 %_4, %_12
  %6 = icmp eq i32 %_11, 0
  %7 = zext i1 %6 to i8
  store i8 %7, ptr %_0, align 1
  br label %bb3

bb5:                                              ; preds = %bb2
  store ptr @alloc_b498cf0a06cafe1ad822ab5dde97c8c0, ptr %_6, align 4
  %8 = getelementptr inbounds i8, ptr %_6, i32 4
  store i32 1, ptr %8, align 4
  %9 = load ptr, ptr @0, align 4
  %10 = load i32, ptr getelementptr inbounds (i8, ptr @0, i32 4), align 4
  %11 = getelementptr inbounds i8, ptr %_6, i32 16
  store ptr %9, ptr %11, align 4
  %12 = getelementptr inbounds i8, ptr %11, i32 4
  store i32 %10, ptr %12, align 4
  %13 = getelementptr inbounds i8, ptr %_6, i32 8
  store ptr inttoptr (i32 4 to ptr), ptr %13, align 4
  %14 = getelementptr inbounds i8, ptr %13, i32 4
  store i32 0, ptr %14, align 4
; call core::panicking::panic_fmt
  call void @_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE(ptr align 4 %_6, ptr align 4 @alloc_2f85c3373aac8b285ea093821a4ea7c0) #11
  unreachable
}

; <T as alloc::slice::hack::ConvertVec>::to_vec
; Function Attrs: inlinehint nounwind
define dso_local void @"_ZN52_$LT$T$u20$as$u20$alloc..slice..hack..ConvertVec$GT$6to_vec17h6cc57b224432aae8E"(ptr sret([12 x i8]) align 4 %_0, ptr align 1 %s.0, i32 %s.1) unnamed_addr #0 {
start:
  %_12 = alloca [12 x i8], align 4
  %v = alloca [12 x i8], align 4
; call alloc::raw_vec::RawVec<T,A>::try_allocate_in
  call void @"_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$15try_allocate_in17h33f63ae881c51c2aE"(ptr sret([12 x i8]) align 4 %_12, i32 %s.1, i1 zeroext false) #10
  %_13 = load i32, ptr %_12, align 4
  %0 = icmp eq i32 %_13, 0
  br i1 %0, label %bb4, label %bb3

bb4:                                              ; preds = %start
  %1 = getelementptr inbounds i8, ptr %_12, i32 4
  %res.0 = load i32, ptr %1, align 4
  %2 = getelementptr inbounds i8, ptr %1, i32 4
  %res.1 = load ptr, ptr %2, align 4
  store i32 %res.0, ptr %v, align 4
  %3 = getelementptr inbounds i8, ptr %v, i32 4
  store ptr %res.1, ptr %3, align 4
  %4 = getelementptr inbounds i8, ptr %v, i32 8
  store i32 0, ptr %4, align 4
  %5 = getelementptr inbounds i8, ptr %v, i32 4
  %self = load ptr, ptr %5, align 4
  br label %bb5

bb3:                                              ; preds = %start
  %6 = getelementptr inbounds i8, ptr %_12, i32 4
  %err.0 = load i32, ptr %6, align 4
  %7 = getelementptr inbounds i8, ptr %6, i32 4
  %err.1 = load i32, ptr %7, align 4
; call alloc::raw_vec::handle_error
  call void @_ZN5alloc7raw_vec12handle_error17h6991f391977ec209E(i32 %err.0, i32 %err.1) #11
  unreachable

bb5:                                              ; preds = %bb4
; call core::intrinsics::copy_nonoverlapping::precondition_check
  call void @_ZN4core10intrinsics19copy_nonoverlapping18precondition_check17h8d7e88ff352b7e3cE(ptr %s.0, ptr %self, i32 1, i32 1, i32 %s.1) #10
  br label %bb7

bb7:                                              ; preds = %bb5
  %8 = mul i32 %s.1, 1
  call void @llvm.memcpy.p0.p0.i32(ptr align 1 %self, ptr align 1 %s.0, i32 %8, i1 false)
  %9 = getelementptr inbounds i8, ptr %v, i32 8
  store i32 %s.1, ptr %9, align 4
  call void @llvm.memcpy.p0.p0.i32(ptr align 4 %_0, ptr align 4 %v, i32 12, i1 false)
  ret void

bb2:                                              ; No predecessors!
  unreachable
}

; alloc::fmt::format
; Function Attrs: inlinehint nounwind
define internal void @_ZN5alloc3fmt6format17h67dd6f5d324a980aE(ptr sret([12 x i8]) align 4 %_0, ptr align 4 %args) unnamed_addr #0 {
start:
  %_4 = alloca [4 x i8], align 4
  %_2 = alloca [8 x i8], align 4
  %_6.0 = load ptr, ptr %args, align 4
  %0 = getelementptr inbounds i8, ptr %args, i32 4
  %_6.1 = load i32, ptr %0, align 4
  %1 = getelementptr inbounds i8, ptr %args, i32 8
  %_7.0 = load ptr, ptr %1, align 4
  %2 = getelementptr inbounds i8, ptr %1, i32 4
  %_7.1 = load i32, ptr %2, align 4
  %3 = icmp eq i32 %_6.1, 0
  br i1 %3, label %bb4, label %bb5

bb4:                                              ; preds = %start
  %4 = icmp eq i32 %_7.1, 0
  br i1 %4, label %bb7, label %bb3

bb5:                                              ; preds = %start
  %5 = icmp eq i32 %_6.1, 1
  br i1 %5, label %bb6, label %bb3

bb7:                                              ; preds = %bb4
  store ptr inttoptr (i32 1 to ptr), ptr %_2, align 4
  %6 = getelementptr inbounds i8, ptr %_2, i32 4
  store i32 0, ptr %6, align 4
  br label %bb2

bb3:                                              ; preds = %bb6, %bb5, %bb4
  %7 = load ptr, ptr @0, align 4
  %8 = load i32, ptr getelementptr inbounds (i8, ptr @0, i32 4), align 4
  store ptr %7, ptr %_2, align 4
  %9 = getelementptr inbounds i8, ptr %_2, i32 4
  store i32 %8, ptr %9, align 4
  br label %bb2

bb2:                                              ; preds = %bb3, %bb8, %bb7
  store ptr %args, ptr %_4, align 4
  %10 = load ptr, ptr %_2, align 4
  %11 = getelementptr inbounds i8, ptr %_2, i32 4
  %12 = load i32, ptr %11, align 4
  %13 = load ptr, ptr %_4, align 4
; call core::option::Option<T>::map_or_else
  call void @"_ZN4core6option15Option$LT$T$GT$11map_or_else17h9a2ec9ca42c8b158E"(ptr sret([12 x i8]) align 4 %_0, ptr align 1 %10, i32 %12, ptr align 4 %13) #10
  ret void

bb6:                                              ; preds = %bb5
  %14 = icmp eq i32 %_7.1, 0
  br i1 %14, label %bb8, label %bb3

bb8:                                              ; preds = %bb6
  %s = getelementptr inbounds [0 x { ptr, i32 }], ptr %_6.0, i32 0, i32 0
  %15 = getelementptr inbounds [0 x { ptr, i32 }], ptr %_6.0, i32 0, i32 0
  %_13.0 = load ptr, ptr %15, align 4
  %16 = getelementptr inbounds i8, ptr %15, i32 4
  %_13.1 = load i32, ptr %16, align 4
  store ptr %_13.0, ptr %_2, align 4
  %17 = getelementptr inbounds i8, ptr %_2, i32 4
  store i32 %_13.1, ptr %17, align 4
  br label %bb2
}

; alloc::fmt::format::{{closure}}
; Function Attrs: inlinehint nounwind
define dso_local void @"_ZN5alloc3fmt6format28_$u7b$$u7b$closure$u7d$$u7d$17h14105c7911711c9eE"(ptr sret([12 x i8]) align 4 %_0, ptr align 4 %_1) unnamed_addr #0 {
start:
  %_2 = alloca [24 x i8], align 4
  call void @llvm.memcpy.p0.p0.i32(ptr align 4 %_2, ptr align 4 %_1, i32 24, i1 false)
; call alloc::fmt::format::format_inner
  call void @_ZN5alloc3fmt6format12format_inner17hdab397b1dc5a3b03E(ptr sret([12 x i8]) align 4 %_0, ptr align 4 %_2) #10
  ret void
}

; alloc::str::<impl alloc::borrow::ToOwned for str>::to_owned
; Function Attrs: inlinehint nounwind
define internal void @"_ZN5alloc3str56_$LT$impl$u20$alloc..borrow..ToOwned$u20$for$u20$str$GT$8to_owned17h9dfbd0d7b7b5c01fE"(ptr sret([12 x i8]) align 4 %_0, ptr align 1 %self.0, i32 %self.1) unnamed_addr #0 {
start:
  %bytes = alloca [12 x i8], align 4
; call <T as alloc::slice::hack::ConvertVec>::to_vec
  call void @"_ZN52_$LT$T$u20$as$u20$alloc..slice..hack..ConvertVec$GT$6to_vec17h6cc57b224432aae8E"(ptr sret([12 x i8]) align 4 %bytes, ptr align 1 %self.0, i32 %self.1) #10
  call void @llvm.memcpy.p0.p0.i32(ptr align 4 %_0, ptr align 4 %bytes, i32 12, i1 false)
  ret void
}

; alloc::alloc::alloc
; Function Attrs: inlinehint nounwind
define internal ptr @_ZN5alloc5alloc5alloc17h2f75a0446fc5f4afE(i32 %0, i32 %1) unnamed_addr #0 {
start:
  %2 = alloca [1 x i8], align 1
  %_13 = alloca [4 x i8], align 4
  %layout = alloca [8 x i8], align 4
  store i32 %0, ptr %layout, align 4
  %3 = getelementptr inbounds i8, ptr %layout, i32 4
  store i32 %1, ptr %3, align 4
  br label %bb3

bb3:                                              ; preds = %start
; call core::ptr::read_volatile::precondition_check
  call void @_ZN4core3ptr13read_volatile18precondition_check17h211ca38c4a8880f7E(ptr @__rust_no_alloc_shim_is_unstable, i32 1) #10
  br label %bb5

bb5:                                              ; preds = %bb3
  %4 = load volatile i8, ptr @__rust_no_alloc_shim_is_unstable, align 1
  store i8 %4, ptr %2, align 1
  %_2 = load i8, ptr %2, align 1
  %5 = getelementptr inbounds i8, ptr %layout, i32 4
  %_5 = load i32, ptr %5, align 4
  %self = load i32, ptr %layout, align 4
  store i32 %self, ptr %_13, align 4
  %_14 = load i32, ptr %_13, align 4
  %_15 = icmp uge i32 %_14, 1
  %_16 = icmp ule i32 %_14, -2147483648
  %_17 = and i1 %_15, %_16
  %_0 = call ptr @__rust_alloc(i32 %_5, i32 %_14) #10
  ret ptr %_0
}

; alloc::alloc::Global::alloc_impl
; Function Attrs: inlinehint nounwind
define internal { ptr, i32 } @_ZN5alloc5alloc6Global10alloc_impl17h70ccf6b2efb805b4E(ptr align 1 %self, i32 %0, i32 %1, i1 zeroext %zeroed) unnamed_addr #0 {
start:
  %_37 = alloca [4 x i8], align 4
  %_32 = alloca [4 x i8], align 4
  %_17 = alloca [8 x i8], align 4
  %self3 = alloca [4 x i8], align 4
  %self2 = alloca [4 x i8], align 4
  %_12 = alloca [4 x i8], align 4
  %layout1 = alloca [8 x i8], align 4
  %raw_ptr = alloca [4 x i8], align 4
  %_6 = alloca [8 x i8], align 4
  %_0 = alloca [8 x i8], align 4
  %layout = alloca [8 x i8], align 4
  store i32 %0, ptr %layout, align 4
  %2 = getelementptr inbounds i8, ptr %layout, i32 4
  store i32 %1, ptr %2, align 4
  %3 = getelementptr inbounds i8, ptr %layout, i32 4
  %size = load i32, ptr %3, align 4
  %4 = icmp eq i32 %size, 0
  br i1 %4, label %bb2, label %bb1

bb2:                                              ; preds = %start
; call core::alloc::layout::Layout::dangling
  %data = call ptr @_ZN4core5alloc6layout6Layout8dangling17h2d10d34492bbdc0bE(ptr align 4 %layout) #10
  br label %bb9

bb1:                                              ; preds = %start
  br i1 %zeroed, label %bb4, label %bb5

bb9:                                              ; preds = %bb2
; call core::ptr::non_null::NonNull<T>::new_unchecked::precondition_check
  call void @"_ZN4core3ptr8non_null16NonNull$LT$T$GT$13new_unchecked18precondition_check17h407ebade46cee789E"(ptr %data) #10
  br label %bb11

bb11:                                             ; preds = %bb9
  store ptr %data, ptr %_6, align 4
  %5 = getelementptr inbounds i8, ptr %_6, i32 4
  store i32 0, ptr %5, align 4
  %6 = load ptr, ptr %_6, align 4
  %7 = getelementptr inbounds i8, ptr %_6, i32 4
  %8 = load i32, ptr %7, align 4
  store ptr %6, ptr %_0, align 4
  %9 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %8, ptr %9, align 4
  br label %bb8

bb8:                                              ; preds = %bb19, %bb13, %bb11
  %10 = load ptr, ptr %_0, align 4
  %11 = getelementptr inbounds i8, ptr %_0, i32 4
  %12 = load i32, ptr %11, align 4
  %13 = insertvalue { ptr, i32 } poison, ptr %10, 0
  %14 = insertvalue { ptr, i32 } %13, i32 %12, 1
  ret { ptr, i32 } %14

bb5:                                              ; preds = %bb1
  %_11.0 = load i32, ptr %layout, align 4
  %15 = getelementptr inbounds i8, ptr %layout, i32 4
  %_11.1 = load i32, ptr %15, align 4
; call alloc::alloc::alloc
  %16 = call ptr @_ZN5alloc5alloc5alloc17h2f75a0446fc5f4afE(i32 %_11.0, i32 %_11.1) #10
  store ptr %16, ptr %raw_ptr, align 4
  br label %bb7

bb4:                                              ; preds = %bb1
  %17 = load i32, ptr %layout, align 4
  %18 = getelementptr inbounds i8, ptr %layout, i32 4
  %19 = load i32, ptr %18, align 4
  store i32 %17, ptr %layout1, align 4
  %20 = getelementptr inbounds i8, ptr %layout1, i32 4
  store i32 %19, ptr %20, align 4
  %21 = getelementptr inbounds i8, ptr %layout1, i32 4
  %_27 = load i32, ptr %21, align 4
  %self4 = load i32, ptr %layout1, align 4
  store i32 %self4, ptr %_32, align 4
  %_33 = load i32, ptr %_32, align 4
  %_34 = icmp uge i32 %_33, 1
  %_35 = icmp ule i32 %_33, -2147483648
  %_36 = and i1 %_34, %_35
  %22 = call ptr @__rust_alloc_zeroed(i32 %_27, i32 %_33) #10
  store ptr %22, ptr %raw_ptr, align 4
  br label %bb7

bb7:                                              ; preds = %bb4, %bb5
  %ptr = load ptr, ptr %raw_ptr, align 4
  %_38 = ptrtoint ptr %ptr to i32
  %23 = icmp eq i32 %_38, 0
  br i1 %23, label %bb13, label %bb14

bb13:                                             ; preds = %bb7
  store ptr null, ptr %self3, align 4
  store ptr null, ptr %self2, align 4
  %24 = load ptr, ptr @0, align 4
  %25 = load i32, ptr getelementptr inbounds (i8, ptr @0, i32 4), align 4
  store ptr %24, ptr %_0, align 4
  %26 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %25, ptr %26, align 4
  br label %bb8

bb14:                                             ; preds = %bb7
  br label %bb15

bb15:                                             ; preds = %bb14
; call core::ptr::non_null::NonNull<T>::new_unchecked::precondition_check
  call void @"_ZN4core3ptr8non_null16NonNull$LT$T$GT$13new_unchecked18precondition_check17h407ebade46cee789E"(ptr %ptr) #10
  br label %bb16

bb16:                                             ; preds = %bb15
  store ptr %ptr, ptr %_37, align 4
  %27 = load ptr, ptr %_37, align 4
  store ptr %27, ptr %self3, align 4
  %v = load ptr, ptr %self3, align 4
  store ptr %v, ptr %self2, align 4
  %v5 = load ptr, ptr %self2, align 4
  store ptr %v5, ptr %_12, align 4
  %ptr6 = load ptr, ptr %_12, align 4
  br label %bb17

bb17:                                             ; preds = %bb16
; call core::ptr::non_null::NonNull<T>::new_unchecked::precondition_check
  call void @"_ZN4core3ptr8non_null16NonNull$LT$T$GT$13new_unchecked18precondition_check17h407ebade46cee789E"(ptr %ptr6) #10
  br label %bb19

bb19:                                             ; preds = %bb17
  store ptr %ptr6, ptr %_17, align 4
  %28 = getelementptr inbounds i8, ptr %_17, i32 4
  store i32 %size, ptr %28, align 4
  %29 = load ptr, ptr %_17, align 4
  %30 = getelementptr inbounds i8, ptr %_17, i32 4
  %31 = load i32, ptr %30, align 4
  store ptr %29, ptr %_0, align 4
  %32 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %31, ptr %32, align 4
  br label %bb8
}

; alloc::raw_vec::RawVec<T,A>::current_memory
; Function Attrs: nounwind
define dso_local void @"_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$14current_memory17h25f56c238f1b29b5E"(ptr sret([12 x i8]) align 4 %_0, ptr align 4 %self) unnamed_addr #1 {
start:
  %self1 = alloca [4 x i8], align 4
  %_9 = alloca [12 x i8], align 4
  %layout = alloca [8 x i8], align 4
  br label %bb1

bb1:                                              ; preds = %start
  %_3 = load i32, ptr %self, align 4
  %0 = icmp eq i32 %_3, 0
  br i1 %0, label %bb2, label %bb4

bb2:                                              ; preds = %bb1
  br label %bb3

bb4:                                              ; preds = %bb1
  %rhs = load i32, ptr %self, align 4
  %size = mul nuw i32 1, %rhs
  %1 = getelementptr inbounds i8, ptr %layout, i32 4
  store i32 %size, ptr %1, align 4
  store i32 1, ptr %layout, align 4
  %2 = getelementptr inbounds i8, ptr %self, i32 4
  %self2 = load ptr, ptr %2, align 4
  store ptr %self2, ptr %self1, align 4
  %3 = load ptr, ptr %self1, align 4
  store ptr %3, ptr %_9, align 4
  %4 = load i32, ptr %layout, align 4
  %5 = getelementptr inbounds i8, ptr %layout, i32 4
  %6 = load i32, ptr %5, align 4
  %7 = getelementptr inbounds i8, ptr %_9, i32 4
  store i32 %4, ptr %7, align 4
  %8 = getelementptr inbounds i8, ptr %7, i32 4
  store i32 %6, ptr %8, align 4
  call void @llvm.memcpy.p0.p0.i32(ptr align 4 %_0, ptr align 4 %_9, i32 12, i1 false)
  br label %bb5

bb3:                                              ; preds = %bb2
  %9 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 0, ptr %9, align 4
  br label %bb5

bb5:                                              ; preds = %bb3, %bb4
  ret void
}

; alloc::raw_vec::RawVec<T,A>::try_allocate_in
; Function Attrs: nounwind
define dso_local void @"_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$15try_allocate_in17h33f63ae881c51c2aE"(ptr sret([12 x i8]) align 4 %_0, i32 %capacity, i1 zeroext %0) unnamed_addr #1 {
start:
  %_29 = alloca [4 x i8], align 4
  %pointer = alloca [4 x i8], align 4
  %_27 = alloca [4 x i8], align 4
  %_26 = alloca [8 x i8], align 4
  %self = alloca [8 x i8], align 4
  %_23 = alloca [8 x i8], align 4
  %result = alloca [8 x i8], align 4
  %_11 = alloca [8 x i8], align 4
  %_8 = alloca [8 x i8], align 4
  %layout = alloca [8 x i8], align 4
  %alloc = alloca [0 x i8], align 1
  %init = alloca [1 x i8], align 1
  %1 = zext i1 %0 to i8
  store i8 %1, ptr %init, align 1
  br label %bb1

bb1:                                              ; preds = %start
  %2 = icmp eq i32 %capacity, 0
  br i1 %2, label %bb2, label %bb4

bb2:                                              ; preds = %bb1
; call alloc::raw_vec::RawVec<T,A>::new_in
  %3 = call { i32, ptr } @"_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$6new_in17h4bc4d1f22578b5f7E"() #10
  %_5.0 = extractvalue { i32, ptr } %3, 0
  %_5.1 = extractvalue { i32, ptr } %3, 1
  %4 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %_5.0, ptr %4, align 4
  %5 = getelementptr inbounds i8, ptr %4, i32 4
  store ptr %_5.1, ptr %5, align 4
  store i32 0, ptr %_0, align 4
  br label %bb15

bb4:                                              ; preds = %bb1
; call core::alloc::layout::Layout::array::inner
  %6 = call { i32, i32 } @_ZN4core5alloc6layout6Layout5array5inner17h0a9bdb0a48d75578E(i32 1, i32 1, i32 %capacity) #10
  %7 = extractvalue { i32, i32 } %6, 0
  %8 = extractvalue { i32, i32 } %6, 1
  store i32 %7, ptr %_8, align 4
  %9 = getelementptr inbounds i8, ptr %_8, i32 4
  store i32 %8, ptr %9, align 4
  %10 = load i32, ptr %_8, align 4
  %11 = icmp eq i32 %10, 0
  %_9 = select i1 %11, i32 1, i32 0
  %12 = icmp eq i32 %_9, 0
  br i1 %12, label %bb7, label %bb6

bb7:                                              ; preds = %bb4
  %layout.0 = load i32, ptr %_8, align 4
  %13 = getelementptr inbounds i8, ptr %_8, i32 4
  %layout.1 = load i32, ptr %13, align 4
  store i32 %layout.0, ptr %layout, align 4
  %14 = getelementptr inbounds i8, ptr %layout, i32 4
  store i32 %layout.1, ptr %14, align 4
  %15 = getelementptr inbounds i8, ptr %layout, i32 4
  %alloc_size = load i32, ptr %15, align 4
  %_34 = icmp ugt i32 %alloc_size, 2147483647
  br i1 %_34, label %bb19, label %bb20

bb6:                                              ; preds = %bb4
  %16 = load i32, ptr @0, align 4
  %17 = load i32, ptr getelementptr inbounds (i8, ptr @0, i32 4), align 4
  %18 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %16, ptr %18, align 4
  %19 = getelementptr inbounds i8, ptr %18, i32 4
  store i32 %17, ptr %19, align 4
  store i32 1, ptr %_0, align 4
  br label %bb16

bb20:                                             ; preds = %bb7
  %20 = load i8, ptr %init, align 1
  %21 = trunc i8 %20 to i1
  %_16 = zext i1 %21 to i32
  %22 = icmp eq i32 %_16, 0
  br i1 %22, label %bb9, label %bb8

bb19:                                             ; preds = %bb7
  %23 = load i32, ptr @0, align 4
  %24 = load i32, ptr getelementptr inbounds (i8, ptr @0, i32 4), align 4
  store i32 %23, ptr %_11, align 4
  %25 = getelementptr inbounds i8, ptr %_11, i32 4
  store i32 %24, ptr %25, align 4
  %err.0 = load i32, ptr %_11, align 4
  %26 = getelementptr inbounds i8, ptr %_11, i32 4
  %err.1 = load i32, ptr %26, align 4
  %27 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %err.0, ptr %27, align 4
  %28 = getelementptr inbounds i8, ptr %27, i32 4
  store i32 %err.1, ptr %28, align 4
  store i32 1, ptr %_0, align 4
  br label %bb16

bb9:                                              ; preds = %bb20
  %_18.0 = load i32, ptr %layout, align 4
  %29 = getelementptr inbounds i8, ptr %layout, i32 4
  %_18.1 = load i32, ptr %29, align 4
; call <alloc::alloc::Global as core::alloc::Allocator>::allocate
  %30 = call { ptr, i32 } @"_ZN63_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..Allocator$GT$8allocate17h757b4a2a0e83aa61E"(ptr align 1 %alloc, i32 %_18.0, i32 %_18.1) #10
  %31 = extractvalue { ptr, i32 } %30, 0
  %32 = extractvalue { ptr, i32 } %30, 1
  store ptr %31, ptr %result, align 4
  %33 = getelementptr inbounds i8, ptr %result, i32 4
  store i32 %32, ptr %33, align 4
  br label %bb12

bb8:                                              ; preds = %bb20
  %_20.0 = load i32, ptr %layout, align 4
  %34 = getelementptr inbounds i8, ptr %layout, i32 4
  %_20.1 = load i32, ptr %34, align 4
; call <alloc::alloc::Global as core::alloc::Allocator>::allocate_zeroed
  %35 = call { ptr, i32 } @"_ZN63_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..Allocator$GT$15allocate_zeroed17h7c5f6e57a18c664fE"(ptr align 1 %alloc, i32 %_20.0, i32 %_20.1) #10
  %36 = extractvalue { ptr, i32 } %35, 0
  %37 = extractvalue { ptr, i32 } %35, 1
  store ptr %36, ptr %result, align 4
  %38 = getelementptr inbounds i8, ptr %result, i32 4
  store i32 %37, ptr %38, align 4
  br label %bb12

bb12:                                             ; preds = %bb8, %bb9
  %39 = load ptr, ptr %result, align 4
  %40 = ptrtoint ptr %39 to i32
  %41 = icmp eq i32 %40, 0
  %_21 = select i1 %41, i32 1, i32 0
  %42 = icmp eq i32 %_21, 0
  br i1 %42, label %bb14, label %bb13

bb14:                                             ; preds = %bb12
  %ptr.0 = load ptr, ptr %result, align 4
  %43 = getelementptr inbounds i8, ptr %result, i32 4
  %ptr.1 = load i32, ptr %43, align 4
  store ptr %ptr.0, ptr %pointer, align 4
  %44 = load ptr, ptr %pointer, align 4
  store ptr %44, ptr %_27, align 4
  store i32 %capacity, ptr %_29, align 4
  %45 = load ptr, ptr %_27, align 4
  %46 = getelementptr inbounds i8, ptr %_26, i32 4
  store ptr %45, ptr %46, align 4
  %47 = load i32, ptr %_29, align 4
  store i32 %47, ptr %_26, align 4
  %48 = load i32, ptr %_26, align 4
  %49 = getelementptr inbounds i8, ptr %_26, i32 4
  %50 = load ptr, ptr %49, align 4
  %51 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %48, ptr %51, align 4
  %52 = getelementptr inbounds i8, ptr %51, i32 4
  store ptr %50, ptr %52, align 4
  store i32 0, ptr %_0, align 4
  br label %bb15

bb13:                                             ; preds = %bb12
  %_25.0 = load i32, ptr %layout, align 4
  %53 = getelementptr inbounds i8, ptr %layout, i32 4
  %_25.1 = load i32, ptr %53, align 4
  store i32 %_25.0, ptr %self, align 4
  %54 = getelementptr inbounds i8, ptr %self, i32 4
  store i32 %_25.1, ptr %54, align 4
  %55 = load i32, ptr %self, align 4
  %56 = getelementptr inbounds i8, ptr %self, i32 4
  %57 = load i32, ptr %56, align 4
  store i32 %55, ptr %_23, align 4
  %58 = getelementptr inbounds i8, ptr %_23, i32 4
  store i32 %57, ptr %58, align 4
  %59 = load i32, ptr %_23, align 4
  %60 = getelementptr inbounds i8, ptr %_23, i32 4
  %61 = load i32, ptr %60, align 4
  %62 = getelementptr inbounds i8, ptr %_0, i32 4
  store i32 %59, ptr %62, align 4
  %63 = getelementptr inbounds i8, ptr %62, i32 4
  store i32 %61, ptr %63, align 4
  store i32 1, ptr %_0, align 4
  br label %bb16

bb15:                                             ; preds = %bb2, %bb14
  br label %bb17

bb16:                                             ; preds = %bb6, %bb19, %bb13
  br label %bb17

bb17:                                             ; preds = %bb15, %bb16
  ret void

bb5:                                              ; No predecessors!
  unreachable
}

; alloc::raw_vec::RawVec<T,A>::new_in
; Function Attrs: nounwind
define dso_local { i32, ptr } @"_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$6new_in17h4bc4d1f22578b5f7E"() unnamed_addr #1 {
start:
  %_3 = alloca [4 x i8], align 4
  %_2 = alloca [4 x i8], align 4
  %_0 = alloca [8 x i8], align 4
  br label %bb1

bb1:                                              ; preds = %start
; call core::ptr::non_null::NonNull<T>::new_unchecked::precondition_check
  call void @"_ZN4core3ptr8non_null16NonNull$LT$T$GT$13new_unchecked18precondition_check17h407ebade46cee789E"(ptr getelementptr (i8, ptr null, i32 1)) #10
  br label %bb3

bb3:                                              ; preds = %bb1
  store ptr getelementptr (i8, ptr null, i32 1), ptr %_3, align 4
  %0 = load ptr, ptr %_3, align 4
  store ptr %0, ptr %_2, align 4
  %1 = load ptr, ptr %_2, align 4
  %2 = getelementptr inbounds i8, ptr %_0, i32 4
  store ptr %1, ptr %2, align 4
  store i32 0, ptr %_0, align 4
  %3 = load i32, ptr %_0, align 4
  %4 = getelementptr inbounds i8, ptr %_0, i32 4
  %5 = load ptr, ptr %4, align 4
  %6 = insertvalue { i32, ptr } poison, i32 %3, 0
  %7 = insertvalue { i32, ptr } %6, ptr %5, 1
  ret { i32, ptr } %7
}

; <alloc::alloc::Global as core::alloc::Allocator>::deallocate
; Function Attrs: inlinehint nounwind
define internal void @"_ZN63_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..Allocator$GT$10deallocate17h0a5d985326b11b74E"(ptr align 1 %self, ptr %ptr, i32 %0, i32 %1) unnamed_addr #0 {
start:
  %_14 = alloca [4 x i8], align 4
  %layout1 = alloca [8 x i8], align 4
  %layout = alloca [8 x i8], align 4
  store i32 %0, ptr %layout, align 4
  %2 = getelementptr inbounds i8, ptr %layout, i32 4
  store i32 %1, ptr %2, align 4
  %3 = getelementptr inbounds i8, ptr %layout, i32 4
  %_4 = load i32, ptr %3, align 4
  %4 = icmp eq i32 %_4, 0
  br i1 %4, label %bb2, label %bb1

bb2:                                              ; preds = %start
  br label %bb3

bb1:                                              ; preds = %start
  %5 = load i32, ptr %layout, align 4
  %6 = getelementptr inbounds i8, ptr %layout, i32 4
  %7 = load i32, ptr %6, align 4
  store i32 %5, ptr %layout1, align 4
  %8 = getelementptr inbounds i8, ptr %layout1, i32 4
  store i32 %7, ptr %8, align 4
  %9 = getelementptr inbounds i8, ptr %layout1, i32 4
  %_9 = load i32, ptr %9, align 4
  %self2 = load i32, ptr %layout1, align 4
  store i32 %self2, ptr %_14, align 4
  %_15 = load i32, ptr %_14, align 4
  %_16 = icmp uge i32 %_15, 1
  %_17 = icmp ule i32 %_15, -2147483648
  %_18 = and i1 %_16, %_17
  call void @__rust_dealloc(ptr %ptr, i32 %_9, i32 %_15) #10
  br label %bb3

bb3:                                              ; preds = %bb1, %bb2
  ret void
}

; <alloc::alloc::Global as core::alloc::Allocator>::allocate_zeroed
; Function Attrs: inlinehint nounwind
define internal { ptr, i32 } @"_ZN63_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..Allocator$GT$15allocate_zeroed17h7c5f6e57a18c664fE"(ptr align 1 %self, i32 %layout.0, i32 %layout.1) unnamed_addr #0 {
start:
; call alloc::alloc::Global::alloc_impl
  %0 = call { ptr, i32 } @_ZN5alloc5alloc6Global10alloc_impl17h70ccf6b2efb805b4E(ptr align 1 %self, i32 %layout.0, i32 %layout.1, i1 zeroext true) #10
  %_0.0 = extractvalue { ptr, i32 } %0, 0
  %_0.1 = extractvalue { ptr, i32 } %0, 1
  %1 = insertvalue { ptr, i32 } poison, ptr %_0.0, 0
  %2 = insertvalue { ptr, i32 } %1, i32 %_0.1, 1
  ret { ptr, i32 } %2
}

; <alloc::alloc::Global as core::alloc::Allocator>::allocate
; Function Attrs: inlinehint nounwind
define internal { ptr, i32 } @"_ZN63_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..Allocator$GT$8allocate17h757b4a2a0e83aa61E"(ptr align 1 %self, i32 %layout.0, i32 %layout.1) unnamed_addr #0 {
start:
; call alloc::alloc::Global::alloc_impl
  %0 = call { ptr, i32 } @_ZN5alloc5alloc6Global10alloc_impl17h70ccf6b2efb805b4E(ptr align 1 %self, i32 %layout.0, i32 %layout.1, i1 zeroext false) #10
  %_0.0 = extractvalue { ptr, i32 } %0, 0
  %_0.1 = extractvalue { ptr, i32 } %0, 1
  %1 = insertvalue { ptr, i32 } poison, ptr %_0.0, 0
  %2 = insertvalue { ptr, i32 } %1, i32 %_0.1, 1
  ret { ptr, i32 } %2
}

; <alloc::vec::Vec<T,A> as core::ops::drop::Drop>::drop
; Function Attrs: nounwind
define dso_local void @"_ZN70_$LT$alloc..vec..Vec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17h32f26574fa0666e9E"(ptr align 4 %self) unnamed_addr #1 {
start:
  %0 = getelementptr inbounds i8, ptr %self, i32 4
  %self1 = load ptr, ptr %0, align 4
  %1 = getelementptr inbounds i8, ptr %self, i32 8
  %len = load i32, ptr %1, align 4
  ret void
}

; <alloc::raw_vec::RawVec<T,A> as core::ops::drop::Drop>::drop
; Function Attrs: nounwind
define dso_local void @"_ZN77_$LT$alloc..raw_vec..RawVec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17h5be054742a362ee5E"(ptr align 4 %self) unnamed_addr #1 {
start:
  %_2 = alloca [12 x i8], align 4
; call alloc::raw_vec::RawVec<T,A>::current_memory
  call void @"_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$14current_memory17h25f56c238f1b29b5E"(ptr sret([12 x i8]) align 4 %_2, ptr align 4 %self) #10
  %0 = getelementptr inbounds i8, ptr %_2, i32 4
  %1 = load i32, ptr %0, align 4
  %2 = icmp eq i32 %1, 0
  %_4 = select i1 %2, i32 0, i32 1
  %3 = icmp eq i32 %_4, 1
  br i1 %3, label %bb2, label %bb4

bb2:                                              ; preds = %start
  %ptr = load ptr, ptr %_2, align 4
  %4 = getelementptr inbounds i8, ptr %_2, i32 4
  %layout.0 = load i32, ptr %4, align 4
  %5 = getelementptr inbounds i8, ptr %4, i32 4
  %layout.1 = load i32, ptr %5, align 4
  %_7 = getelementptr inbounds i8, ptr %self, i32 8
; call <alloc::alloc::Global as core::alloc::Allocator>::deallocate
  call void @"_ZN63_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..Allocator$GT$10deallocate17h0a5d985326b11b74E"(ptr align 1 %_7, ptr %ptr, i32 %layout.0, i32 %layout.1) #10
  br label %bb4

bb4:                                              ; preds = %bb2, %start
  ret void

bb5:                                              ; No predecessors!
  unreachable
}

; probe1::probe
; Function Attrs: nounwind
define dso_local void @_ZN6probe15probe17h092f94c8c3abeec6E() unnamed_addr #1 {
start:
  %_3.i = alloca [8 x i8], align 4
  %_8 = alloca [8 x i8], align 4
  %_7 = alloca [8 x i8], align 4
  %_3 = alloca [24 x i8], align 4
  %res = alloca [12 x i8], align 4
  %_1 = alloca [12 x i8], align 4
  store ptr @alloc_83ea17bf0c4f4a5a5a13d3ae7955acd0, ptr %_3.i, align 4
  %0 = getelementptr inbounds i8, ptr %_3.i, i32 4
  store ptr @"_ZN4core3fmt3num3imp55_$LT$impl$u20$core..fmt..LowerExp$u20$for$u20$isize$GT$3fmt17h955388736a6f9d35E", ptr %0, align 4
  call void @llvm.memcpy.p0.p0.i32(ptr align 4 %_8, ptr align 4 %_3.i, i32 8, i1 false)
  %1 = getelementptr inbounds [1 x %"core::fmt::rt::Argument<'_>"], ptr %_7, i32 0, i32 0
  call void @llvm.memcpy.p0.p0.i32(ptr align 4 %1, ptr align 4 %_8, i32 8, i1 false)
; call core::fmt::Arguments::new_v1
  call void @_ZN4core3fmt9Arguments6new_v117h9cb1fbba51a4b191E(ptr sret([24 x i8]) align 4 %_3, ptr align 4 @alloc_68ac15728a1e6ba4743b718936db7fdf, i32 1, ptr align 4 %_7, i32 1) #10
; call alloc::fmt::format
  call void @_ZN5alloc3fmt6format17h67dd6f5d324a980aE(ptr sret([12 x i8]) align 4 %res, ptr align 4 %_3) #10
  call void @llvm.memcpy.p0.p0.i32(ptr align 4 %_1, ptr align 4 %res, i32 12, i1 false)
; call core::ptr::drop_in_place<alloc::string::String>
  call void @"_ZN4core3ptr42drop_in_place$LT$alloc..string..String$GT$17hecd313b61134291eE"(ptr align 4 %_1) #10
  ret void
}

; core::panicking::panic_nounwind
; Function Attrs: cold noinline noreturn nounwind
declare dso_local void @_ZN4core9panicking14panic_nounwind17h16e38f5a9ff4ae2cE(ptr align 1, i32) unnamed_addr #2

; core::fmt::num::imp::<impl core::fmt::LowerExp for isize>::fmt
; Function Attrs: nounwind
declare dso_local zeroext i1 @"_ZN4core3fmt3num3imp55_$LT$impl$u20$core..fmt..LowerExp$u20$for$u20$isize$GT$3fmt17h955388736a6f9d35E"(ptr align 4, ptr align 4) unnamed_addr #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i32(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i32, i1 immarg) #3

; core::panicking::panic_fmt
; Function Attrs: cold noinline noreturn nounwind
declare dso_local void @_ZN4core9panicking9panic_fmt17h5c7ce52813e94bcdE(ptr align 4, ptr align 4) unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare i1 @llvm.expect.i1(i1, i1) #4

; core::panicking::panic_const::panic_const_div_by_zero
; Function Attrs: cold noinline noreturn nounwind
declare dso_local void @_ZN4core9panicking11panic_const23panic_const_div_by_zero17h22ae5ed81ae7585cE(ptr align 4) unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctpop.i32(i32) #5

; alloc::raw_vec::handle_error
; Function Attrs: cold noreturn nounwind
declare dso_local void @_ZN5alloc7raw_vec12handle_error17h6991f391977ec209E(i32, i32) unnamed_addr #6

; alloc::fmt::format::format_inner
; Function Attrs: nounwind
declare dso_local void @_ZN5alloc3fmt6format12format_inner17hdab397b1dc5a3b03E(ptr sret([12 x i8]) align 4, ptr align 4) unnamed_addr #1

; Function Attrs: nounwind allockind("alloc,uninitialized,aligned") allocsize(0)
declare dso_local noalias ptr @__rust_alloc(i32, i32 allocalign) unnamed_addr #7

; Function Attrs: nounwind allockind("alloc,zeroed,aligned") allocsize(0)
declare dso_local noalias ptr @__rust_alloc_zeroed(i32, i32 allocalign) unnamed_addr #8

; Function Attrs: nounwind allockind("free")
declare dso_local void @__rust_dealloc(ptr allocptr, i32, i32) unnamed_addr #9

attributes #0 = { inlinehint nounwind "target-cpu"="generic" }
attributes #1 = { nounwind "target-cpu"="generic" }
attributes #2 = { cold noinline noreturn nounwind "target-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { cold noreturn nounwind "target-cpu"="generic" }
attributes #7 = { nounwind allockind("alloc,uninitialized,aligned") allocsize(0) "alloc-family"="__rust_alloc" "target-cpu"="generic" }
attributes #8 = { nounwind allockind("alloc,zeroed,aligned") allocsize(0) "alloc-family"="__rust_alloc" "target-cpu"="generic" }
attributes #9 = { nounwind allockind("free") "alloc-family"="__rust_alloc" "target-cpu"="generic" }
attributes #10 = { nounwind }
attributes #11 = { noreturn nounwind }

!llvm.ident = !{!0}

!0 = !{!"rustc version 1.79.0 (129f3b996 2024-06-10)"}
