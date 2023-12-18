% Test elementary functionality.

:- initialization(test, main).

:- if((current_prolog_flag(version, V), V>=90121)).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
New version. This finds all foreign resources in the libraries and loads
them while resolving all symbols immediately.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

:- use_module(library(filesex)).
:- use_module(library(lists)).
:- use_module(library(occurs)).
:- use_module(library(prolog_source)).
:- use_module(library(solution_sequences)).

test :-
    forall(library_file(_File, Foreign),
           load_foreign(Foreign)),
    writeln("Loaded modules successfully.").

load_foreign(Spec) :-
    catch(load_foreign_(Spec), Ex,
          print_message(error, Ex)).

load_foreign_(Spec) :-
    absolute_file_name(Spec, File,
                       [ file_type(executable),
                         access(read)
                       ]),
    open_shared_object(File, _Handle, [resolve(now)]).

library_file(File, Foreign) :-
    absolute_file_name(library(.), Dir,
                       [ file_type(directory),
                         solutions(all)
                       ]),
    directory_member(Dir, File, [ extensions([pl]) ]),
    file_base_name(File, Base),
    \+ skip_file(Base),
    loads_foreign(File, Foreign).

loads_foreign(File, Foreign) :-
    (   current_prolog_flag(xref, Old)
    ->  true
    ;   Old = false
    ),
    setup_call_cleanup(
        set_prolog_flag(xref, true),
        limit(100, term_in_file(File, Term)),
        set_prolog_flag(xref, Old)),
    sub_term(Sub, Term),
    foreign(Sub, Foreign),
    !.

foreign(use_foreign_library(Lib), Foreign) =>
    strip_module(Lib, _, Foreign).
foreign(use_foreign_library(Lib, _), Foreign) =>
    strip_module(Lib, _, Foreign).
foreign(_, _) => fail.

term_in_file(File, Term) :-
    setup_call_cleanup(
        prolog_open_source(File, In),
        (   repeat,
            prolog_read_source_term(In, Read, Expanded, [])
        ),
        prolog_close_source(In)),
    (   Read == end_of_file
    ->  !
    ;   is_list(Expanded)
    ->  member(Term, Expanded)
    ;   Term = Expanded
    ).

skip_file('check_installation.pl'). % refers to all foreign files
skip_file('sty_xpce.pl').           % does not import operators, causing syntax errors

:- else.

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Old version. This checks only the extensions.   Note that we only try to
load the extensions that are  in  the   library.  If  the package is not
downloaded at all, this is on purpose.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

lib(space/space).
lib(prosqlite).
lib(r/r_call).
lib(rocksdb).
lib(hdt).

test :-
    forall(lib(Lib), check_lib(library(Lib))),
    writeln("Loaded modules successfully.").

check_lib(Lib) :-
    exists_source(Lib),
    !,
    use_module(Lib, []).
check_lib(_).

:- endif.
