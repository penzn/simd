open Types
open Values


(* Runtime type errors *)

exception TypeError of int * value * value_type

let of_arg f n v =
  try f v with Value t -> raise (TypeError (n, v, t))


(* Int operators *)

module IntOp (IXX : Int.S) (Value : ValueType with type t = IXX.t) =
struct
  open Ast.IntOp

  let to_value = Value.to_value
  let of_value = of_arg Value.of_value

  let unop op =
    let f = match op with
      | Clz -> IXX.clz
      | Ctz -> IXX.ctz
      | Popcnt -> IXX.popcnt
      | ExtendS sz -> IXX.extend_s (8 * packed_size sz)
    in fun v -> to_value (f (of_value 1 v))

  let binop op =
    let f = match op with
      | Add -> IXX.add
      | Sub -> IXX.sub
      | Mul -> IXX.mul
      | DivS -> IXX.div_s
      | DivU -> IXX.div_u
      | RemS -> IXX.rem_s
      | RemU -> IXX.rem_u
      | And -> IXX.and_
      | Or -> IXX.or_
      | Xor -> IXX.xor
      | Shl -> IXX.shl
      | ShrU -> IXX.shr_u
      | ShrS -> IXX.shr_s
      | Rotl -> IXX.rotl
      | Rotr -> IXX.rotr
    in fun v1 v2 -> to_value (f (of_value 1 v1) (of_value 2 v2))

  let testop op =
    let f = match op with
      | Eqz -> IXX.eqz
    in fun v -> f (of_value 1 v)

  let relop op =
    let f = match op with
      | Eq -> IXX.eq
      | Ne -> IXX.ne
      | LtS -> IXX.lt_s
      | LtU -> IXX.lt_u
      | LeS -> IXX.le_s
      | LeU -> IXX.le_u
      | GtS -> IXX.gt_s
      | GtU -> IXX.gt_u
      | GeS -> IXX.ge_s
      | GeU -> IXX.ge_u
    in fun v1 v2 -> f (of_value 1 v1) (of_value 2 v2)
end

module I32Op = IntOp (I32) (Values.I32Value)
module I64Op = IntOp (I64) (Values.I64Value)


(* Float operators *)

module FloatOp (FXX : Float.S) (Value : ValueType with type t = FXX.t) =
struct
  open Ast.FloatOp

  let to_value = Value.to_value
  let of_value = of_arg Value.of_value

  let unop op =
    let f = match op with
      | Neg -> FXX.neg
      | Abs -> FXX.abs
      | Sqrt  -> FXX.sqrt
      | Ceil -> FXX.ceil
      | Floor -> FXX.floor
      | Trunc -> FXX.trunc
      | Nearest -> FXX.nearest
    in fun v -> to_value (f (of_value 1 v))

  let binop op =
    let f = match op with
      | Add -> FXX.add
      | Sub -> FXX.sub
      | Mul -> FXX.mul
      | Div -> FXX.div
      | Min -> FXX.min
      | Max -> FXX.max
      | CopySign -> FXX.copysign
    in fun v1 v2 -> to_value (f (of_value 1 v1) (of_value 2 v2))

  let testop op = assert false

  let relop op =
    let f = match op with
      | Eq -> FXX.eq
      | Ne -> FXX.ne
      | Lt -> FXX.lt
      | Le -> FXX.le
      | Gt -> FXX.gt
      | Ge -> FXX.ge
    in fun v1 v2 -> f (of_value 1 v1) (of_value 2 v2)
end

module F32Op = FloatOp (F32) (Values.F32Value)
module F64Op = FloatOp (F64) (Values.F64Value)

(* Simd operators *)

module SimdOp (SXX : Simd.S) (Value : ValueType with type t = SXX.t) =
struct
  open Ast.SimdOp

  let to_value = Value.to_value
  let of_value = of_arg Value.of_value

  let unop (op : unop) =
    fun v -> match op with
      | I8x16 Neg -> to_value (SXX.I8x16.neg (of_value 1 v))
      | I16x8 Neg -> to_value (SXX.I16x8.neg (of_value 1 v))
      | I16x8 Abs -> to_value (SXX.I16x8.abs (of_value 1 v))
      | I32x4 Abs -> to_value (SXX.I32x4.abs (of_value 1 v))
      | I32x4 Neg -> to_value (SXX.I32x4.neg (of_value 1 v))
      | F32x4 Abs -> to_value (SXX.F32x4.abs (of_value 1 v))
      | F32x4 Neg -> to_value (SXX.F32x4.neg (of_value 1 v))
      | F32x4 Sqrt -> to_value (SXX.F32x4.sqrt (of_value 1 v))
      | F64x2 Abs -> to_value (SXX.F64x2.abs (of_value 1 v))
      | F64x2 Neg -> to_value (SXX.F64x2.neg (of_value 1 v))
      | F64x2 Sqrt -> to_value (SXX.F64x2.sqrt (of_value 1 v))
      | _ -> failwith "TODO v128 unimplemented unop"

  let binop (op : binop) =
    let f = match op with
      | I8x16 Add -> SXX.I8x16.add
      | I8x16 Sub -> SXX.I8x16.sub
      | I16x8 Add -> SXX.I16x8.add
      | I16x8 Sub -> SXX.I16x8.sub
      | I16x8 Mul -> SXX.I16x8.mul
      | I16x8 MinS -> SXX.I16x8.min_s
      | I16x8 MinU -> SXX.I16x8.min_u
      | I16x8 MaxS -> SXX.I16x8.max_s
      | I16x8 MaxU -> SXX.I16x8.max_u
      | I16x8 AvgrU -> SXX.I16x8.avgr_u
      | I32x4 Add -> SXX.I32x4.add
      | I32x4 Sub -> SXX.I32x4.sub
      | I32x4 MinS -> SXX.I32x4.min_s
      | I32x4 MinU -> SXX.I32x4.min_u
      | I32x4 MaxS -> SXX.I32x4.max_s
      | I32x4 MaxU -> SXX.I32x4.max_u
      | I32x4 Mul -> SXX.I32x4.mul
      | F32x4 Add -> SXX.F32x4.add
      | F32x4 Sub -> SXX.F32x4.sub
      | F32x4 Mul -> SXX.F32x4.mul
      | F32x4 Div -> SXX.F32x4.div
      | F32x4 Min -> SXX.F32x4.min
      | F32x4 Max -> SXX.F32x4.max
      | F64x2 Add -> SXX.F64x2.add
      | F64x2 Sub -> SXX.F64x2.sub
      | F64x2 Mul -> SXX.F64x2.mul
      | F64x2 Div -> SXX.F64x2.div
      | F64x2 Min -> SXX.F64x2.min
      | F64x2 Max -> SXX.F64x2.max
      | _ -> failwith "TODO v128 unimplemented binop"
    in fun v1 v2 -> to_value (f (of_value 1 v1) (of_value 2 v2))

  (* FIXME *)
  let testop op = failwith "TODO v128 unimplemented testop"

  (* FIXME *)
  let relop op = failwith "TODO v128 unimplemented relop"

  let extractop op v =
    match op with
    | F32x4ExtractLane imm ->
      (F32Op.to_value (SXX.F32x4.extract_lane imm (of_value 1 v)))
    | I32x4ExtractLane imm ->
      (I32Op.to_value (SXX.I32x4.extract_lane imm (of_value 1 v)))
end

module V128Op = SimdOp (V128) (Values.V128Value)

(* Conversion operators *)

module I32CvtOp =
struct
  open Ast.IntOp

  let cvtop op v =
    match op with
    | WrapI64 -> I32 (I32_convert.wrap_i64 (I64Op.of_value 1 v))
    | TruncSF32 -> I32 (I32_convert.trunc_f32_s (F32Op.of_value 1 v))
    | TruncUF32 -> I32 (I32_convert.trunc_f32_u (F32Op.of_value 1 v))
    | TruncSF64 -> I32 (I32_convert.trunc_f64_s (F64Op.of_value 1 v))
    | TruncUF64 -> I32 (I32_convert.trunc_f64_u (F64Op.of_value 1 v))
    | TruncSatSF32 -> I32 (I32_convert.trunc_sat_f32_s (F32Op.of_value 1 v))
    | TruncSatUF32 -> I32 (I32_convert.trunc_sat_f32_u (F32Op.of_value 1 v))
    | TruncSatSF64 -> I32 (I32_convert.trunc_sat_f64_s (F64Op.of_value 1 v))
    | TruncSatUF64 -> I32 (I32_convert.trunc_sat_f64_u (F64Op.of_value 1 v))
    | ReinterpretFloat -> I32 (I32_convert.reinterpret_f32 (F32Op.of_value 1 v))
    | ExtendSI32 -> raise (TypeError (1, v, I32Type))
    | ExtendUI32 -> raise (TypeError (1, v, I32Type))
end

module I64CvtOp =
struct
  open Ast.IntOp

  let cvtop op v =
    match op with
    | ExtendSI32 -> I64 (I64_convert.extend_i32_s (I32Op.of_value 1 v))
    | ExtendUI32 -> I64 (I64_convert.extend_i32_u (I32Op.of_value 1 v))
    | TruncSF32 -> I64 (I64_convert.trunc_f32_s (F32Op.of_value 1 v))
    | TruncUF32 -> I64 (I64_convert.trunc_f32_u (F32Op.of_value 1 v))
    | TruncSF64 -> I64 (I64_convert.trunc_f64_s (F64Op.of_value 1 v))
    | TruncUF64 -> I64 (I64_convert.trunc_f64_u (F64Op.of_value 1 v))
    | TruncSatSF32 -> I64 (I64_convert.trunc_sat_f32_s (F32Op.of_value 1 v))
    | TruncSatUF32 -> I64 (I64_convert.trunc_sat_f32_u (F32Op.of_value 1 v))
    | TruncSatSF64 -> I64 (I64_convert.trunc_sat_f64_s (F64Op.of_value 1 v))
    | TruncSatUF64 -> I64 (I64_convert.trunc_sat_f64_u (F64Op.of_value 1 v))
    | ReinterpretFloat -> I64 (I64_convert.reinterpret_f64 (F64Op.of_value 1 v))
    | WrapI64 -> raise (TypeError (1, v, I64Type))
end

module F32CvtOp =
struct
  open Ast.FloatOp

  let cvtop op v =
    match op with
    | DemoteF64 -> F32 (F32_convert.demote_f64 (F64Op.of_value 1 v))
    | ConvertSI32 -> F32 (F32_convert.convert_i32_s (I32Op.of_value 1 v))
    | ConvertUI32 -> F32 (F32_convert.convert_i32_u (I32Op.of_value 1 v))
    | ConvertSI64 -> F32 (F32_convert.convert_i64_s (I64Op.of_value 1 v))
    | ConvertUI64 -> F32 (F32_convert.convert_i64_u (I64Op.of_value 1 v))
    | ReinterpretInt -> F32 (F32_convert.reinterpret_i32 (I32Op.of_value 1 v))
    | PromoteF32 -> raise (TypeError (1, v, F32Type))
end

module F64CvtOp =
struct
  open Ast.FloatOp

  let cvtop op v =
    match op with
    | PromoteF32 -> F64 (F64_convert.promote_f32 (F32Op.of_value 1 v))
    | ConvertSI32 -> F64 (F64_convert.convert_i32_s (I32Op.of_value 1 v))
    | ConvertUI32 -> F64 (F64_convert.convert_i32_u (I32Op.of_value 1 v))
    | ConvertSI64 -> F64 (F64_convert.convert_i64_s (I64Op.of_value 1 v))
    | ConvertUI64 -> F64 (F64_convert.convert_i64_u (I64Op.of_value 1 v))
    | ReinterpretInt -> F64 (F64_convert.reinterpret_i64 (I64Op.of_value 1 v))
    | DemoteF64 -> raise (TypeError (1, v, F64Type))
end

module V128CvtOp =
struct
  (* TODO
  open Ast.SimdOp
  *)

  (* FIXME *)
  let cvtop op v = failwith "TODO v128"
end

let eval_extractop extractop v = V128Op.extractop extractop v

(* Dispatch *)

let op i32 i64 f32 f64 v128 = function
  | I32 x -> i32 x
  | I64 x -> i64 x
  | F32 x -> f32 x
  | F64 x -> f64 x
  | V128 x -> v128 x

let eval_unop = op I32Op.unop I64Op.unop F32Op.unop F64Op.unop V128Op.unop
let eval_binop = op I32Op.binop I64Op.binop F32Op.binop F64Op.binop V128Op.binop
let eval_testop = op I32Op.testop I64Op.testop F32Op.testop F64Op.testop V128Op.testop
let eval_relop = op I32Op.relop I64Op.relop F32Op.relop F64Op.relop V128Op.relop
let eval_cvtop = op I32CvtOp.cvtop I64CvtOp.cvtop F32CvtOp.cvtop F64CvtOp.cvtop V128CvtOp.cvtop
