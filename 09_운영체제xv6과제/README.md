# Operating Systems Practice with xv6

This folder records staged xv6 assignments focused on process control, scheduling, memory allocation, and synchronization.

## 1. Portfolio Snapshot
- Category: Major project (Operating Systems)
- Period: **2025.03 to 2025.06.26**
- Date reference: root experience CSV

## 2. Assignment Tracks
### Track 01: xv6 initialization baseline
- base xv6 source and initial assignment setup

### Track 02: syscall and priority extension
- added `setnice` and `getnice`
- added test programs such as `test_nice` and process status utilities
- student note file documents priority initialization and fork inheritance fix points

### Track 03: MLFQ scheduler track
- includes scheduler tests: `test_mlfq`, `test_mlfq2`, `test_rr`

### Track 04: slab allocator track
- added slab allocator files (`slab.c`, `slab.h`, syscall glue)
- includes slab tests in user and kernel space

### Track 05: synchronization track
- added semaphore implementation and syscall interface
- includes producer-consumer and priority-related test cases

## 3. What This Folder Demonstrates
- kernel syscall extension,
- scheduler policy experimentation,
- custom kernel memory allocator integration,
- synchronization primitive implementation and verification.

## 4. Tech Stack
- Language: `C`, `x86 assembly`
- System: `xv6`
- Domain: process, scheduler, memory, synchronization internals
