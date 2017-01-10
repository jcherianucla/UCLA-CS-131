; Return if obj is an empty listdiff or not
; Make sure that object is valid by testing if it is a pair
; and then just make sure the two elements of the pair listdiff
; are the same, which thus means the listdiff is null.
(define (null-ld? obj) 
	(if (or (null? obj) (not (pair? obj))) #f 
		(eq? (car obj) (cdr obj))
  	)
)

; Return if obj is a listdiff or not
; Go through all the elements through the listdiff unti
; we hit an empty list diff, so that we know that obj is a listdiff
; otherwise, if we don't have a valid pair for the obj or the car
; of the obj then we know that it is not a valid listdiff.
(define (listdiff? obj) 
	(if (null-ld? obj) #t 
	  (if (or (null? obj) (not (pair? obj)) (not (pair? (car obj)))) #f
	  (listdiff? (cons (cdr (car obj)) (cdr obj))))
	)
)

; Return a listdiff whose first element is obj 
; and whose remaining elements are listdiff.
; If we are given a valid listdiff, then just cons
; the obj to the start of the listdiff first element, and 
; then cons that with the rest of the listdiff to return a
; valid listdiff, otherwise just throw an error.
(define (cons-ld obj listdiff)
	(if (listdiff? listdiff)
	  (cons (cons obj (car listdiff)) (cdr listdiff)) (error "ERROR!")
	)
)

; Return the first element of listdiff. It is an error if 
; listdiff has no elements.
; If it is a valid listdiff and not empty, then just return listdiff's
; first element's first element (that is the very first element of the listdiff)
; else throw an error.
(define (car-ld listdiff)
	(if (and (listdiff? listdiff) (not (null-ld? listdiff)))
		(car (car listdiff)) (error "ERROR!")
	)
)

; Return a listdiff containing all but the first element of listdiff.
; It is an error if listdiff has no elements.
; If its a valid listdiff and is not empty, then we just remove the 
; first element by using cons on the cdr of the car (everything but the
; first element) and the cdr of the listdiff, else throw an error.
(define (cdr-ld listdiff)
	(if (and (listdiff? listdiff) (not (null-ld? listdiff)))
		(cons (cdr (car listdiff)) (cdr listdiff)) (error "ERROR!")	
	)
)

; Return a newly allocated listdiff of its arguments.
; Just combine the object and arguments, thus giving us a 
; pair that is a listdiff.
(define (listdiff obj . args)
	(cons (cons obj args) '())
)

; Return the length of listdiff
; If we are given a valid listdiff, then if it is null, its length is 0
; otherwise we just add 1 and then check for the rest of the listdiff, else
; return an error. Use a helper function for tail-recursion optimization.
(define (length-ld listdiff)
  	(define (length-ld-tail listdiff accum)
		(if (listdiff? listdiff)
			(if (null-ld? listdiff)
				accum
				(length-ld-tail (cdr-ld listdiff) (+ accum 1))
			)
			(error "ERROR!")
		)
	)
	(length-ld-tail listdiff 0)
)

; Return a listdiff consisting of the elements of 
; the first listdiff followed by the elements of the other listdiffs. 
; The resulting listdiff is always newly allocated, except that it shares 
; structure with the last argument. (Unlike append, the last argument 
; cannot be an arbitrary object; it must be a listdiff.)
; Recursively get the actual difference and append to each beginning of the 
; next listdiff and then recursively call it with the cdr of the args, and
; unpack the arguments so that they are packed in the recursive call, ending
; when we have no more listdiffs in args.
(define (append-ld listdiff . args)
	(if (null? args) listdiff
	  (apply append-ld (cons (append (take (car listdiff) (length-ld listdiff)) 
	  								  (car (car args))) (cdr (car args))) 
	  					(cdr args))
	)
)
; alistdiff must be a listdiff whose members are all pairs. 
; Find the first pair in alistdiff whose car field is eq? to obj, 
; and return that pair; if there is no such pair, return #f.
; If we have an empty listdiff then we just return false, otherwise
; just compare the first element (car of car of car of listdiff) with obj
; making sure its a pair, and if they are equal return the pair else 
; recursively call it with the rest of the listdiff.
(define (assq-ld obj alistdiff)
	(if (null-ld? alistdiff) #f
	  (if (and (pair? (car alistdiff)) (eq? (car (car (car alistdiff))) obj))
	  	(car (car alistdiff))
	  	(if (pair? (car alistdiff))
	  		(assq-ld obj (cons (cdr (car alistdiff)) (cdr alistdiff)))
	  		#f
	  	)
	  )
	)
)

; Return a listdiff that represents the same elements as list.
; Reuse the listdiff function, unpacking the list as a set of 
; arguments.
(define (list->listdiff list)
  	(if (list? list)
		(apply listdiff (car list) (cdr list))
		(error "ERROR!")
	)
)

; Return a list that represents the same elements as listdiff.
; Simply take the difference of the listdiff, which implicitly
; returns a list.
(define (listdiff->list listdiff)
  	(if (listdiff? listdiff)
		(take (car listdiff) (length-ld listdiff))
		(error "ERROR!")
	)
)

; Return a Scheme expression that, when evaluated, will return a copy of listdiff, 
; that is, a listdiff that has the same top-level data structure as listdiff. 
; Your implementation can assume that the argument listdiff contains only 
; booleans, characters, numbers, and symbols.
; Use a quasiquote to produce the difference of lists and cons that with 
; an empty list to create a valid listdiff thus giving us a shallow copy of 
; the original listdiff.
(define (expr-returning listdiff)
  	(if (listdiff? listdiff)
		`(cons ',(take (car listdiff) (length-ld listdiff)) '())
		(error "ERROR!")
	)
)

; Test values - Uncomment to use
;(define ils (append '(a e i o u) 'y))
;(define d1 (cons ils (cdr (cdr ils))))
;(define d2 (cons ils ils))
;(define d3 (cons ils (append '(a e i o u) 'y)))
;(define d4 (cons '() ils))
;(define d5 0)
;(define d6 (listdiff ils d1 37))
;(define d7 (append-ld d1 d2 d6))
;(define e1 (expr-returning d1))
;(define kv1 (cons d1 'a))
;(define kv2 (cons d2 'b))
;(define kv3 (cons d3 'c))
;(define kv4 (cons d1 'd))
;(define d8 (listdiff kv1 kv2 kv3 kv4))
;(eq? (assq-ld d1 d8) kv1)
;(eq? (assq-ld d2 d8) kv2)
;(eq? (assq-ld d1 d8) kv4)
;(eq? (car-ld d6) ils)
;(eqv? (car-ld (cdr-ld (cdr-ld d6))) 37)
;(equal? (listdiff->list d6) (list ils d1 37))
;(eq? (list-tail (car d6) 3) (cdr d6))
;(listdiff->list (eval e1))
;(equal? (listdiff->list (eval e1))
;		        (listdiff->list d1))
