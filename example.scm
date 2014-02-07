#lang scheme
(require net/url)
(require (planet neil/html-parsing:2:0))
(require "spath.scm")

; url->xexp
;; url : string?
;; -> list?
; Visits URL and parses HTML into a s-expression.
(define (url->xexp url)
  (let ((o (get-pure-port (string->url url) #:redirections 10)))
    (html->xexp o)))

; get-strings
;; sexp : list?
; Returns a list of all strings inside sexp.
(define (get-strings sexp)
  (filter string? (flatten sexp)))



; Stock market example
;; Display current S&P500 value
(define stock-page (url->xexp "https://www.google.com/finance?cid=626307"))
(define stock-info (spath stock-page 
			  "///div[@/id='price-panel']///span/[@/id]"))
(define sp500-value (cadr (get-strings stock-info)))
(display "S&P 500:\t")(display sp500-value)(newline)


; News example
;; Display title of first story from Google News "Top Stories"
(define news-page (url->xexp "https://news.google.com"))
(define news-info (spath news-page
			 "///h2//span[@/class='titletext']"))
(define top-story (cadr (get-strings news-info)))
(display "Top Story:\t")(display top-story)(newline)
