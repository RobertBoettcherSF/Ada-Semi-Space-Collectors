# Ada Semi-Space Garbage Collector

## Project Overview
This project provides a robust, strongly-typed implementation of a two-space copying garbage collector in Ada. Drawing inspiration from classic memory management principles, it splits memory into a "From-Space" and a "To-Space." During collection, live objects are evacuated from the active space into the reserve space, simultaneously compacting memory and discarding unreferenced data. 

## Features
- **Strong Typing:** Utilizes safe array indices (`Object_Id`) rather than OS-level pointers, preventing segmentation faults and out-of-bounds pointer arithmetic.
- **Variant 1: Cheney's Algorithm (Iterative):** The primary collection method. Uses the To-Space itself as a BFS queue to traverse the object graph, completely eliminating the risk of stack overflow on deep object graphs.
- **Variant 2: Standard Recursive Collection:** A secondary DFS variant implemented for comparative study and architectural completeness.
- **Cyclic Graph Safety:** Both variants handle cyclical object references natively via immediately-placed forwarding pointers, ensuring no infinite loops or recursions occur.

## Testing (Verification & Validation)
Testing in critical software requires a pessimistic assumption: **the code is broken until proven otherwise**. The included test suite serves as our Verification and Validation (V&V) pipeline. 

- **Functional Correctness:** Tests verify that graphs (trees, linked lists) are perfectly mirrored into the new space. *Why it matters:* Proves the algorithm correctly follows memory references.
- **Error Handling & Boundaries:** Tests strictly enforce the `Space_Size = 1024` boundary. Allocating node 1025 must raise an `Out_Of_Memory` exception. *Why it matters:* Ensures the system fails safely and predictably rather than silently corrupting memory.
- **Edge Cases (Cycles & Shared Pointers):** Tests deliberately create cycles (Node A -> Node B -> Node A) and duplicate root references. *Why it matters:* Proves the forwarding pointer mechanism works, preventing infinite loops and preventing memory duplication. 
- **Assumption Disproven:** By forcing 13 distinct edge-case, boundary, and state-integrity failures, and having the code successfully navigate all of them, the suite validates that the garbage collector meets its intended design goals.

## Usage

### Compilation
The project requires the GNAT toolchain. A Makefile is provided for convenience.
```bash
# Compile both the main executable and the test suite
make all
