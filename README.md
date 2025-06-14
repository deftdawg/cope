# Cope and new Cope for colourized shell command output.

## Screenshot

<img src="https://github.com/user-attachments/assets/5636da62-f6e8-4301-b3c8-f4a85867be15" width=80%/>

New Cope in the top left pane, with cope wrapped output for ls, df, ping, shasum, free, 
lsusb in the other panes.


## New Cope

new-cope is a rewrite of cope to include some additional quality of life 
improvements, including enabling and disabling cope dynamically.

## Cope (original documentation)

cope is a wrapper around programs that output to a terminal, to give
them colour for utility and aesthetics while still keeping them the
same at the text level.

Adding colours on top of text makes it easy to see when something's
amiss. For utility, you can stop hunting through your terminal's
scroll buffer to locate an error when it's clearly highlighted in red,
or locating a network address hidden in dense output when they're
marked in yellow and blue (local and foreign, respectively). As for
aesthetics, even the simplest utility can be brightened up by adding a
dash of colour on top.

cope's scripts are written in Perl, so they're as flexible (and fast)
as Perl allows.

---

You'll need Perl >= 5.10, and a working version of CPAN.

Installation is the standard procedure:

```sh
$ perl Makefile.PL
$ make
$ make test
$ sudo make install
```

Then, find out where perl put the scripts:

```sh
$ perl cope_path.pl
```

And add that to your $PATH.

---

Special Commands:

    * `nocope` or `NOCOPE=1 ...`:  Disable all colorization
    * `cope` or `COPE=1 ...`:  Force colorization
