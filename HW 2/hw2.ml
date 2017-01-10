type ('terminal, 'nonterminal) symbol =
    | T of 'terminal
    | N of 'nonterminal
(*
 * The function receives a tuple of nonterminal and list of rules, where we want to match
 * the nonterminal from the production function to the nonterminal in each rule and append
 * to our alternative list the rhs for said function.
 * *)
let convert_grammar gram1 =
    let rec alternate_lists nt rules = match rules with
    [] -> []
    | (non_term_sym, rhs)::t -> if nt = non_term_sym then rhs::(alternate_lists nt t) else alternate_lists nt t in
    ((fst gram1), fun nt -> (alternate_lists nt (snd gram1)));;

(*
 * The parse prefix returns a derivation using a curried matcher function that takes in the acceptor that determines
 * what elements to put in the prefix. The matcher looks through all the rules in the given grammar and uses
 * the match_element to compare each element recursively until we find the fragment element in the rules with the 
 * start symbol or ends the prefix, and just returns the suffix along with the derivation that constantly gets 
 * appended to. For more information read the hw2.txt.
 *)

let parse_prefix gram accept frag =
    let rec match_element rules rule accept derivation frag = match rule with
        | [] -> accept derivation frag
        | _ -> match frag with
            | [] -> None
            | curr_prefix::r_frag -> match rule with
                | [] -> None
                | (T term)::rhs -> if curr_prefix = term then (match_element rules rhs accept derivation r_frag) else None
                | (N nterm)::rhs -> (matcher nterm rules (rules nterm) (match_element rules rhs accept) derivation frag)
    and matcher start rules matching_start_rules accept derivation frag = match matching_start_rules with
        | [] -> None
        | top_rule::other_rules -> match (match_element rules top_rule accept (derivation@[start, top_rule]) frag) with
            | None -> matcher start rules other_rules accept derivation frag
            | Some res -> Some res in
    matcher (fst gram) (snd gram) ((snd gram) (fst gram)) accept [] frag
