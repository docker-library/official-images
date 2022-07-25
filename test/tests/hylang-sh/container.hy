(require hyrule [-> comment])

(->
  (+ 2 2)
  (print))

(import subprocess sys)
(subprocess.check_call [sys.executable "-m" "pip" "install" "-q" "sh==1.14.2"])
(import platform)

(comment Windows is not supported by sh (sad day))
(comment https://github.com/amoffat/sh/blob/608f4c3bf5ad75ad40035d03a9c5ffcce0898f07/sh.py#L33-L36)
(if (= (.system platform) "Windows")
  (defn echo [dashn num] (return num))
  (import sh [echo]))

(->
  (+
    (int (echo "-n" 21))
    (int (echo "-n" 21)))
  (print))
