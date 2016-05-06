(->
  (+ 2 2)
  (print))

(import [pip])
(pip.main ["install" "-q" "sh"])

(import [sh [echo]])
(->
  (+
    (int (echo "-n" 21))
    (int (echo "-n" 21)))
  (print))
