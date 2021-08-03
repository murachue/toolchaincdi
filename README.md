# toolchaincdi

Dockerfile for developing CD-i (or OS-9/68000) applications.

# Ingredients

- binutils (`m68k-elfos9-*`)
    - _no_ linker script for elf2mod, you must prepare that
- gcc with OS-9/68000 customization (`m68k-elfos9-gcc`)
    - `-ma6rel` (with `-mpcrel`) is required for OS-9
    - `-mbsrw` may be shrink your app a bit
    - _no_ startup routine for OS-9, you must prepare that
- newlib
    - _no_ any syscall implementation but namespace clean
        - you must implement OS-9 syscall if you want, with `_` prefix
- elf2mod
    - converts specially-crafted ELF into OS-9/68000 executable (module) file
    - [consult elf2mod README for more details](https://github.com/murachue/elf2mod/blob/main/README.md)
- psximager
    - psxbuild with CD-BRIDGE is your friend
    - no ability to make native CD-i image

# How to use?

An example, some application code in C, some Ruby code for generating data, build with GNU Make, follows:

```
$ cat <<'EOF' | sed 's/^    /\t/' > Makefile
all: build.img

build.img: build.cat build/CDI_TEST.APP build/SOMEDATA.RTF build/ABSTRACT.TXT build/COPYRGHT.TXT build/BIBLIOGR.TXT
    psxbuild --cuefile build.cat build.img

build/SOMEDATA.RTF: somedata.txt
    ruby mkdata.rb $< $@

build/CDI_TEST.APP: cdi_test.elf
    elf2mod $< $@

cdi_test.elf: os9.lds cstart.o main.o
    m68k-elfos9-gcc -nostdlib -Wl,-q -o $@ -T $+ -lc -lgcc

cstart.o: cstart.s
    m68k-elfos9-as -o $@ $<

main.o: main.c
    m68k-elfos9-gcc -c -mpcrel -ma6rel -Os -o $@ $<
EOF
$ cat <<EOF > cstart.s
    .type start, function
    .global start
start:
...
    bsr.w main
...
EOF
$ cat <<EOF > main.c
...
void main(void) {
    // some code...
    // sometimes with inline asm...
}
...
EOF
$ cat <<EOF > os9.lds
OUTPUT_FORMAT("elf32-m68k", "elf32-m68k", "elf32-m68k")
OUTPUT_ARCH(m68k)
EXTERN(start)
ENTRY(start)

SECTIONS {
    .text : {
        *(.text_startup)
        *(.text .text.*)
        *(.rodata .rodata.*)
        /* *(.init)
            *(.fini) */
        . = ALIGN(2);
    }

    . = -0x8000; /* 32K only */

    /* OS-9/68000 linkers often place .data after .bss, but we follow other standard. */
    .data : {
        *(.data .data.*)
        . = ALIGN(2);
    }

    .bss(NOLOAD) : {
        *(.bss .bss*)
        *(COMMON)
        . = ALIGN(2);
    }

    end = .;
}
EOF
$ cat <<EOF > mkdata.rb
...
EOF
$ cat <<EOF > somedata.txt
...
EOF
$ mkdir build
$ cat <<EOF > build/ABSTRACT.TXT
this is a test.
EOF
$ cat <<EOF > build/COPYRGHT.TXT
copyright (c) 20xx
public domain
EOF
$ cat <<EOF > build/BIBLIOGR.TXT
murachue/toolchaincdi, 2021
EOF
$ cat <<EOF > build.cat
volume {
    system_id [CD-RTOS CD-BRIDGE]
    volume_id [TEST]
    volume_set_id [TEST]
    publisher_id [YOURNAME]
    preparer_id [YOURNAME]
    application_id [CDI_TEST.APP;1]
    copyright_file_id [COPYRGHT.TXT;1]
    abstract_file_id [ABSTRACT.TXT;1]
    bibliographic_file_id [BIBLIOGR.TXT;1]
}

dir {
    file CDI_TEST.APP
    file COPYRGHT.TXT
    file ABSTRACT.TXT
    file BIBLIOGR.TXT
    xafile SOMEDATA.RTF
}
EOF
$ cat <<EOF > Dockerfile
FROM ghcr.io/murachue/toolchaincdi
RUN apt update && apt install --no-install-recommends -y make ruby && apt clean
EOF
$ docker run --rm -ti -v $PWD:/work -w /work -u $(id -u):$(id -g) $(docker build -q .) make
```

You'll get `build.bin` and `build.cat`.

Note that if you run docker without `-u`, built files are owned by root. Be careful.

psxbuild (libcdio) will says something about failing filename constraints, but it's OK.

# License

MIT for Dockerfile.
