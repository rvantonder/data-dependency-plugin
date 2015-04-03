open Core_kernel.Std
open Bap_bil
open Bap.Std
open Program_visitor

(* Data (Flow) Dependence
 *
 * Formal Definition: 
 * Let X and Y be nodes in a CFG. There is a data dependence from X to Y with
 * respect to a variable v iff there is a non-null path p from X to Y with no
 * intervening definition of v and:
 * X contains a definition of v and Y a use of v;
*)

(* for the instruction at a given index [i] of basic block [b], return its
 * direct data dependencies *)

(* this is only for direct data dependencies of a single block*)

module Depgraph = struct
  type t = project
  module V = struct
    type t = string
  end
  module E = struct
    type t = string * string
    let src = fst
    let dst = snd
  end


  (* returns the string representation of a stmt at a given index [i] 
   * of bil [stmts] *)
  let get_stmt stmts i =
    let r = 
      Bil.fold ~init:(0, "") (object inherit [int * string] Bil.visitor
        method! enter_stmt stmt (index,result) =
          if index = i then 
            (index, sprintf "%s" @@ Stmt.to_string stmt)
          else
            (index, result)

        method! leave_stmt stmt (index, result) =
          (index+1, result)
      end) stmts in 
    snd r

  let print_disasm disas =
    let indices = List.range 0 (List.length disas)
    in List.iteri indices ~f:(fun i x -> 
      Format.printf "%d: %s\n" i @@ get_stmt disas x)

  (* Given a starting index [start] and operand [op], return:
    * 1) the first definition of this [op] OR
    * 2) if [op] is of type mem, in which case return all definitions of op *)
  (* This is a linear sweep *)
  let operand_defs op start succs =
    Bil.fold ~init:(start, []) (object inherit [int * int list] Bil.visitor
      (* We keep track of the statement index for all statements *)
      method! leave_stmt _ (index, result) =
        (index+1, result) (* increment post statement *)

      (* We only care about move instructions *)
      method! enter_move var exp (index, result) =
        (* Think of var as the lhs of an assignment, a definition of op *)
        if Var.(var = op) then 
          begin
            (* Verbose output
             * Format.printf "%d op: %s var: %s\n" 
             * (index+1) (Var.to_string op) (Var.to_string var); *)

            (* better way to test var against 'mem'? *)
            if (Var.name var) = "mem" then 
              (index, (index+1)::result) (* append it to list *)
            else 
              (* not mem, one element in list *)
              match result with
              | [] -> (index, [index+1]) (* first match *)
              | _ -> (index, result) (* subsequent matches are ignored *)
          end
        else
          (index, result)
    end) succs (* succs visitor state: all statements not visited yet *)

  (* For a given [start] index, return the indices of all statements
   * it is dependent on *)
  let get_deps stmts start =
    let state = 
      (* State represented as tuple--is there a better way? *)
      (* Tuple: (index, list of statements affect this one) *)
      Bil.fold ~init:(0, [])  (object inherit [int * int list] Bil.visitor
        (* We must visit each statement to get a correct index *)
        method! leave_stmt _ (i, l) =
          ((i+1), l) (* increment post statement *)

        method! enter_move var exp (i, l) =
          (* if the start index matches the current index *)
          if (i = start) then 
            (* for each use on the rhs, do a linear search forward (successors)
             * to get the statement corresponding to it
             * do visit_var for each operand in exp *)
            let operands = 
              (object inherit [Var.t list] Bil.visitor
                method! enter_var v ll =
                  v::ll
              end)#visit_exp exp [] in (* visit only expressions *)
            let all_defs = List.map ~f:(fun x -> operand_defs x start succs)
                operands in
            let deflist = List.concat List.(all_defs >>| snd) in
            (i, List.append l deflist);
          else (i, l)
      end) stmts in 
    snd state

  (* Gets the dependency chain for a given statement at index [start] *)
  (* Note on efficiency: this can generate duplicates (which are removed) since
   * we repeat the linear search for each statement in the block.  We *could*
   * build a table for each statement's dependencies,but really this is fine
   * for now. *)
  let get_dep_chain stmts start =
    let rec dc stmts start acc =
      let res = get_deps stmts start in
      match res with 
      | [] ->  acc
      | l -> 
        List.fold l ~init:(List.append l acc) ~f:(fun acc x -> dc stmts x acc) in
    dc stmts start [] |> List.dedup

  (* TODO condense and improve *)
  let iter_vertex f t = 
    Table.iteri t.symbols ~f:(fun mem src ->
        if (src = "main") then
          let disasm = Seq.to_list (Disasm.insns_at_mem t.program mem) in
          let bil_disasm = List.fold disasm ~init:[] ~f:(fun acc (_mem, insn) ->
              (List.rev @@ Insn.bil insn)::acc) in
          let flat_bil_disasm = List.concat bil_disasm in
          List.iteri flat_bil_disasm ~f:(fun i s -> 
              f @@ sprintf "%d: %s" i @@ Stmt.to_string s))

  (* TODO condense and improve *)
  let iter_edges_e f t =
    Table.iteri t.symbols ~f:(fun mem src ->
        if (src = "main") then
          let disasm = Seq.to_list (Disasm.insns_at_mem t.program mem) in
          let bil_disasm = List.fold disasm ~init:[] ~f:(fun acc (_mem, insn) ->
              (List.rev @@ Insn.bil insn)::acc) in
          let flat_bil_disasm = List.concat bil_disasm in
          List.iteri flat_bil_disasm ~f:(fun i _ -> 
              let deps = get_deps flat_bil_disasm i in
              let mm = List.zip_exn deps @@ List.map deps ~f:(fun x -> 
                  get_stmt flat_bil_disasm x) in
              let root = sprintf "%d: %s" i @@ get_stmt flat_bil_disasm i in
              List.iter mm ~f:(fun (i,x) -> 
                  let node = sprintf "%d: %s" i x in
                  f (root, node))))

  let vertex_name v = sprintf "%S" v
  let vertex_attributes v = 
    (* TODO expose vertex to color through env var *)
    (* Hardcoded values for stack example *)
    if vertex_name v = "\"10: R1 := R3\"" || (* include the quotes *)
       vertex_name v = "\"11: R0 := R2\"" then 
      [`Style `Filled;`Fillcolor 0xff6600]
    else []
  let default_vertex_attributes _ = []
  let get_subgraph _ = None
  let default_edge_attributes _ = []
  let edge_attributes _ = []
  let graph_attributes _ = []
end


let main project = 
  (* Textual output *)
  Table.iteri project.symbols ~f:(fun mem src ->
      (* TODO expose function name as env var *)
      if (src = "main") then
        let disasm = Seq.to_list (Disasm.insns_at_mem project.program mem) in
        (* this will reverse the list. we actually want that. *)
        let bil_disasm = 
          List.fold disasm ~init:[] ~f:(fun acc (_mem, insn) ->
              (List.rev @@ Insn.bil insn)::acc) in
        let flat_bil_disasm = List.concat bil_disasm in
        Format.printf "START Disassembly:\n";
        Depgraph.print_disasm flat_bil_disasm;
        Format.printf "END Disassembly\n\n";
        Format.printf "START Dependency Chain:\n";
        let all_chains = 
            let indices = List.range 0 (List.length flat_bil_disasm) in
            List.fold indices ~init:[] ~f:(fun l x -> 
                (Depgraph.get_dep_chain flat_bil_disasm x)::l) in
          List.iteri (List.rev all_chains) (fun i x ->
              Format.printf "%d: %a\n" i Sexp.pp @@
              sexp_of_list sexp_of_int x); 
        Format.printf "END\n\n";
        ()
    );

  (* Table.iter project.symbols ~f:print_endline; *)

  (* Graph output (optional) *)
  let module Dot = Graph.Graphviz.Dot (Depgraph) in
  Out_channel.with_file "ddep.dot" ~f:(fun out -> Dot.output_graph out project);
  project

let () = register main
