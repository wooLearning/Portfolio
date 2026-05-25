ENTRY(_start)

MEMORY
{
  ROM  (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
  SRAM (rwx) : ORIGIN = 0x20010000, LENGTH = 32K
}

SECTIONS
{
  /DISCARD/ :
  {
    *(.note*)
    *(.comment*)
  }

  .text :
  {
    KEEP(*(.vectors))
    KEEP(*(.text.startup))
    *(.text*)
    *(.rodata*)
  } > ROM

  .data :
  {
    __data_start = .;
    *(.sdata*)
    *(.data*)
    __data_end = .;
  } > SRAM AT > ROM

  .bss (NOLOAD) :
  {
    __bss_start = .;
    *(.sbss*)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > SRAM

  . = ORIGIN(SRAM) + LENGTH(SRAM);
  . = ALIGN(16);
  __stack_top = .;
}
