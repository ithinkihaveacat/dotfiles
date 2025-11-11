Fixes rendering of Helvetica.

For some reason some Linux systems come with a horrible bitmapped version of
Helvetica, and for some reason this has a particularly poor interaction with
Firefox. (Chrome seems immune.)

This maps the font "Helvetica" to something else, and needs to be installed in
`~/.config/fontconfig/fonts.conf`.

See <https://forum.voidlinux.eu/t/bad-font-rendering-in-firefox-for-helvetica/>
for more info.
