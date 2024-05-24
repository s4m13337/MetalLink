# MetalLink

MetalLink connects Mathematica with Apple's metal API using LibraryLink. The code base is written in a mixture of C and Objective C.

## Conventions
- All the host codes files containing a specific function are named as per the function prefixed with `metal_` e.g. `metal_map.m`, `metal_add.m`, etc. These files live in the `./src/` directory. 
- The corresponding kernel code files in the `./lib/` directory are simply named according tot the function name along with the extension `.metal` e.g. `map.metal`, `add.metal`, etc.
- The `__preamble.metal` contains all the declarations required for the kernel functions. During building, All the `.metal` files get combined into `library.metal` which is built into the final executable.
- All the functions must be named in snake case. 