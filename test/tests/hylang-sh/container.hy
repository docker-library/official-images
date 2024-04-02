(require hyrule [-> comment])

(->
  (+ 2 2)
  (print))

(import os subprocess sys)
(subprocess.check_call [sys.executable "-m" "pip" "install" "-q" "sh==1.14.2"]
  :stdout sys.stderr
  :env (dict os.environ
    :PIP_DISABLE_PIP_VERSION_CHECK "1"
    :PIP_NO_PYTHON_VERSION_WARNING "1"
    :PIP_ROOT_USER_ACTION "ignore"))
(comment PIP_DISABLE_PIP_VERSION_CHECK: ensure pip does not complain about a new version being available)
(comment PIP_NO_PYTHON_VERSION_WARNING: or that a new version will no longer work with this python version)
(comment PIP_ROOT_USER_ACTION: ensure pip does not complain about running about root)

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
