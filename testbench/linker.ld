ENTRY(_start)



SECTIONS
{
    . = 0x00000000;

    .text :
    {
        *(.text*)
    }
    PROVIDE(_estack = __StackTop);

    /DISCARD/ :
    {
        *(.data*)
        *(.bss*)
        *(.rodata*)
        *(.comment)
        *(.note*)
        *(.eh_frame*)
        *(.debug*)
    }
}