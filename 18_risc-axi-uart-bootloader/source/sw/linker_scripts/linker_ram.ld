ENTRY(_start)

MEMORY
{
  SRAM_APP (rwx) : ORIGIN = 0x20001000, LENGTH = 0x3000
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
  } > SRAM_APP

  .data :
  {
    . = ALIGN(4);
    __data_start = .;
    *(.sdata*)
    *(.data*)
    . = ALIGN(4);
    __data_end = .;
  } > SRAM_APP

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
  } > SRAM_APP

  PROVIDE(__global_pointer$ = __data_start + 0x800);

  . = ORIGIN(SRAM_APP) + LENGTH(SRAM_APP);
  . = ALIGN(16);
  __stack_top = .;
}
