(*
  Compilation from timeLang to panLang
*)
open preamble pan_commonTheory
     timeLangTheory panLangTheory

val _ = new_theory "time_to_pan"

val _ = set_grammar_ancestry ["pan_common", "timeLang", "panLang"];


Datatype:
  context =
  <| funcs     : timeLang$loc    |-> panLang$funname;
     ext_funcs : timeLang$effect |-> panLang$funname
  |>
End

Definition real_to_word_def:
  (real_to_word (t:real) = (ARB t): 'a word)
End

Definition comp_exp_def:
  (comp_exp (ELit time) = Const (real_to_word time)) ∧
  (comp_exp (EClock (CVar clock)) = Var (strlit clock)) ∧
  (comp_exp (ESub e1 e2) = Op Sub [comp_exp e1; comp_exp e2])
End

(* ≤ is missing in the cmp datatype *)

Definition comp_condition_def:
  (comp_condition (CndLe e1 e2) =
    Cmp Less (comp_exp e1) (comp_exp e2)) ∧
  (comp_condition (CndLt e1 e2) =
    Cmp Less (comp_exp e1) (comp_exp e2))
End

Definition conditions_of_def:
  (conditions_of (Tm _ cs _ _ _) = cs)
End

Definition comp_conditions_def:
  (comp_conditions [] = Const 1w) ∧
  (* generating true for the time being *)
  (comp_conditions cs = Op And (MAP comp_condition cs))
End

(* provide a value to be reseted at, for the time being *)
Definition set_clks_def:
  (set_clks [] n = Skip) ∧
  (set_clks (CVar c::cs) n = Seq (Assign (strlit c) (Const n))
                                 (set_clks cs n))
End

(* does order matter here *)
Definition comp_step_def:
  comp_step ctxt cval loc_var wt_var
  (Tm io cnds clks loc wt) =
  case FLOOKUP ctxt.funcs loc of
  | NONE => Skip
  | SOME fname =>
      Seq (set_clks clks cval)
          (Seq (Store loc_var (Label fname))
               (Seq (Store wt_var (ARB wt))
                     (case io of
                      | (Input act)  => Skip
                      | (Output eff) =>
                          case FLOOKUP ctxt.ext_funcs eff of
                          | NONE => Skip
                          | SOME efname => ExtCall efname ARB ARB ARB ARB)))
End

Definition comp_terms_def:
  (comp_terms ctxt cval loc_var wt_var [] = Skip) ∧
  (comp_terms ctxt cval loc_var wt_var (t::ts) =
   If (comp_conditions (conditions_of t))
        (comp_step ctxt cval loc_var wt_var t)
        (comp_terms ctxt cval loc_var wt_var ts))
End

Definition comp_location_def:
  comp_location ctxt cval loc_var wt_var (loc, ts) =
   case FLOOKUP ctxt.funcs loc of
   | SOME fname => (fname, [], comp_terms ctxt cval loc_var wt_var ts)
   | NONE => (strlit "", [], Skip)
End


Definition comp_prog_def:
  (comp_prog ctxt ctxt cval loc_var wt_var [] = []) ∧
  (comp_prog ctxt ctxt cval loc_var wt_var (p::ps) =
   comp_location ctxt cval loc_var wt_var p ::
   comp_prog ctxt ctxt cval loc_var wt_var ps)
End




(*
Definition compile_term:
  compile_term
    (Tm io cs reset_clocks next_location wait_time) =
     If (compile_conditions cs)
     (compile_step (Input action) location_var location clks waitad waitval)
     (* take step, do the action, goto the next location *)
     Skip (* stay in the same state, maybe *)
End
*)

(* what does it mean conceptually if a state has more than
   one transitions *)
(* to understand how wait time is modeled in the formalism *)

(* keep going in the same direction *)



(*
Type program = ``:(loc # term list) list``
*)


val _ = export_theory();
