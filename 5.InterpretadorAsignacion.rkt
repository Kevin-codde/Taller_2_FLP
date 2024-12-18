#lang eopl
#|

   Autores: Kevin Andres Bejarano - 2067678
            Juan David Gutierrez Florez - 2060104
            Johan Sebastián Laverde pineda - 2266278
            Johan Sebastian Acosta Restrepo 2380393
   
|#

(define especificacion-lexica
  '(
    ;; Patrones básicos
    (espacio-blanco (whitespace) skip)
    (comentario ("%" (arbno (not #\newline))) skip)
    (identificador (letter (arbno (or letter digit "?" "$"))) symbol)
    (numero (digit (arbno digit)) number)
    (numero ("-" digit (arbno digit)) number)
    (numero (digit (arbno digit)"." digit (arbno digit)) number)
    (numero ("-" digit (arbno digit)"." digit (arbno digit)) number)
    
  ))


(define especificacion-gramatical
  '(
    (programa (expresion) a-program)
    (expresion (numero) lit-exp)
    (expresion (identificador) var-exp)
    ;;Agregamos la gramática de los condicionales y las ligaduras
    (expresion ("true") true-exp)
    (expresion ("false") false-exp)
    (expresion ("if" expresion "then" expresion "else" expresion) if-exp)
    ;; gramatica cond
    (expresion ("cond" (arbno expresion "==>"  expresion) "else" "==>" expresion "end") cond-exp)
    ;;Ligaduras locales
    (expresion ("let" (arbno identificador "=" expresion) "in" expresion) let-exp)
    ;;Fin de condicionales y ligaduras
    ;;procedimientos
    (expresion ("proc" "(" (separated-list identificador ",") ")" expresion) proc-exp)
    (expresion ("(" expresion (arbno expresion) ")") app-exp)

    ;;fin procedimientos
    ;;procedimientos recursivos
    (expresion ("letrec" (arbno identificador "(" (separated-list identificador ",") ")" "=" expresion) "in" expresion) letrec-exp) 
    ;;fin de procedimientos recursivos

    ;;Asignación
    (expresion ("begin" expresion (arbno ";" expresion) "end") begin-exp)
    (expresion ("set" identificador "=" expresion) set-exp)

    ;;Primitivas
    (expresion (primitiva "(" (separated-list expresion ",") ")") prim-exp)
    (primitiva ("+") sum-prim)
    (primitiva ("-") minus-prim)
    (primitiva ("*") mult-prim)
    (primitiva ("/") div-prim)
    (primitiva ("add1") add-prim)
    (primitiva ("sub1") sub-prim)
    ;;primitivas booleanas
    (primitiva (">") mayor-prim)
    (primitiva (">=") mayorigual-prim)
    (primitiva ("<") menor-prim)
    (primitiva ("<=") menorigual-prim)
    (primitiva ("==") igual-prim)

    ;; Add to especificacion-gramatical for lists
    (programa (expresion) a-program)
    (expresion (numero) lit-exp)
    (expresion (identificador) var-exp)
    (expresion ("true") true-exp)
    (expresion ("false") false-exp)
    ;; Agregado para listas
    (expresion ("empty") list-empty-exp) ; Lista vacía
    (expresion ("cons" "(" expresion expresion ")") cons-exp) ; Lista no vacía
    (expresion ("length" "(" expresion")") length-exp) ; Longitud de lista
    (expresion ("first" "(" expresion ")") first-exp) ; Primer elemento
    (expresion ("rest" "(" expresion ")") rest-exp) ; Resto de lista
    (expresion ("nth" "(" expresion expresion ")") nth-exp) ; N-ésimo elemento
    )
  )

;;Creamos los datatypes automaticamente
(sllgen:make-define-datatypes especificacion-lexica especificacion-gramatical)


;;Evaluar programa
(define evaluar-programa
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp) (evaluar-expresion exp ambiente-inicial))
      )

    )
  )

;;ambientes
(define-datatype ambiente ambiente?
  (ambiente-vacio)
  (ambiente-extendido-ref
   (lids (list-of symbol?))
   (lvalue vector?)
   (old-env ambiente?)))

(define ambiente-extendido
  (lambda (lids lvalue old-env)
    (ambiente-extendido-ref lids (list->vector lvalue) old-env)))

;;Implementación ambiente extendido recursivo

(define ambiente-extendido-recursivo
  (lambda (procnames lidss cuerpos old-env)
    (let
        (
         (vec-clausuras (make-vector (length procnames)))
         )
      (letrec
          (
           (amb (ambiente-extendido-ref procnames vec-clausuras old-env))
           (obtener-clausuras
            (lambda (lidss cuerpos pos)
              (cond
                [(null? lidss) amb]
                [else
                 (begin
                   (vector-set! vec-clausuras pos
                                (closure (car lidss) (car cuerpos) amb))
                   (obtener-clausuras (cdr lidss) (cdr cuerpos) (+ pos 1)))]
                )
              )
            )
           )
        (obtener-clausuras lidss cuerpos 0)
        )
      )
    )
  )


(define apply-env
  (lambda (env var)
    (deref (apply-env-ref env var))))


(define apply-env-ref
  (lambda (env var)
    (cases ambiente env
      (ambiente-vacio () (eopl:error "No se encuentra la variable " var))
      (ambiente-extendido-ref (lid vec old-env)
                          (letrec
                              (
                               (buscar-variable (lambda (lid vec pos)
                                                  (cond
                                                    [(null? lid) (apply-env-ref old-env var)]
                                                    [(equal? (car lid) var) (a-ref pos vec)]
                                                    [else
                                                     (buscar-variable (cdr lid) vec (+ pos 1)  )]
                                                    )
                                                  )
                                                )
                               )
                            (buscar-variable lid vec 0)
                            )
                          
                          )
      
      )
    )
  )

(define ambiente-inicial
  (ambiente-extendido '(x y z) '(4 2 5)
                      (ambiente-extendido '(a b c) '(4 5 6)
                                          (ambiente-vacio))))

;;Evaluar expresion
(define evaluar-expresion
  (lambda (exp amb)
    (cases expresion exp
      ;; Casos existentes
      (lit-exp (dato) dato) ; Caso para literales
      (var-exp (id) (apply-env amb id)) ; Caso para variables
      (true-exp () #true) ; Caso para booleanos
      (false-exp () #false)

      ;; Caso para lista vacía
      (list-empty-exp ()
        '()) ; Devuelve la lista vacía directamente

      ;; Caso para lista no vacía
    (cons-exp (exp1 exp2)
        (let ([first-val (evaluar-expresion exp1 amb)]
              [rest-val (evaluar-expresion exp2 amb)])
          (if (list? rest-val)
              (cons first-val rest-val)
              (eopl:error "El segundo argumento de cons no es una lista: " rest-val))))

      ;; Otros casos existentes...
      (prim-exp (prim args)
                (let ([lista-numeros (map (lambda (x) (evaluar-expresion x amb)) args)])
                  (evaluar-primitiva prim lista-numeros)))
      (if-exp (condicion hace-verdadero hace-falso)
              (if (evaluar-expresion condicion amb)
                  (evaluar-expresion hace-verdadero amb)
                  (evaluar-expresion hace-falso amb)))
      (cond-exp (evaluacion_exp retorno_exp else_exp)
        (letrec 
          (
            (expresion_correcta
              (lambda (caso list_e valor)
                (cond
                  [(null? caso) (evaluar-expresion else_exp amb)]
                  [(and (evaluar-expresion (car caso) amb) (not (equal? (evaluar-expresion (car caso) amb) 0))) (evaluar-expresion (car list_e) amb)]
                  [else (expresion_correcta (cdr caso) (cdr list_e) valor)]
                )
              )
            )
          )
          (expresion_correcta evaluacion_exp retorno_exp else_exp)
        )
      )
      
      (let-exp (ids rands body)
               (let ([lvalues (map (lambda (x) (evaluar-expresion x amb)) rands)])
                 (evaluar-expresion body (ambiente-extendido ids lvalues amb))))
      (proc-exp (ids body)
                (closure ids body amb))
      (app-exp (rator rands)
               (let ([lrands (map (lambda (x) (evaluar-expresion x amb)) rands)]
                     [procV (evaluar-expresion rator amb)])
                 (if (procval? procV)
                     (cases procval procV
                       (closure (lid body old-env)
                                (if (= (length lid) (length lrands))
                                    (evaluar-expresion body
                                                       (ambiente-extendido lid lrands old-env))
                                    (eopl:error "Número incorrecto de argumentos"))))
                     (eopl:error "No puede evaluarse algo que no sea un procedimiento: " procV))))
      ;; Asignación
      (set-exp (id exp)
               (begin
                 (setref! (apply-env-ref amb id)
                          (evaluar-expresion exp amb))
                 1))

      ;; Caso general: error
      (else (eopl:error "Expresión no válida: " exp)))))


;;Manejo de primitivas
(define evaluar-primitiva
  (lambda (prim lval)
    (cases primitiva prim
      (sum-prim () (operacion-prim lval + 0))
      (minus-prim () (operacion-prim lval - 0))
      (mult-prim () (operacion-prim lval * 1))
      (div-prim () (operacion-prim lval / 1))
      (add-prim () (+ (car lval) 1))
      (sub-prim () (- (car lval) 1))
      (mayor-prim () (> (car lval) (cadr lval)))
      (mayorigual-prim () (>= (car lval) (cadr lval)))
      (menor-prim () (< (car lval) (cadr lval)))
      (menorigual-prim () (<= (car lval) (cadr lval)))
      (igual-prim () (= (car lval) (cadr lval)))
      )
    )
  )


(define operacion-prim
  (lambda (lval op term)
    (cond
      [(null? lval) term]
      [else
       (op
        (car lval)
        (operacion-prim (cdr lval) op term))
       ]
      )
    )
  )

;;Definiciones para los procedimientos
(define-datatype procval procval?
  (closure (lid (list-of symbol?))
           (body expresion?)
           (amb-creation ambiente?)))

;;Referencias

(define-datatype referencia referencia?
  (a-ref (pos number?)
         (vec vector?)))

;;Extractor de referencias
(define deref
  (lambda (ref)
    (primitiva-deref ref)))

(define primitiva-deref
  (lambda (ref)
    (cases referencia ref
      (a-ref (pos vec)
             (vector-ref vec pos)))))

;;Asignación/cambio referencias
(define setref!
  (lambda (ref val)
    (primitiva-setref! ref val)))

(define primitiva-setref!
  (lambda (ref val)
    (cases referencia ref
      (a-ref (pos vec)
             (vector-set! vec pos val)))))



;; Crear el analizador léxico y sintáctico
(define scan&parse
  (sllgen:make-string-parser especificacion-lexica especificacion-gramatical))
;;Interpretador
(define interpretador
  (sllgen:make-rep-loop "-->" evaluar-programa
                        (sllgen:make-stream-parser
                         especificacion-lexica especificacion-gramatical)))


(define exp (scan&parse  "let x = 2 in 
       cond 
         ==(x,1) ==> 1
         ==(x,2) ==> 2
         ==(x,3) ==> 4
         else ==> 9
       end"))
;(display exp)
;(display (evaluar-programa exp))
;(interpretador)
(provide (all-defined-out)) 

 
 