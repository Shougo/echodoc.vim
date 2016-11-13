# echodoc.vim

Displays function signatures from completions in the command line.

![example](https://cloud.githubusercontent.com/assets/111942/19444981/a076d748-9460-11e6-851c-f249f8110b3b.gif)

## Installation

Use a package manager and follow its instructions.

Note: echodoc requires v:completed_item feature.  It is added in Vim 7.4.774.

## Usage

The command line is used to display `echodoc` text.  This means that you will
either need to `set noshowmode` or `set cmdheight=2`.  Otherwise, the `--
INSERT --` mode text will overwrite `echodoc`'s text.

When you accept a completion for a function with `<c-y>`, `echodoc` will
display the function signature in the command line and highlight the argument
position your cursor is in.
