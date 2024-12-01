#lang racket/base

(require rackunit "5.InterpretadorAsignacion.rkt") ; Cambia el nombre si tu archivo tiene otro

; Test 1: Caso básico de cond con múltiples condiciones
(define exp1
  (scan&parse
    "let x = 2 in 
       cond 
         ==(x,1) ==> 1
         ==(x,2) ==> 2
         ==(x,3) ==> 4
         else ==> 9
       end"
  ))
(define expected-exp1
  2 ; Se evalúa `(x 2)` porque x es igual a 2
)
(check-equal? (evaluar-programa exp1) expected-exp1)

; Test 2: Caso de cond con solo else
(define exp2
  (scan&parse
    "let x = 2 in 
       cond 
         else ==> 9
       end"
  ))
(define expected-exp2
  9 ; Solo está else, así que retorna 9
)
(check-equal? (evaluar-programa exp2) expected-exp2)

; Test 3: Caso donde cond evalúa el primer valor verdadero
(define exp3
  (scan&parse
    "let x = 3 in 
       cond 
         ==(x,1) ==> 1
         ==(x,3) ==> 3
         else ==> 9
       end"
  ))
(define expected-exp3
  3 ; La segunda condición es verdadera
)
(check-equal? (evaluar-programa exp3) expected-exp3)

; Test 4: Caso donde cond nunca llega a else
(define exp4
  (scan&parse
    "let x = 1 in 
       cond 
         ==(x,1) ==> 7
         ==(x,2) ==> 8
         else ==> 10
       end"
  ))
(define expected-exp4
  7 ; Retorna el primer caso verdadero
)
(check-equal? (evaluar-programa exp4) expected-exp4)

; Test 5: Caso donde ninguna condición es verdadera, se usa else
(define exp5
  (scan&parse
    "let x = 0 in 
       cond 
         ==(x,1) ==> 1
         ==(x,2) ==> 2
         else ==> 10
       end"
  ))
(define expected-exp5
  10 ; Retorna el else porque ninguna condición es verdadera
)
(check-equal? (evaluar-programa exp5) expected-exp5)

; Test 6: Caso con múltiplos valores en una condición
(define exp6
  (scan&parse
    "let x = 10 in 
       cond 
         ==(x,10) ==> 5
         ==(x,20) ==> 15
         else ==> 0
       end"
  ))
(define expected-exp6
  5 ; La primera condición es verdadera
)
(check-equal? (evaluar-programa exp6) expected-exp6)

; ; Test 7: Error al no finalizar bien la gramatica
; (define exp7
;   (scan&parse
;     "let x = 10 in 
;        cond 
;          ==(x,10) ==> 5
;          ==(x,20) ==> 15
;        end"
;   ))
; (check-exn exn:fail?
;   (lambda () (evaluar-programa exp7)))





