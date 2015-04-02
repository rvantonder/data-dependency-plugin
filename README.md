# Data dependency plugin 

## Notes:

* Only flow dependency, we don't care so much about anti- and output data dependencies at this point
* We treat any memory read as being dependent on all previous memory writes. This is the important area we want to improve on next.
* `ddep.dot` file is output for a graph representation.

## Example

Run `run.sh`.

* We highlight the two statements in the graph which serve as arguments for `strcpy`:

```
8: jmp 0x82E0:32     <- strcpy call
9: LR := 0x849C:32
10: R1 := R3         <- highlighted
11: R0 := R2         <- highlighted
```

(Note statements are in reverse of execution order)

Full output:

```
0: jmp (mem[base_478 + 0x4:32, el]:u32)                                         0: ()
1: SP := SP + 0x8:32                                                            1: (4 44 47)
2: R11 := mem[base_478 + 0x0:32, el]:u32                                        2: (3 4 23 24 25 26 29 30 31 34 35 36 39 40 44 47 48 49 50)
3: base_478 := SP                                                               3: (4 44 47)
4: SP := R11 - 0x4:32                                                           4: (44 47)
5: t_477 := 0x4:32                                                              5: ()
6: s_476 := R11                                                                 6: (44 47)
7: R0 := R3                                                                     7: (15 16 19 23 24 25 26 29 30 31 34 35 36 39 40 44 47 48 49 50)
8: jmp 0x82E0:32                                                                8: ()
9: LR := 0x849C:32                                                              9: ()
10: R1 := R3                                                                    10: (15 16 19 23 24 25 26 29 30 31 34 35 36 39 40 44 47 48 49 50)
11: R0 := R2                                                                    11: (12 44 47)
12: R2 := R11 - 0x10:32                                                         12: (44 47)
13: t_471 := 0x10:32                                                            13: ()
14: s_470 := R11                                                                14: (44 47)
15: R3 := mem[R3 + 0x0:32, el]:u32                                              15: (16 19 23 24 25 26 29 30 31 34 35 36 39 40 44 47 48 49 50)
16: R3 := R3 + 0x4:32                                                           16: (19 23 24 25 26 29 30 31 34 35 36 39 40 44 47 48 49 50)
17: t_467 := 0x4:32                                                             17: ()
18: s_466 := R3                                                                 18: (19 23 24 25 26 29 30 31 34 35 36 39 40 44 47 48 49 50)
19: R3 := mem[R11 + 0xFFFFFFE4:32, el]:u32                                      19: (23 24 25 26 29 30 31 34 35 36 39 40 44 47 48 49 50)
20: R3 := R3 + 0x2:32                                                           20: (26 31 36 44 47)
21: t_463 := 0x2:32                                                             21: ()
22: s_462 := R3                                                                 22: (26 31 36 44 47)
23: mem := mem with [R3 + 0x0:32, el]:u16 <- t_460                              23: (24 25 26 29 30 31 34 35 36 39 40 44 47 48 49 50)
24: t_460 := low:16[R2]                                                         24: (25)
25: R2 := 0x0:32                                                                25: ()
26: R3 := R3 + 0x4:32                                                           26: (31 36 44 47)
27: t_457 := 0x4:32                                                             27: ()
28: s_456 := R3                                                                 28: (31 36 44 47)
29: mem := mem with [R3 + 0x0:32, el]:u32 <- R2                                 29: (30 31 34 35 36 39 40 44 47 48 49 50)
30: R2 := 0x0:32                                                                30: ()
31: R3 := R3 + 0x4:32                                                           31: (36 44 47)
32: t_452 := 0x4:32                                                             32: ()
33: s_451 := R3                                                                 33: (36 44 47)
34: mem := mem with [R3 + 0x0:32, el]:u32 <- R2                                 34: (35 36 39 40 44 47 48 49 50)
35: R2 := 0x0:32                                                                35: ()
36: R3 := R11 - 0x10:32                                                         36: (44 47)
37: t_447 := 0x10:32                                                            37: ()
38: s_446 := R11                                                                38: (44 47)
39: mem := mem with [R11 + 0xFFFFFFE4:32, el]:u32 <- R1                         39: (40 44 47 48 49 50)
40: mem := mem with [R11 + 0xFFFFFFE8:32, el]:u32 <- R0                         40: (44 47 48 49 50)
41: SP := SP - 0x18:32                                                          41: (47)
42: t_442 := 0x18:32                                                            42: ()
43: s_441 := SP                                                                 43: (47)
44: R11 := SP + 0x4:32                                                          44: (47)
45: t_439 := 0x4:32                                                             45: ()
46: s_438 := SP                                                                 46: (47)
47: SP := SP - 0x8:32                                                           47: ()
48: mem := mem with [base_436 + 0xFFFFFFF8:32, el]:u32 <- R11                   48: (49 50)
49: mem := mem with [base_436 + 0xFFFFFFFC:32, el]:u32 <- LR                    49: (50)
50: base_436 := SP                                                              50: ()
```
