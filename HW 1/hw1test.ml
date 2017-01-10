let my_subset_test0 = subset [] []
let my_subset_test1 = not (subset [1;2;3] [4;5;6;1;2])
let my_subset_test2 = subset [1] [12; 13; 1; 14]

let my_equal_sets_test0 = equal_sets [42; 34; 55] [55; 42; 34; 55]
let my_equal_sets_test1 = not (equal_sets [1;4;7] [2;5;8])

let my_set_union_test0 = equal_sets (set_union [1;3;5;7] [2;4;6;8]) [1;2;3;4;5;6;7;8]
let my_set_union_test1 = equal_sets (set_union [1;1;1;1;1] [2;2;2;2;2]) [1;2]
let my_set_union_test2 = equal_sets (set_union [2] [3]) [2;3]

let my_set_intersection_test0 = equal_sets (set_intersection [2;5;9] [1;4;10]) [] 
let my_set_intersection_test1 = equal_sets (set_intersection [1;2;3] [2;3;4;5]) [2;3]
let my_set_intersection_test2 = equal_sets (set_intersection [1;1;2;2] [2;3;2;6;1]) [1;2]

let my_set_diff_test0 = equal_sets (set_diff [1;5] [5;1;5]) []
let my_set_diff_test1 = equal_sets (set_diff [6;7] [1;2;3;4]) [6;7]
let my_set_diff_test2 = equal_sets (set_diff [1;1;2] [1;3]) [2]
let my_set_diff_test3 = equal_sets (set_diff [] [1;9;10;3]) []

let my_computed_fixed_point_test0 = computed_fixed_point (=) (fun x -> x *. 2.) 100. = infinity
let my_computed_fixed_point_test1 = computed_fixed_point (=) (fun x -> x mod 3) 81 = 0
let my_computed_fixed_point_test2 = computed_fixed_point (=) (fun x -> x) 10000000 = 10000000

let my_computed_periodic_point_test0 = computed_periodic_point (=) (fun x -> x mod 2) 1 40 = computed_fixed_point (=) (fun x -> x mod 2) 40
let my_computed_periodic_point_test1 = computed_periodic_point (fun x y -> x <= y) (fun x -> x + 5) 4 10 = 10

let my_while_away_test0 = while_away ((+) 3) ((>) 10) 0 = [0; 3; 6; 9]
let my_while_away_test1 = while_away ((-) 20) ((<) 80) 100 = [100]
let my_while_away_test2 = while_away ((/) 2) ((<=) 6) 4 = []

let my_rle_decode_test0 = rle_decode [2,0; 1,6] = [0; 0; 6]
let my_rle_decode_test1 = rle_decode [3,"w"; 1,"x"; 0,"y"; 2,"z"] = ["w"; "w"; "w"; "x"; "z"; "z"]
let my_rle_decode_test2 = rle_decode [1, "u"; 1, "c"; 1, "l"; 2, "a"] = ["u"; "c"; "l"; "a"; "a"]
let my_rle_decode_test3 = rle_decode [3, 9; 0, 100; 1, 10] = [9; 9; 9; 10]

type non_terminals =
  | Process | Threads | Descriptors | Pages | Memory

let grammar = 
    [ 
      Descriptors, [N Descriptors; T "sockets"];
      Descriptors, [T "private"; N Descriptors];
      Process, [N Pages];
      Process, [N Memory; T "virtualization"];
      Threads, [T "lightweight"];
      Threads, [T "threadstack"; N Process];
      Pages, [N Process; T "swapping"];
      Pages, [N Threads; N Memory];
      Memory, [T "dram"; T "sram"];
      Memory, [N Process; N Threads; N Pages];
    ]
let grammar_test0 = Process, List.tl (List.tl (grammar))
let grammar_test1 = Threads, grammar
let grammar_test2 = Memory, List.tl (List.tl (List.rev grammar))

let my_filter_blind_alleys_test0 = filter_blind_alleys grammar_test0 = grammar_test0
let my_filter_blind_alleys_test1 = filter_blind_alleys grammar_test1 = (Threads,
   [(Process, [N Pages]); (Process, [N Memory; T "virtualization"]);
    (Threads, [T "lightweight"]); (Threads, [T "threadstack"; N Process]);
    (Pages, [N Process; T "swapping"]); (Pages, [N Threads; N Memory]);
    (Memory, [T "dram"; T "sram"]);
    (Memory, [N Process; N Threads; N Pages])])
let my_filter_blind_alleys_test1 = filter_blind_alleys grammar_test2 = (Memory, [(Threads, [T "lightweight"])])

