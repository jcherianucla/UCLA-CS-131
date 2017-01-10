(*Use exists to check if the current element (h) is in b in which case we run a further
 * recursive subset, else we return false*)
let rec subset a b = match a with
    [] -> true
    | h::t -> if List.exists (fun x -> x = h) b then subset t b else false;;

(*If the two lists are both subsets of each other then they are by definition equal*)
let equal_sets a b = subset a b && subset b a;;

(*If the element is in both lists then ignore it by excluding it in the parameter, else 
 * else include that element*)
let rec set_union a b = match a with
    [] -> b
    | h::t -> if List.exists (fun x -> x = h) b then set_union t b else set_union t (h::b);;

(*Filter b by finding all the elements that also exist in a *)
let set_intersection a b = List.filter (fun x -> List.exists (fun elem -> elem = x) a) b;;

(*Filter a by finaing all the elements in b that are not equal to the current element in a *)
let set_diff a b = List.filter (fun x -> List.for_all (fun elem -> elem <> x) b) a;;

(* See if the computed point exists with the current function and x else recurse deeper applying the function on x *)
let rec computed_fixed_point eq f x = if eq (f x) x then x else computed_fixed_point eq f (f x)

(* Use a helper to store the current periodic function to be able to maintain the period between the points *)
let rec computed_periodic_point eq f p x = 
    let rec help eq f p x fx = match p with
        0 -> if eq x fx then x else help eq f p (f x) (f fx)
        | _ -> help eq f (p-1) x (f fx) in
    help eq f p x x;;

(* If p x succeeds then just recurse with s x else empty list *)
let rec while_away s p x = if (p x) then x::while_away s p (s x) else [];;

(* if the number of ocurrences is 0 then discard the value else append the value and recurse for num-1 times *)
let rec rle_decode lp = match lp with
    [] -> []
    | (num, value)::t -> if num = 0 then rle_decode(t) else value::rle_decode ((num-1,value)::t);;

type ('nonterminal, 'terminal) symbol =
    | N of 'nonterminal
    | T of 'terminal

let filter_blind_alleys g =
    (* Checks to see if the symbol exists as a nonterminal value in the list of terminal rules *)
    let sym_exist symbol terminal_rhs = match symbol with
        T symbol -> true
        | N symbol -> if List.exists (fun x -> (fst x) = symbol) terminal_rhs then true else false in
    (* Confirms that all the symbols in the current rhs exist in the terminal rhs *)
    let rec verify_existence rhs terminal_rhs = match rhs with
        [] -> true
        | symbol::t -> if (sym_exist symbol terminal_rhs) then true && (verify_existence t terminal_rhs) else false in
    (* Creates the terminal_rhs by appending the rules only if the verification for the rule passes and the rule doesn't already exist in the terminal rhs *)
    let rec create_terminal_rhs rules terminal_rhs = match rules with
        [] -> terminal_rhs
        | rule::t -> if (verify_existence (snd rule) terminal_rhs) && (not (subset [rule] terminal_rhs)) then create_terminal_rhs t (rule::terminal_rhs) else (create_terminal_rhs t terminal_rhs) in
    (* Filter out all the non terminal rules from the original rules to maintain order, and apply computed_fixed_point to run for all N by optimizing to stop when we no longer add any rules *)
    (fst g, List.filter (fun x -> List.exists (fun e -> e = x) (computed_fixed_point (=) (create_terminal_rhs (snd g)) [])) (snd g));;
