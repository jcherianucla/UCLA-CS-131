%%%%%%%%%%%%%%%%%%%%%%% Signal Morse %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Perform Run length encoding for the given list
run_encode([], []).
% A single item has only count of 1
run_encode([H], [[1, H]]).
% Only one encoding is necessary, so cut after generation so no more backtracking
% Keep counting on the next set of elements using succ to increment
run_encode([H | T], [[C, H] | Rest]):- run_encode(T, [[SC, H] | Rest]), succ(SC, C), !.
% Handle the case of moving from 1's to 0's to restart the run length
run_encode([H | T], [[1, H], [SC, X] | Rest]):- run_encode(T, [[SC, X] | Rest]), H \= X, !.

% Match all the valid cases in order from shortest to longest for ambiguous
is_valid([], []).
is_valid([[1,1] | T], ['.' | V]):- is_valid(T, V).
is_valid([[2,1] | T], ['.' | V]):- is_valid(T, V).
is_valid([[2,1] | T], ['-' | V]):- is_valid(T, V).
is_valid([[3,1] | T], ['-' | V]):- is_valid(T, V).
is_valid([[X,1] | T], ['-' | V]):- X > 3, is_valid(T, V).
% Ignore 1 or 2 0's
is_valid([[1,0] | T], V):- is_valid(T, V).
is_valid([[2,0] | T], V):- is_valid(T, V).
is_valid([[2,0] | T], ['^' | V]):- is_valid(T, V).
is_valid([[3,0] | T], ['^' | V]):- is_valid(T, V).
is_valid([[4,0] | T], ['^' | V]):- is_valid(T, V).
is_valid([[5,0] | T], ['^' | V]):- is_valid(T, V).
is_valid([[5,0] | T], ['#' | V]):- is_valid(T, V).
is_valid([[X,0] | T], ['#' | V]):- X > 5, is_valid(T, V).

% Generate the morse code using RLE to get the counts, and is_valid to match with
% the correct output, in order (top to bottom) using shortest first for ambiguous cases
signal_morse([], []).
signal_morse([H | T], M):- run_encode([H | T], ENC), is_valid(ENC, M).

%%%%%%%%%%%%%%%%%%%%%%% Signal Message %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Morse code dictionary
morse(a, [.,-]).           % A
morse(b, [-,.,.,.]).	   % B
morse(c, [-,.,-,.]).	   % C
morse(d, [-,.,.]).	   % D
morse(e, [.]).		   % E
morse('e''', [.,.,-,.,.]). % É (accented E)
morse(f, [.,.,-,.]).	   % F
morse(g, [-,-,.]).	   % G
morse(h, [.,.,.,.]).	   % H
morse(i, [.,.]).	   % I
morse(j, [.,-,-,-]).	   % J
morse(k, [-,.,-]).	   % K or invitation to transmit
morse(l, [.,-,.,.]).	   % L
morse(m, [-,-]).	   % M
morse(n, [-,.]).	   % N
morse(o, [-,-,-]).	   % O
morse(p, [.,-,-,.]).	   % P
morse(q, [-,-,.,-]).	   % Q
morse(r, [.,-,.]).	   % R
morse(s, [.,.,.]).	   % S
morse(t, [-]).	 	   % T
morse(u, [.,.,-]).	   % U
morse(v, [.,.,.,-]).	   % V
morse(w, [.,-,-]).	   % W
morse(x, [-,.,.,-]).	   % X or multiplication sign
morse(y, [-,.,-,-]).	   % Y
morse(z, [-,-,.,.]).	   % Z
morse(0, [-,-,-,-,-]).	   % 0
morse(1, [.,-,-,-,-]).	   % 1
morse(2, [.,.,-,-,-]).	   % 2
morse(3, [.,.,.,-,-]).	   % 3
morse(4, [.,.,.,.,-]).	   % 4
morse(5, [.,.,.,.,.]).	   % 5
morse(6, [-,.,.,.,.]).	   % 6
morse(7, [-,-,.,.,.]).	   % 7
morse(8, [-,-,-,.,.]).	   % 8
morse(9, [-,-,-,-,.]).	   % 9
morse(., [.,-,.,-,.,-]).   % . (period)
morse(',', [-,-,.,.,-,-]). % , (comma)
morse(:, [-,-,-,.,.,.]).   % : (colon or division sign)
morse(?, [.,.,-,-,.,.]).   % ? (question mark)
morse('''',[.,-,-,-,-,.]). % ' (apostrophe)
morse(-, [-,.,.,.,.,-]).   % - (hyphen or dash or subtraction sign)
morse(/, [-,.,.,-,.]).     % / (fraction bar or division sign)
morse('(', [-,.,-,-,.]).   % ( (left-hand bracket or parenthesis)
morse(')', [-,.,-,-,.,-]). % ) (right-hand bracket or parenthesis)
morse('"', [.,-,.,.,-,.]). % " (inverted commas or quotation marks)
morse(=, [-,.,.,.,-]).     % = (double hyphen)
morse(+, [.,-,.,-,.]).     % + (cross or addition sign)
morse(@, [.,-,-,.,-,.]).   % @ (commercial at)

% Error.
morse(error, [.,.,.,.,.,.,.,.]). % error - see below

% Prosigns.
morse(as, [.,-,.,.,.]).          % AS (wait A Second)
morse(ct, [-,.,-,.,-]).          % CT (starting signal, Copy This)
morse(sk, [.,.,.,-,.,-]).        % SK (end of work, Silent Key)
morse(sn, [.,.,.,-,.]).          % SN (understood, Sho' 'Nuff)

% Use accumulationg to store all morse codes relating to a letter until
% we come across a carrot after which we append to our final message.
% The special case for #, we add ourselves to the message as it is not in the
% dictionary.
accum([], [], []).
accum([], A, [M]):- morse(M, A).
accum(['#' | T], [], ['#' | MT]):- accum(T, [], MT).
accum(['#' | T], A, [Other, '#' | MT]):- morse(Other, A), accum(T, [], MT).
accum(['^' | T], [], M):- accum(T, [], M).
accum(['^' | T], A, [MH | MT]):- morse(MH, A), accum(T, [], MT).
accum([H | T], A, M):- append(A, [H], New), accum(T, New, M).

% Remove errors assuming an error is a token (Point 1 from post @217 on piazza)
% We accumulate the valid letters until a # after which we add to our message, clear the
% accumulator and continue. If we have an error token, then we check the next token, if
% it is an error then our accumulator takes the first error token and continues, else we
% refresh the accumulator, thus discarding all previous values that should be deleted.
remove_errors_accum([], [], []).
remove_errors_accum([], A, A).
remove_errors_accum(['#' | T], [], ['#' | MT]):- remove_errors_accum(T, [], MT).
remove_errors_accum(['#' | T], [AH | AT], [AH | MT]):- remove_errors_accum(['#' | T], AT, MT). 
remove_errors_accum([error, Other | T], A, M):- =(error, Other), append(A, [error], New), remove_errors_accum([Other | T], New, M);
											 remove_errors_accum([Other |T], [], M).
remove_errors_accum([H | T], A, M):- \=([H],['error']), append(A,[H], New), remove_errors_accum(T, New, M).

% Use an accumulator to fill up the final 'error free' message
remove_errors(Msg, M):- once(remove_errors_accum(Msg, [], M)).

% Signal message is broken into 1. Generating Morse Code, 2. Generating the word sequence
% 3. Removing all errors
signal_message([], []).
signal_message([H | T], M):- signal_morse([H | T], Morse), accum(Morse, [], Message), remove_errors(Message, M).
