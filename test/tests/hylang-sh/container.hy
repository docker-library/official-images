(->
  (+ 2 2)
  (print))

(import subprocess sys)
(subprocess.check_call [sys.executable "-m" "pip" "install" "-q" "sh"])

(import [sh [echo]])
(->
  (+
    (int (echo "-n" 21))
    (int (echo "-n" 21)))
  (print))
