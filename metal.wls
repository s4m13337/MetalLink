#!/usr/bin/env wolframscript
Print["Welcome to MetalLink tests"];
Print["Loading dynamic library"];
path = "~/Developer/MetalLink/";
LibraryLoad[path<>"libmetal.dylib"];
Print["Library loaded"];
addArray = LibraryFunctionLoad[
    path<>"libmetal.dylib", 
    "addArrays", 
    {{LibraryDataType[NumericArray]}, {LibraryDataType[NumericArray]}}, 
    {LibraryDataType[NumericArray]}
];

addArray = LibraryFunctionLoad[
    path<>"libmetal.dylib", 
    "map", 
    {{LibraryDataType[NumericArray]}, {LibraryDataType[NumericArray]}}, 
    {LibraryDataType[NumericArray]}
];

n1 = NumericArray[Table[1., 10], "Real32"];
n2 = NumericArray[Table[1., 10], "Real32"];

Print["CPU addition time: ", AbsoluteTiming[cpu = Normal[n1] + Normal[n2];]]
Print["GPU addition time: ", AbsoluteTiming[gpu = addArray[n1, n2];]]

If[cpu === Normal[gpu], Print["GPU calculations are correct"], Print["GPU calculations are wrong"]]

Print["Trial 2"]
gpu = addArray[n1, n2];
Print["Trial 3"]
gpu = addArray[n1, n2];

Print["CPU result: ", cpu[[1;;10]]];
Print["GPU result: ", Normal[gpu][[1;;10]]];

LibraryFunctionUnload[addArray];
libraryUnload[libmetal];


