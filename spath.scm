;; Title:   SPath
;; Author:  Carl A Olson
;; Date:    Feb 6, 2014
#lang scheme
(require srfi/26)

; full-gather deep-gather shallow-gather
;; sexp : list?
;; pred : procedure?
;; args : any/c
;; -> list?
; These three methods traverse s-expressions (sexp)
; and return lists of matching sub-sexps.
; Sexps match when pred returns true, args are
; passed to pred following a sub-sexp. pred could
; be replaced with "member", thus cleaning up function
; calls, but passing pred gives more syntax flexibility.

;; full-gather traverses every element
(define (full-gather sexp pred . args)
  (let full-gather ((sexp sexp))
    (cond
     ((or (null? sexp)
	  (not (list? sexp)))
      (quote ()))
     ((apply pred (car sexp) args)
      (append (list (car sexp))
	      (full-gather (car sexp))
	      (full-gather (cdr sexp))))
     (else
      (append (full-gather (car sexp))
	      (full-gather (cdr sexp)))))))

;; deep-gather traverses until it matches
(define (deep-gather sexp pred . args)
  (let deep-gather ((sexp sexp))
    (cond
     ((or (null? sexp)
	  (not (list? sexp)))
      (quote ()))
     ((apply pred (car sexp) args)
      (append (list (car sexp))
	      (deep-gather (cdr sexp))))
     (else
      (append (deep-gather (car sexp))
	      (deep-gather (cdr sexp)))))))

;; shallow-gather traverses only horizontally
(define (shallow-gather sexp pred . args)
  (let shallow-gather ((sexp sexp))
    (cond
     ((or (null? sexp)
	  (not (list? sexp)))
      (quote ()))
     ((apply pred (car sexp) args)
      (append (list (car sexp))
	      (shallow-gather (cdr sexp))))
     (else
      (shallow-gather (cdr sexp))))))

; parse-query
;; string : string?
;; -> list?
; Returns a list representation of the given string.
; Returned list is for easier parsing of s-expressions.
; Retuned list members are now refered to as "requests".
; Syntax rules for SPath are defined here.
(define (parse-query string)
  (let loop ((string string))
    (match string
	   [(regexp #rx"^/*[^/[]+(?=(\\[|/))") ;split based on foreward slashes, one at a time
	    (append-map loop (regexp-match* #rx"^/*[^/[]+(?=(\\[|/))" string #:gap-select? #t))]
	   [(regexp #rx"^\\[[^[]*](?=/)") ;split after bracket groups
	    (append-map loop (regexp-match* #rx"^\\[[^[]*]" string #:gap-select? #t))]
	   [(regexp #rx"^/*\\[.*\\]$") ;split up bracket groups
	    (list (append-map loop (regexp-match* #rx"[^]]+" string)))]
	   [(regexp #rx"\\[") ;clean up left over foreward brackets, keeping foreward slashes
	    (loop (regexp-replace #rx"\\[" string ""))]
	   [(regexp #rx"=") ;split up equal sign
	    (list (cons '= (regexp-match* #rx"[^=]+" string)))]
	   [(regexp #rx"^/*$") ;remove useless strings
	    (quote ())]
	   [_ (list string)])))

; request->proc
;; request : string?
;; -> procedure?
; Takes a request and returns an appropriate
; gather function to process it.
(define (request->proc request)
  (let/cc break
	  (let* ((count (length (regexp-match* "/" request)))
		 (proc (match count
			      [(or 0 1) shallow-gather]
			      [2 deep-gather]
			      [3 (break full-gather)]))) ;full-gather doesn't need append-map
	    (lambda(sexp pred . args)
	      (append-map (cut apply proc <> pred args) sexp)))))

; request->pred
;; request : list?
;; -> procedure?
; Takes a request and returns a predicate.
; Used by requests that check value (=).
(define (request->pred request)
  (lambda (sexp)
;    (and (eqv? (car request) '=)
    (member (map request->data (cdr request))
	    sexp)))

; request->data
;; request : string?
;; -> (or/c number? symbol? string?)
; Converts a request into its correct data type.
(define (request->data request)
  (let ((string (regexp-replace #rx"/*" request "")))
    (match string
	   [(regexp #rx"^[0-9]*\\.?[0-9]*$")
	    (string->number string)] ;number
	   [(regexp #rx"^[^']*$")
	    (string->symbol string)] ;symbol
	   [(regexp #rx"^'.*'$")
	    (regexp-replace #rx"^'(.*)'$" string "\\1")] ;string
	   [_ (error "Could not parse request.")]))) ;unknown

; is-member?
;; sexp : list?
;; a    : any/c
;; -> boolean?
; Returns true if a is the first element of sexp.
(define (is-member? sexp a)
  (and (list? sexp)
       (> (length sexp) 0)
       (or (eqv? (car sexp) a)
	   (eqv? a '*)))) ;wildcard

; spath
;; sexp  : list?
;; query : string?
;; -> list?
; spath is the only visible function of this file.
; spath will take a list of s-expressions and parse,
; filter, and return them based on the supplied query.
(define (spath sexp query)
  (let loop ((path (parse-query query))
	     (sexp (list sexp)))
    (if (or (null? path)
	    (null? sexp))
	sexp
	(loop (cdr path)
	      (let ((request (car path)))
		(cond
		 ((string? request) ;find next sub-sexp groups
		  ((request->proc request)
		   sexp is-member? (request->data request)))
		 ((and (list? request) ;check sexp for member
		       (> (length request) 1)
		       (eqv? (car request) '=))
		  (filter (request->pred request) sexp))
		 ((list? request) ;filter if sub-sexp chain is not found
		  (filter-not (compose null?
				       (cut loop request <>)
				       list)
			      sexp))
		 (else (error "Could not parse request."))))))))

; Export spath with a contract.
(provide (contract-out
	  [spath (list? string? . -> . list?)]))
