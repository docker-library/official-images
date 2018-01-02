multiarch:-[library(space/space)], [library(prosqlite)], [library(r/r_call)].
amd64arch:-[library(rocksdb)], [library(hdt)].

cpu(Cpu):-current_prolog_flag(arch, Arch), split_string(Arch, "-", "", [Cpu, _]).

test:-
    (
        cpu("x86_64")
        -> multiarch
        , amd64arch
        , writeln("Loaded modules successfully.")
        ;
        cpu("armv8l")
        -> multiarch
        , writeln("Loaded modules successfully.")
    )
    , halt.
