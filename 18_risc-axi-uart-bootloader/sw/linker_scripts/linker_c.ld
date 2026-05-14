ENTRY(_start)

MEMORY
{
  ROM  (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
  SRAM (rwx) : ORIGIN = 0x20000100, LENGTH = 0x3F00
}

SECTIONS
{
  /DISCARD/ :
  {
    *(.note*)
    *(.comment*)
    *(.eh_frame*)
    *(.riscv.attributes)
  }

  .text :
  {
    . = ALIGN(4);
    KEEP(*(.vectors))
    KEEP(*(.text.startup))
    *(.text*)
    *(.rodata*)
    . = ALIGN(4);
  } > ROM

  .data :
  {
    . = ALIGN(4);
    __data_start = .;
    *(.sdata*)
    *(.data*)
    . = ALIGN(4);
    __data_end = .;
  } > SRAM AT > ROM

  __data_load_start = LOADADDR(.data);

  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    __bss_start = .;
    *(.sbss*)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > SRAM

  PROVIDE(__global_pointer$ = __data_start + 0x800);

  . = ORIGIN(SRAM) + LENGTH(SRAM);
  . = ALIGN(16);
  __stack_top = .;
}
