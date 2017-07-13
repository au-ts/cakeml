(*Generated by Lem from typeSystem.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasives_extraTheory libTheory astTheory namespaceTheory semanticPrimitivesTheory;

val _ = numLib.prefer_num();



val _ = new_theory "typeSystem"

(*open import Pervasives_extra*)
(*open import Lib*)
(*open import Ast*)
(*open import Namespace*)
(*open import SemanticPrimitives*)

(* Check that the free type variables are in the given list. Every deBruijn
 * variable must be smaller than the first argument. So if it is 0, no deBruijn
 * indices are permitted. *)
(*val check_freevars : nat -> list tvarN -> t -> bool*)
 val check_freevars_defn = Defn.Hol_multi_defns `

(check_freevars dbmax tvs (Tvar tv)=  
 (MEM tv tvs))
/\
(check_freevars dbmax tvs (Tapp ts tn)=  
 (EVERY (check_freevars dbmax tvs) ts))
/\
(check_freevars dbmax tvs (Tvar_db n)=  (n < dbmax))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) check_freevars_defn;

(* Simultaneous substitution of types for type variables in a type *)
(*val type_subst : Map.map tvarN t -> t -> t*)
 val type_subst_defn = Defn.Hol_multi_defns `

(type_subst s (Tvar tv)=  
 ((case FLOOKUP s tv of
      NONE => Tvar tv
    | SOME(t) => t
  )))
/\
(type_subst s (Tapp ts tn)=  
 (Tapp (MAP (type_subst s) ts) tn))
/\
(type_subst s (Tvar_db n)=  (Tvar_db n))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) type_subst_defn;

(* Increment the deBruijn indices in a type by n levels, skipping all levels
 * less than skip. *)
(*val deBruijn_inc : nat -> nat -> t -> t*)
 val deBruijn_inc_defn = Defn.Hol_multi_defns `

(deBruijn_inc skip n (Tvar tv)=  (Tvar tv))
/\
(deBruijn_inc skip n (Tvar_db m)=  
 (if m < skip then
    Tvar_db m
  else
    Tvar_db (m + n)))
/\
(deBruijn_inc skip n (Tapp ts tn)=  (Tapp (MAP (deBruijn_inc skip n) ts) tn))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) deBruijn_inc_defn;

(* skip the lowest given indices and replace the next (LENGTH ts) with the given types and reduce all the higher ones *)
(*val deBruijn_subst : nat -> list t -> t -> t*)
 val deBruijn_subst_defn = Defn.Hol_multi_defns `

(deBruijn_subst skip ts (Tvar tv)=  (Tvar tv))
/\
(deBruijn_subst skip ts (Tvar_db n)=  
 (if ~ (n < skip) /\ (n < (LENGTH ts + skip)) then
    EL (n - skip) ts
  else if ~ (n < skip) then
    Tvar_db (n - LENGTH ts)
  else
    Tvar_db n))
/\
(deBruijn_subst skip ts (Tapp ts' tn)=  
 (Tapp (MAP (deBruijn_subst skip ts) ts') tn))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) deBruijn_subst_defn;

(* Type environments *)
val _ = Hol_datatype `
 tenv_val_exp =
    Empty
  (* Binds several de Bruijn type variables *)
  | Bind_tvar of num => tenv_val_exp
  (* The number is how many de Bruijn type variables the typescheme binds *)
  | Bind_name of varN => num => t => tenv_val_exp`;


(*val bind_tvar : nat -> tenv_val_exp -> tenv_val_exp*)
val _ = Define `
 (bind_tvar tvs tenvE=  (if tvs =( 0 : num) then tenvE else Bind_tvar tvs tenvE))`;


(*val opt_bind_name : maybe varN -> nat -> t -> tenv_val_exp -> tenv_val_exp*)
val _ = Define `
 (opt_bind_name n tvs t tenvE=  
 ((case n of
      NONE => tenvE
    | SOME n' => Bind_name n' tvs t tenvE
  )))`;


(*val tveLookup : varN -> nat -> tenv_val_exp -> maybe (nat * t)*)
 val _ = Define `

(tveLookup n inc Empty=  NONE)
/\
(tveLookup n inc (Bind_tvar tvs tenvE)=  (tveLookup n (inc + tvs) tenvE))
/\
(tveLookup n inc (Bind_name n' tvs t tenvE)=  
 (if n' = n then
    SOME (tvs, deBruijn_inc tvs inc t)
  else
    tveLookup n inc tenvE))`;


val _ = type_abbrev( "tenv_abbrev" , ``: (modN, typeN, ( tvarN list # t)) namespace``);
val _ = type_abbrev( "tenv_ctor" , ``: (modN, conN, ( tvarN list # t list # tid_or_exn)) namespace``);
val _ = type_abbrev( "tenv_val" , ``: (modN, varN, (num # t)) namespace``);

val _ = Hol_datatype `
 type_env =
  <| v : tenv_val
   ; c : tenv_ctor
   ; t : tenv_abbrev
   |>`;


(*val extend_dec_tenv : type_env -> type_env -> type_env*)
val _ = Define `
 (extend_dec_tenv tenv' tenv=  
 (<| v := (nsAppend tenv'.v tenv.v);
     c := (nsAppend tenv'.c tenv.c);
     t := (nsAppend tenv'.t tenv.t) |>))`;


(*val lookup_varE : id modN varN -> tenv_val_exp -> maybe (nat * t)*)
val _ = Define `
 (lookup_varE id tenvE=  
 ((case id of
    Short x => tveLookup x(( 0 : num)) tenvE
  | _ => NONE
  )))`;


(*val lookup_var : id modN varN -> tenv_val_exp -> type_env -> maybe (nat * t)*)
val _ = Define `
 (lookup_var id tenvE tenv=  
 ((case lookup_varE id tenvE of
    SOME x => SOME x
  | NONE => nsLookup tenv.v id
  )))`;


(*val num_tvs : tenv_val_exp -> nat*)
 val _ = Define `

(num_tvs Empty= (( 0 : num)))
/\
(num_tvs (Bind_tvar tvs tenvE)=  (tvs + num_tvs tenvE))
/\
(num_tvs (Bind_name n tvs t tenvE)=  (num_tvs tenvE))`;


(*val bind_var_list : nat -> list (varN * t) -> tenv_val_exp -> tenv_val_exp*)
 val _ = Define `

(bind_var_list tvs [] tenvE=  tenvE)
/\
(bind_var_list tvs ((n,t)::binds) tenvE=  
 (Bind_name n tvs t (bind_var_list tvs binds tenvE)))`;


(* A pattern matches values of a certain type and extends the type environment
 * with the pattern's binders. The number is the maximum deBruijn type variable
 * allowed. *)
(*val type_p : nat -> type_env -> pat -> t -> list (varN * t) -> bool*)

(* An expression has a type *)
(*val type_e : type_env -> tenv_val_exp -> exp -> t -> bool*)

(* A list of expressions has a list of types *)
(*val type_es : type_env -> tenv_val_exp -> list exp -> list t -> bool*)

(* Type a mutually recursive bundle of functions.  Unlike pattern typing, the
 * resulting environment does not extend the input environment, but just
 * represents the functions *)
(*val type_funs : type_env -> tenv_val_exp -> list (varN * varN * exp) -> list (varN * t) -> bool*)

val _ = Hol_datatype `
 decls =
  <| defined_mods : ( modN list) set;
     defined_types : ( (modN, typeN)id) set;
     defined_exns : ( (modN, conN)id) set |>`;


(*val empty_decls : decls*)
val _ = Define `
 (empty_decls=  (<|defined_mods := ({}); defined_types := ({}); defined_exns := ({})|>))`;


(*val union_decls : decls -> decls -> decls*)
val _ = Define `
 (union_decls d1 d2=  
 (<| defined_mods := (d1.defined_mods UNION d2.defined_mods);
     defined_types := (d1.defined_types UNION d2.defined_types);
     defined_exns := (d1.defined_exns UNION d2.defined_exns) |>))`;


(* Check a declaration and update the top-level environments
 * The arguments are in order:
 * - the module that the declaration is in
 * - the set of all modules, and types, and exceptions that have been previously declared
 * - the type environment
 * - the declaration
 * - the set of all modules, and types, and exceptions that are declared here
 * - the environment of new stuff declared here *)

(*val type_d : bool -> list modN -> decls -> type_env -> dec -> decls -> type_env -> bool*)

(*val type_ds : bool -> list modN -> decls -> type_env -> list dec -> decls -> type_env -> bool*)
(*val check_signature : list modN -> tenv_abbrev -> decls -> type_env -> maybe specs -> decls -> type_env -> bool*)
(*val type_specs : list modN -> tenv_abbrev -> specs -> decls -> type_env -> bool*)
(*val type_prog : bool -> decls -> type_env -> list top -> decls -> type_env -> bool*)

(* Check that the operator can have type (t1 -> ... -> tn -> t) *)
(*val type_op : op -> list t -> t -> bool*)
val _ = Define `
 (type_op op ts t=  
 ((case (op,ts) of
      (Opapp, [Tapp [t2'; t3'] TC_fn; t2]) => (t2 = t2') /\ (t = t3')
    | (Opn _, [Tapp [] TC_int; Tapp [] TC_int]) => (t = Tint)
    | (Opb _, [Tapp [] TC_int; Tapp [] TC_int]) => (t = Tapp [] (TC_name (Short "bool")))
    | (Opw W8 _, [Tapp [] TC_word8; Tapp [] TC_word8]) => (t = Tapp [] TC_word8)
    | (Opw W64 _, [Tapp [] TC_word64; Tapp [] TC_word64]) => (t = Tapp [] TC_word64)
    | (Shift W8 _ _, [Tapp [] TC_word8]) => (t = Tapp [] TC_word8)
    | (Shift W64 _ _, [Tapp [] TC_word64]) => (t = Tapp [] TC_word64)
    | (Equality, [t1; t2]) => (t1 = t2) /\ (t = Tapp [] (TC_name (Short "bool")))
    | (Opassign, [Tapp [t1] TC_ref; t2]) => (t1 = t2) /\ (t = Tapp [] TC_tup)
    | (Opref, [t1]) => (t = Tapp [t1] TC_ref)
    | (Opderef, [Tapp [t1] TC_ref]) => (t = t1)
    | (Aw8alloc, [Tapp [] TC_int; Tapp [] TC_word8]) => (t = Tapp [] TC_word8array)
    | (Aw8sub, [Tapp [] TC_word8array; Tapp [] TC_int]) => (t = Tapp [] TC_word8)
    | (Aw8length, [Tapp [] TC_word8array]) => (t = Tapp [] TC_int)
    | (Aw8update, [Tapp [] TC_word8array; Tapp [] TC_int; Tapp [] TC_word8]) => t = Tapp [] TC_tup
    | (WordFromInt W8, [Tapp [] TC_int]) => t = Tapp [] TC_word8
    | (WordToInt W8, [Tapp [] TC_word8]) => t = Tapp [] TC_int
    | (WordFromInt W64, [Tapp [] TC_int]) => t = Tapp [] TC_word64
    | (WordToInt W64, [Tapp [] TC_word64]) => t = Tapp [] TC_int
    | (CopyStrStr, [Tapp [] TC_string; Tapp [] TC_int; Tapp [] TC_int]) => t = Tapp [] TC_string
    | (CopyStrAw8, [Tapp [] TC_string; Tapp [] TC_int; Tapp [] TC_int; Tapp [] TC_word8array; Tapp [] TC_int]) => t = Tapp [] TC_tup
    | (CopyAw8Str, [Tapp [] TC_word8array; Tapp [] TC_int; Tapp [] TC_int]) => t = Tapp [] TC_string
    | (CopyAw8Aw8, [Tapp [] TC_word8array; Tapp [] TC_int; Tapp [] TC_int; Tapp [] TC_word8array; Tapp [] TC_int]) => t = Tapp [] TC_tup
    | (Chr, [Tapp [] TC_int]) => (t = Tchar)
    | (Ord, [Tapp [] TC_char]) => (t = Tint)
    | (Chopb _, [Tapp [] TC_char; Tapp [] TC_char]) => (t = Tapp [] (TC_name (Short "bool")))
    | (Implode, [Tapp [Tapp [] TC_char] (TC_name (Short "list"))]) => t = Tapp [] TC_string
    | (Strsub, [Tapp [] TC_string; Tapp [] TC_int]) => t = Tchar
    | (Strlen, [Tapp [] TC_string]) => t = Tint
    | (Strcat, [Tapp [Tapp [] TC_string] (TC_name (Short "list"))]) => t = Tapp [] TC_string
    | (VfromList, [Tapp [t1] (TC_name (Short "list"))]) => t = Tapp [t1] TC_vector
    | (Vsub, [Tapp [t1] TC_vector; Tapp [] TC_int]) => t = t1
    | (Vlength, [Tapp [t1] TC_vector]) => (t = Tapp [] TC_int)
    | (Aalloc, [Tapp [] TC_int; t1]) => t = Tapp [t1] TC_array
    | (AallocEmpty, [Tapp [] TC_tup]) => ? t1. t = Tapp [t1] TC_array
    | (Asub, [Tapp [t1] TC_array; Tapp [] TC_int]) => t = t1
    | (Alength, [Tapp [t1] TC_array]) => t = Tapp [] TC_int
    | (Aupdate, [Tapp [t1] TC_array; Tapp [] TC_int; t2]) => (t1 = t2) /\ (t = Tapp [] TC_tup)
    | (FFI n, [Tapp [] TC_word8array]) => t = Tapp [] TC_tup
    | _ => F
  )))`;


(*val check_type_names : tenv_abbrev -> t -> bool*)
 val check_type_names_defn = Defn.Hol_multi_defns `

(check_type_names tenvT (Tvar tv)= 
  T)
/\
(check_type_names tenvT (Tapp ts tn)=  
 ((case tn of
     TC_name tn =>
       (case nsLookup tenvT tn of
           SOME (tvs, t) => LENGTH tvs = LENGTH ts
         | NONE => F
       )
   | _ => T
  ) /\
  EVERY (check_type_names tenvT) ts))
/\
(check_type_names tenvT (Tvar_db n)= 
  T)`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) check_type_names_defn;

(* Substitution of type names for the type they abbreviate *)
(*val type_name_subst : tenv_abbrev -> t -> t*)
 val type_name_subst_defn = Defn.Hol_multi_defns `

(type_name_subst tenvT (Tvar tv)=  (Tvar tv))
/\
(type_name_subst tenvT (Tapp ts tc)=  
 (let args = (MAP (type_name_subst tenvT) ts) in
    (case tc of
        TC_name tn =>
          (case nsLookup tenvT tn of
              SOME (tvs, t) => type_subst (alist_to_fmap (ZIP (tvs, args))) t
            | NONE => Tapp args tc
          )
      | _ => Tapp args tc
    )))
/\
(type_name_subst tenvT (Tvar_db n)=  (Tvar_db n))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) type_name_subst_defn;

(* Check that a type definition defines no already defined types or duplicate
 * constructors, and that the free type variables of each constructor argument
 * type are included in the type's type parameters. Also check that all of the
 * types mentioned are in scope. *)
(*val check_ctor_tenv : tenv_abbrev -> list (list tvarN * typeN * list (conN * list t)) -> bool*)
val _ = Define `
 (check_ctor_tenv tenvT tds=  
 (check_dup_ctors tds /\
  EVERY
    (\ (tvs,tn,ctors) . 
       ALL_DISTINCT tvs /\
       EVERY
         (\ (cn,ts) .  EVERY (check_freevars(( 0 : num)) tvs) ts /\ EVERY (check_type_names tenvT) ts)
         ctors)
    tds /\
  ALL_DISTINCT (MAP (\p .  
  (case (p ) of ( (_,tn,_) ) => tn )) tds)))`;


(*val build_ctor_tenv : list modN -> tenv_abbrev -> list (list tvarN * typeN * list (conN * list t)) -> tenv_ctor*)
val _ = Define `
 (build_ctor_tenv mn tenvT tds=  
 (alist_to_ns
    (REVERSE
      (FLAT
        (MAP
           (\ (tvs,tn,ctors) . 
              MAP (\ (cn,ts) .  (cn,(tvs,MAP (type_name_subst tenvT) ts, TypeId (mk_id mn tn)))) ctors)
           tds)))))`;


(* Check that an exception definition defines no already defined (or duplicate)
 * constructors, and that the arguments have no free type variables. *)
(*val check_exn_tenv : list modN -> conN -> list t -> bool*)
val _ = Define `
 (check_exn_tenv mn cn ts=  
 (EVERY (check_freevars(( 0 : num)) []) ts))`;


(* For the value restriction on let-based polymorphism *)
(*val is_value : exp -> bool*)
 val is_value_defn = Defn.Hol_multi_defns `

(is_value (Lit _)=  T)
/\
(is_value (Con _ es)=  (EVERY is_value es))
/\
(is_value (Var _)=  T)
/\
(is_value (Fun _ _)=  T)
/\
(is_value (Tannot e _)=  (is_value e))
/\
(is_value (Lannot e _)=  (is_value e))
/\
(is_value _=  F)`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) (List.map Defn.save_defn) is_value_defn;

(*val tid_exn_to_tc : tid_or_exn -> tctor*)
val _ = Define `
 (tid_exn_to_tc t=  
 ((case t of
      TypeId tid => TC_name tid
    | TypeExn _ => TC_exn
  )))`;


val _ = Hol_reln ` (! tvs tenv t.
(check_freevars tvs [] t)
==>
type_p tvs tenv Pany t [])

/\ (! tvs tenv n t.
(check_freevars tvs [] t)
==>
type_p tvs tenv (Pvar n) t [(n,t)])

/\ (! tvs tenv n.
T
==>
type_p tvs tenv (Plit (IntLit n)) Tint [])

/\ (! tvs tenv c.
T
==>
type_p tvs tenv (Plit (Char c)) Tchar [])

/\ (! tvs tenv s.
T
==>
type_p tvs tenv (Plit (StrLit s)) Tstring [])

/\ (! tvs tenv w.
T
==>
type_p tvs tenv (Plit (Word8 w)) Tword8 [])

/\ (! tvs tenv w.
T
==>
type_p tvs tenv (Plit (Word64 w)) Tword64 [])

/\ (! tvs tenv cn ps ts tvs' tn ts' bindings.
(EVERY (check_freevars tvs []) ts' /\
(LENGTH ts' = LENGTH tvs') /\
type_ps tvs tenv ps (MAP (type_subst (alist_to_fmap (ZIP (tvs', ts')))) ts) bindings /\
(nsLookup tenv.c cn = SOME (tvs', ts, tn)))
==>
type_p tvs tenv (Pcon (SOME cn) ps) (Tapp ts' (tid_exn_to_tc tn)) bindings)

/\ (! tvs tenv ps ts bindings.
(type_ps tvs tenv ps ts bindings)
==>
type_p tvs tenv (Pcon NONE ps) (Tapp ts TC_tup) bindings)

/\ (! tvs tenv p t bindings.
(type_p tvs tenv p t bindings)
==>
type_p tvs tenv (Pref p) (Tref t) bindings)

/\ (! tvs tenv p t bindings.
(check_freevars(( 0 : num)) [] t /\
check_type_names tenv.t t /\
type_p tvs tenv p (type_name_subst tenv.t t) bindings)
==>
type_p tvs tenv (Ptannot p t) (type_name_subst tenv.t t) bindings)

/\ (! tvs tenv.
T
==>
type_ps tvs tenv [] [] [])

/\ (! tvs tenv p ps t ts bindings bindings'.
(type_p tvs tenv p t bindings /\
type_ps tvs tenv ps ts bindings')
==>
type_ps tvs tenv (p::ps) (t::ts) (bindings'++bindings))`;

val _ = Hol_reln ` (! tenv tenvE n.
T
==>
type_e tenv tenvE (Lit (IntLit n)) Tint)

/\ (! tenv tenvE c.
T
==>
type_e tenv tenvE (Lit (Char c)) Tchar)

/\ (! tenv tenvE s.
T
==>
type_e tenv tenvE (Lit (StrLit s)) Tstring)

/\ (! tenv tenvE w.
T
==>
type_e tenv tenvE (Lit (Word8 w)) Tword8)

/\ (! tenv tenvE w.
T
==>
type_e tenv tenvE (Lit (Word64 w)) Tword64)

/\ (! tenv tenvE e t.
(check_freevars (num_tvs tenvE) [] t /\
type_e tenv tenvE e Texn)
==>
type_e tenv tenvE (Raise e) t)


/\ (! tenv tenvE e pes t.
(type_e tenv tenvE e t /\ ~ (pes = []) /\
(! ((p,e) :: LIST_TO_SET pes). ? bindings.
   ALL_DISTINCT (pat_bindings p []) /\
   type_p (num_tvs tenvE) tenv p Texn bindings /\
   type_e tenv (bind_var_list(( 0 : num)) bindings tenvE) e t))
==>
type_e tenv tenvE (Handle e pes) t)

/\ (! tenv tenvE cn es tvs tn ts' ts.
(EVERY (check_freevars (num_tvs tenvE) []) ts' /\
(LENGTH tvs = LENGTH ts') /\
type_es tenv tenvE es (MAP (type_subst (alist_to_fmap (ZIP (tvs, ts')))) ts) /\
(nsLookup tenv.c cn = SOME (tvs, ts, tn)))
==>
type_e tenv tenvE (Con (SOME cn) es) (Tapp ts' (tid_exn_to_tc tn)))

/\ (! tenv tenvE es ts.
(type_es tenv tenvE es ts)
==>
type_e tenv tenvE (Con NONE es) (Tapp ts TC_tup))

/\ (! tenv tenvE n t targs tvs.
((tvs = LENGTH targs) /\
EVERY (check_freevars (num_tvs tenvE) []) targs /\
(lookup_var n tenvE tenv = SOME (tvs,t)))
==>
type_e tenv tenvE (Var n) (deBruijn_subst(( 0 : num)) targs t))

/\ (! tenv tenvE n e t1 t2.
(check_freevars (num_tvs tenvE) [] t1 /\
type_e tenv (Bind_name n(( 0 : num)) t1 tenvE) e t2)
==>
type_e tenv tenvE (Fun n e) (Tfn t1 t2))

/\ (! tenv tenvE op es ts t.
(type_es tenv tenvE es ts /\
type_op op ts t /\
check_freevars (num_tvs tenvE) [] t)
==>
type_e tenv tenvE (App op es) t)

/\ (! tenv tenvE l e1 e2.
(type_e tenv tenvE e1 (Tapp [] (TC_name (Short "bool"))) /\
type_e tenv tenvE e2 (Tapp [] (TC_name (Short "bool"))))
==>
type_e tenv tenvE (Log l e1 e2) (Tapp [] (TC_name (Short "bool"))))

/\ (! tenv tenvE e1 e2 e3 t.
(type_e tenv tenvE e1 (Tapp [] (TC_name (Short "bool"))) /\
type_e tenv tenvE e2 t /\
type_e tenv tenvE e3 t)
==>
type_e tenv tenvE (If e1 e2 e3) t)

/\ (! tenv tenvE e pes t1 t2.
(type_e tenv tenvE e t1 /\ ~ (pes = []) /\
(! ((p,e) :: LIST_TO_SET pes) . ? bindings.
   ALL_DISTINCT (pat_bindings p []) /\
   type_p (num_tvs tenvE) tenv p t1 bindings /\
   type_e tenv (bind_var_list(( 0 : num)) bindings tenvE) e t2))
==>
type_e tenv tenvE (Mat e pes) t2)

/\ (! tenv tenvE n e1 e2 t1 t2.
(type_e tenv tenvE e1 t1 /\
type_e tenv (opt_bind_name n(( 0 : num)) t1 tenvE) e2 t2)
==>
type_e tenv tenvE (Let n e1 e2) t2)

(*
and

letrec : forall tenv tenvE funs e t tenv' tvs.
type_funs tenv (bind_var_list 0 tenv' (bind_tvar tvs tenvE)) funs tenv' &&
type_e tenv (bind_var_list tvs tenv' tenvE) e t
==>
type_e tenv tenvE (Letrec funs e) t
*)

/\ (! tenv tenvE funs e t bindings.
(type_funs tenv (bind_var_list(( 0 : num)) bindings tenvE) funs bindings /\
type_e tenv (bind_var_list(( 0 : num)) bindings tenvE) e t)
==>
type_e tenv tenvE (Letrec funs e) t)

/\ (! tenv tenvE e t.
(check_freevars(( 0 : num)) [] t /\
check_type_names tenv.t t /\
type_e tenv tenvE e (type_name_subst tenv.t t))
==>
type_e tenv tenvE (Tannot e t) (type_name_subst tenv.t t))

/\ (! tenv tenvE e l t.
(type_e tenv tenvE e t)
==>
type_e tenv tenvE (Lannot e l) t)

/\ (! tenv tenvE.
T
==>
type_es tenv tenvE [] [])

/\ (! tenv tenvE e es t ts.
(type_e tenv tenvE e t /\
type_es tenv tenvE es ts)
==>
type_es tenv tenvE (e::es) (t::ts))

/\ (! tenv tenvE.
T
==>
type_funs tenv tenvE [] [])

/\ (! tenv tenvE fn n e funs bindings t1 t2.
(check_freevars (num_tvs tenvE) [] (Tfn t1 t2) /\
type_e tenv (Bind_name n(( 0 : num)) t1 tenvE) e t2 /\
type_funs tenv tenvE funs bindings /\
(ALOOKUP bindings fn = NONE))
==>
type_funs tenv tenvE ((fn, n, e)::funs) ((fn, Tfn t1 t2)::bindings))`;

(*val tenv_add_tvs : nat -> alist varN t -> alist varN (nat * t)*)
val _ = Define `
 (tenv_add_tvs tvs bindings=  
 (MAP (\ (n,t) .  (n,(tvs,t))) bindings))`;


(*val type_pe_determ : type_env -> tenv_val_exp -> pat -> exp -> bool*)
val _ = Define `
 (type_pe_determ tenv tenvE p e=  
 (! t1 tenv1 t2 tenv2.    
(type_p(( 0 : num)) tenv p t1 tenv1 /\ type_e tenv tenvE e t1 /\
    type_p(( 0 : num)) tenv p t2 tenv2 /\ type_e tenv tenvE e t2)
    ==>    
(tenv1 = tenv2)))`;


(*val tscheme_inst : (nat * t) -> (nat * t) -> bool*)
val _ = Define `
 (tscheme_inst (tvs_spec, t_spec) (tvs_impl, t_impl)=  
 (? subst.    
(LENGTH subst = tvs_impl) /\
    check_freevars tvs_impl [] t_impl /\
    EVERY (check_freevars tvs_spec []) subst /\    
(deBruijn_subst(( 0 : num)) subst t_impl = t_spec)))`;


val _ = Hol_reln ` (! extra_checks tvs mn tenv p e t bindings decls locs.
(is_value e /\
ALL_DISTINCT (pat_bindings p []) /\
type_p tvs tenv p t bindings /\
type_e tenv (bind_tvar tvs Empty) e t /\
(extra_checks ==>  
(! tvs' bindings' t'.    
(type_p tvs' tenv p t' bindings' /\
    type_e tenv (bind_tvar tvs' Empty) e t') ==>
      EVERY2 tscheme_inst (MAP SND (tenv_add_tvs tvs' bindings')) (MAP SND (tenv_add_tvs tvs bindings)))))
==>
type_d extra_checks mn decls tenv (Dlet locs p e)
  empty_decls <| v := (alist_to_ns (tenv_add_tvs tvs bindings)); c := nsEmpty; t := nsEmpty |>)

/\ (! extra_checks mn tenv p e t bindings decls locs.
(
(* The following line makes sure that when the value restriction prohibits
   generalisation, a type error is given rather than picking an arbitrary
   instantiation. However, we should only do the check when the extra_checks
   argument tells us to. *)(extra_checks ==> (~ (is_value e) /\ type_pe_determ tenv Empty p e)) /\
ALL_DISTINCT (pat_bindings p []) /\
type_p(( 0 : num)) tenv p t bindings /\
type_e tenv Empty e t)
==>
type_d extra_checks mn decls tenv (Dlet locs p e)
  empty_decls <| v := (alist_to_ns (tenv_add_tvs(( 0 : num)) bindings)); c := nsEmpty; t := nsEmpty |>)

/\ (! extra_checks mn tenv funs bindings tvs decls locs.
(type_funs tenv (bind_var_list(( 0 : num)) bindings (bind_tvar tvs Empty)) funs bindings /\
(extra_checks ==>  
(! tvs' bindings'.
    type_funs tenv (bind_var_list(( 0 : num)) bindings' (bind_tvar tvs' Empty)) funs bindings' ==>
      EVERY2 tscheme_inst (MAP SND (tenv_add_tvs tvs' bindings')) (MAP SND (tenv_add_tvs tvs bindings)))))
==>
type_d extra_checks mn decls tenv (Dletrec locs funs)
  empty_decls <| v := (alist_to_ns (tenv_add_tvs tvs bindings)); c := nsEmpty; t := nsEmpty |>)

/\ (! extra_checks mn tenv tdefs decls defined_types' decls' tenvT locs.
(check_ctor_tenv (nsAppend tenvT tenv.t) tdefs /\
(defined_types' = LIST_TO_SET (MAP (\ (tvs,tn,ctors) .  (mk_id mn tn)) tdefs)) /\
DISJOINT defined_types' decls.defined_types /\
(tenvT = alist_to_ns (MAP (\ (tvs,tn,ctors) .  (tn, (tvs, Tapp (MAP Tvar tvs) (TC_name (mk_id mn tn))))) tdefs)) /\
(decls' = <| defined_mods := ({}); defined_types := defined_types'; defined_exns := ({}) |>))
==>
type_d extra_checks mn decls tenv (Dtype locs tdefs)
  decls' <| v := nsEmpty; c := (build_ctor_tenv mn (nsAppend tenvT tenv.t) tdefs); t := tenvT |>)

/\ (! extra_checks mn decls tenv tvs tn t locs.
(check_freevars(( 0 : num)) tvs t /\
check_type_names tenv.t t /\
ALL_DISTINCT tvs)
==>
type_d extra_checks mn decls tenv (Dtabbrev locs tvs tn t)
  empty_decls <| v := nsEmpty; c := nsEmpty;
                 t := (nsSing tn (tvs,type_name_subst tenv.t t)) |>)

/\ (! extra_checks mn tenv cn ts decls decls' locs.
(check_exn_tenv mn cn ts /\
~ (mk_id mn cn IN decls.defined_exns) /\
EVERY (check_type_names tenv.t) ts /\
(decls' = <| defined_mods := ({}); defined_types := ({}); defined_exns := ({mk_id mn cn}) |>))
==>
type_d extra_checks mn decls tenv (Dexn locs cn ts)
  decls' <| v := nsEmpty;
            c := (nsSing cn ([], MAP (type_name_subst tenv.t) ts, TypeExn (mk_id mn cn)));
            t := nsEmpty |>)`;

val _ = Hol_reln ` (! extra_checks mn tenv decls.
T
==>
type_ds extra_checks mn decls tenv []
  empty_decls <| v := nsEmpty; c := nsEmpty; t := nsEmpty |>)

/\ (! extra_checks mn tenv d ds tenv1 tenv2 decls decls1 decls2.
(type_d extra_checks mn decls tenv d decls1 tenv1 /\
type_ds extra_checks mn (union_decls decls1 decls) (extend_dec_tenv tenv1 tenv) ds decls2 tenv2)
==>
type_ds extra_checks mn decls tenv (d::ds)
  (union_decls decls2 decls1) (extend_dec_tenv tenv2 tenv1))`;

val _ = Hol_reln ` (! mn tenvT.
T
==>
type_specs mn tenvT []
  empty_decls <| v := nsEmpty; c := nsEmpty; t := nsEmpty |>)

/\ (! mn tenvT x t specs tenv fvs decls subst.
(check_freevars(( 0 : num)) fvs t /\
check_type_names tenvT t /\
type_specs mn tenvT specs decls tenv /\
(subst = alist_to_fmap (ZIP (fvs, (MAP Tvar_db (GENLIST (\ x .  x) (LENGTH fvs)))))))
==>
type_specs mn tenvT (Sval x t :: specs)
  decls
  (extend_dec_tenv tenv
    <| v := (nsSing x (LENGTH fvs, type_subst subst (type_name_subst tenvT t)));
       c := nsEmpty;
       t := nsEmpty |>))

/\ (! mn tenvT tenv td specs decls' decls tenvT'.
((tenvT' = alist_to_ns (MAP (\ (tvs,tn,ctors) .  (tn, (tvs, Tapp (MAP Tvar tvs) (TC_name (mk_id mn tn))))) td)) /\
check_ctor_tenv (nsAppend tenvT' tenvT) td /\
type_specs mn (nsAppend tenvT' tenvT) specs decls tenv /\
(decls' = <| defined_mods := ({});
            defined_types := (LIST_TO_SET (MAP (\ (tvs,tn,ctors) .  (mk_id mn tn)) td));
            defined_exns := ({}) |>))
==>
type_specs mn tenvT (Stype td :: specs)
  (union_decls decls decls')
  (extend_dec_tenv tenv
   <| v := nsEmpty;
      c := (build_ctor_tenv mn (nsAppend tenvT' tenvT) td);
      t := tenvT' |>))

/\ (! mn tenvT tenvT' tvs tn t specs decls tenv.
(ALL_DISTINCT tvs /\
check_freevars(( 0 : num)) tvs t /\
check_type_names tenvT t /\
(tenvT' = nsSing tn (tvs,type_name_subst tenvT t)) /\
type_specs mn (nsAppend tenvT' tenvT) specs decls tenv)
==>
type_specs mn tenvT (Stabbrev tvs tn t :: specs)
  decls (extend_dec_tenv tenv <| v := nsEmpty; c := nsEmpty; t := tenvT' |>))

/\ (! mn tenvT tenv cn ts specs decls.
(check_exn_tenv mn cn ts /\
type_specs mn tenvT specs decls tenv /\
EVERY (check_type_names tenvT) ts)
==>
type_specs mn tenvT (Sexn cn ts :: specs)
  (union_decls decls <| defined_mods := ({}); defined_types := ({}); defined_exns := ({mk_id mn cn}) |>)
  (extend_dec_tenv tenv
   <| v := nsEmpty;
      c := (nsSing cn ([], MAP (type_name_subst tenvT) ts, TypeExn (mk_id mn cn)));
      t := nsEmpty |>))

/\ (! mn tenvT tenv tn specs tvs decls tenvT'.
(ALL_DISTINCT tvs /\
(tenvT' = nsSing tn (tvs, Tapp (MAP Tvar tvs) (TC_name (mk_id mn tn)))) /\
type_specs mn (nsAppend tenvT' tenvT) specs decls tenv)
==>
type_specs mn tenvT (Stype_opq tvs tn :: specs)
  (union_decls decls <| defined_mods := ({}); defined_types := ({mk_id mn tn}); defined_exns := ({}) |>)
  (extend_dec_tenv tenv <| v := nsEmpty; c := nsEmpty; t := tenvT' |>))`;

(*val weak_decls : decls -> decls -> bool*)
val _ = Define `
 (weak_decls decls_impl decls_spec=
   ((decls_impl.defined_mods = decls_spec.defined_mods) /\  
(decls_spec.defined_types SUBSET decls_impl.defined_types) /\  
(decls_spec.defined_exns SUBSET decls_impl.defined_exns)))`;


(*val weak_tenvT : id modN typeN -> (list tvarN * t) -> (list tvarN * t) -> bool*)
val _ = Define `
 (weak_tenvT n (tvs_spec, t_spec) (tvs_impl, t_impl)=
   ((
  (* For simplicity, we reject matches that differ only by renaming of bound type variables *)tvs_spec = tvs_impl) /\
  ((t_spec = t_impl) \/   
(
   (* The specified type is opaque *)t_spec = Tapp (MAP Tvar tvs_spec) (TC_name n)))))`;


val _ = Define `
 (tscheme_inst2 _ ts1 ts2=  (tscheme_inst ts1 ts2))`;


(*val weak_tenv : type_env -> type_env -> bool*)
val _ = Define `
 (weak_tenv tenv_impl tenv_spec=  
 (nsSub tscheme_inst2 tenv_spec.v tenv_impl.v /\
  nsSub (\i x y .  (case (i ,x ,y ) of ( _ , x , y ) => x = y )) tenv_spec.c tenv_impl.c /\
  nsSub weak_tenvT tenv_spec.t tenv_impl.t))`;


val _ = Hol_reln ` (! mn tenvT decls tenv.
T
==>
check_signature mn tenvT decls tenv NONE decls tenv)

/\ (! mn specs tenv_impl tenv_spec decls_impl decls_spec tenvT.
(weak_tenv tenv_impl tenv_spec /\
weak_decls decls_impl decls_spec /\
type_specs mn tenvT specs decls_spec tenv_spec)
==>
check_signature mn tenvT decls_impl tenv_impl (SOME specs) decls_spec tenv_spec)`;

val _ = Define `
 (tenvLift mn tenv=  
 (<| v := (nsLift mn tenv.v); c := (nsLift mn tenv.c); t := (nsLift mn tenv.t)  |>))`;


val _ = Hol_reln ` (! extra_checks tenv d tenv' decls decls'.
(type_d extra_checks [] decls tenv d decls' tenv')
==>
type_top extra_checks decls tenv (Tdec d) decls' tenv')

/\ (! extra_checks tenv mn spec ds tenv_impl tenv_spec decls decls_impl decls_spec.
(~ ([mn] IN decls.defined_mods) /\
type_ds extra_checks [mn] decls tenv ds decls_impl tenv_impl /\
check_signature [mn] tenv.t decls_impl tenv_impl spec decls_spec tenv_spec)
==>
type_top extra_checks decls tenv (Tmod mn spec ds)
  (union_decls <| defined_mods := ({[mn]}); defined_types := ({}); defined_exns := ({}) |> decls_spec)
  (tenvLift mn tenv_spec))`;

val _ = Hol_reln ` (! extra_checks tenv decls.
T
==>
type_prog extra_checks decls tenv [] empty_decls <| v := nsEmpty; c := nsEmpty; t := nsEmpty |>)

/\ (! extra_checks tenv top tops tenv1 tenv2 decls decls1 decls2.
(type_top extra_checks decls tenv top decls1 tenv1 /\
type_prog extra_checks (union_decls decls1 decls) (extend_dec_tenv tenv1 tenv) tops decls2 tenv2)
==>
type_prog extra_checks decls tenv (top :: tops)
  (union_decls decls2 decls1) (extend_dec_tenv tenv2 tenv1))`;
val _ = export_theory()

