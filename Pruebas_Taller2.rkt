#lang racket/base

(require rackunit "5.InterpretadorAsignacion.rkt") ; Cambia el nombre si tu archivo tiene otro


; Test 1: Lista vacía
(define exp1
  (scan&parse
    "empty"  
  ))
(define expected-exp1
  '())
(check-equal? (evaluar-programa exp1) expected-exp1)

; Test 2: Construcción de listas
(define exp2
  (scan&parse
    "cons (1 cons (2 cons (3 empty)))"
  ))
(define expected-exp2
  '(1 2 3)
)
(check-equal? (evaluar-programa exp2) expected-exp2)

; Test 3: Longitud de listas
(define exp3
  (scan&parse
    "length (cons (1 cons (2 cons (3 empty))))"
  ))
(define expected-exp3
  3
)
(check-equal? (evaluar-programa exp3) expected-exp3)

; Test 4: Primer elemento
(define exp4
  (scan&parse
    "first (cons (1 cons (2 cons (3 empty))))"
  ))
(define expected-exp4
  1
)
(check-equal? (evaluar-programa exp4) expected-exp4)

; Test 5: Resto de la lista
(define exp5
  (scan&parse
    "rest (cons (1 cons (2 cons (3 empty))))"
  ))
(define expected-exp5
  '(2 3)
)
(check-equal? (evaluar-programa exp5) expected-exp5)

; Test 6: Elemento en posición n
(define exp6
  (scan&parse
    "nth (cons (1 cons (2 cons (3 empty))) 2)"
  ))
(define expected-exp6
  3
)
(check-equal? (evaluar-programa exp6) expected-exp6)

; Test 7: Error al acceder a una lista vacía
(define exp7
  (scan&parse
    "first (empty)"
  ))
(check-exn exn:fail?
  (lambda () (evaluar-programa exp7)))

; Test 8: Error al acceder a índice fuera de rango
(define exp8
  (scan&parse
    "nth (cons (1 cons (2 cons (3 empty))) 5)"
  ))
(check-exn exn:fail?
  (lambda () (evaluar-programa exp8)))
