(* Nonterminals defining key components of English Language *)
type english_nonterminals = 
    | S | NP | VP | Nn | V | D | PP | P

(* Acceptor taking in everything *)
let accept_all deriv str = Some(deriv, str)

(* Acceptor looking for only verbs *)
let rec contains_verb = function
    | [] -> false
    | (V,_)::_ -> true
    | _::rules -> contains_verb rules
let accept_only_verbs rules frag = if contains_verb rules then Some(rules, frag) else None

(* Grammar defining English rules *)
let english_grammar =
    (S, function
        | S -> [[N NP]; [N VP]]
        | NP -> [[N Nn]; [N D; N Nn]]
        | VP -> [[N V; N NP; N PP]; [N V; N PP]; [N V]]
        | Nn -> [[T"computers"]; [T"ucla"]; [T"major"]; [T "degree"]; [T"boelter"]; [T"eggert"]]
        | V -> [[T"graduated"]; [T"ran"]; [T"loved"]]
        | D -> [[T"the"]; [T"this"]; [T"which"]; [T"a"]; [T"any"]]
        | PP -> [[N P; N NP]]
        | P -> [[T"in"]; [T"with"]; [T"through"]]
    )

(*Test 1*)

let test_1 = parse_prefix english_grammar accept_all ["eggert"; "loved"; "computers";
             "in"; "the"; "degree"; "through"; "ucla"; "while"; "he"; "ran"; "in"; "boelter"] =
              Some ([(S, [N NP]); (NP, [N Nn]); (Nn, [T "eggert"])], ["loved"; "computers"; "in"; "the"; "degree"; "through"; "ucla"; "while";
                    "he"; "ran"; "in"; "boelter"])

(*Test 2*)

let test_2 = parse_prefix english_grammar accept_only_verbs ["graduated"; "coded"; "gamed"; "built"] =
    Some ([(S, [N VP]); (VP, [N V]); (V, [T "graduated"])],
           ["coded"; "gamed"; "built"])
