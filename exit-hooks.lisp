;;;; exit-hooks.lisp

(in-package #:exit-hooks)

#-(or sbcl ccl ecl abcl allegro clisp cmu dotcl)
(error "Sorry, not implement for ~a. If you can provide exit-hooks for your implementation, please contact me at icerove@gmail.com~%" (lisp-implementation-type))

#+abcl
(progn
  (defparameter *abcl-exit-hooks* nil)

  (defun %abcl-exit-hook-controller ()
    (mapc #'funcall *abcl-exit-hooks*))
  
  (defparameter *exit-hook-thread*
    (java:jnew-runtime-class "ExitHookThread" :superclass "java.lang.Thread"
			     :methods `(("run" :void () ,#'(lambda (this)
							     (declare (ignore this))
							     (funcall #'%abcl-exit-hook-controller))))))
  (java:jcall "addShutdownHook" (java:jstatic "getRuntime" "java.lang.Runtime")
	      (java:jnew *exit-hook-thread*)))

#+dotcl
(progn
  (defvar *dotcl-exit-hooks* nil)

  (defun %dotcl-run-exit-hooks (sender args)
    (declare (ignore sender args))
    (mapc #'funcall *dotcl-exit-hooks*))

  (defvar *dotcl-exit-hook-handler*
    (let ((handler (dotnet:make-delegate "System.EventHandler" #'%dotcl-run-exit-hooks)))
      (dotnet:invoke (dotnet:static "System.AppDomain" "CurrentDomain")
                     "add_ProcessExit" handler)
      handler)))

(define-symbol-macro *exit-hooks*
    #+sbcl sb-ext:*exit-hooks*
    #+ccl ccl:*lisp-cleanup-functions*
    #+ecl si:*exit-hooks*
    #+abcl *abcl-exit-hooks*
    #+allegro sys:*exit-cleanup-forms*
    #+clisp custom:*fini-hooks*
    #+cmu lisp::*cleanup-functions*
    #+dotcl *dotcl-exit-hooks*)

(defun add-exit-hook (func)
  (push #+allegro (list 'funcall func) 
	#-allegro func
        *exit-hooks*))
