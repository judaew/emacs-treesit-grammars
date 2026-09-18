# emacs-treesit-grammars

**Pinned** Tree-sitter grammars for Emacs `treesit`, packaged as a Nix flake.

## Usage

Add the input to your flake. `inputs.nixpkgs.follows` makes the
grammars use the same nixpkgs revision as the Emacs package.


```nix
{
    inputs = {
        # Your inputs:
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
        nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

        emacs-treesit-grammars = {
            url = "github:judaew/emacs-treesit-grammars";
            inputs.nixpkgs.follows = "nixpkgs-unstable";
        };
    };

    # The rest of your flake.nix config
    outputs = ...
}
```

Use it in your Emacs package:

```
{ inputs, pkgs, ... }:

services.emacs = {
    package = (emacsPackagesFor pkgs.emacs-pgtk).emacsWithPackages (epkgs: [
        (inputs.emacs-treesit-grammars.lib.withGrammars {
            pkgs = pkgs;
            epkgs = epkgs;

            # `languages` is optional
            # By default, all pinned grammars are included.

            # Pins + stock nixpkgs grammars:
            languages = inputs.emacs-treesit-grammars.lib.languages ++ [
                "tree-sitter-nix"
            ];

            # A subset:
            languages = [ "tree-sitter-rust" ];
        })
    ]);
};
```

Example configuration (with latest Emacs):

```nix
{ inputs, nixpkgs-unstable, ... }:

let
    emacsTreesit = inputs.emacs-treesit-grammars.lib;
    epkgs = nixpkgs-unstable.emacsPackagesFor nixpkgs-unstable.emacs-pgtk;
in
{
    services.emacs = {
        enable = true;
        defaultEditor = true;
        package = epkgs.emacsWithPackages (e: [
            (emacsTreesit.withGrammars {
                pkgs = nixpkgs-unstable;
                epkgs = e;
                languages = emacsTreesit.languages ++ [ "tree-sitter-nix" ];
            })

            epkgs.jinx
            epkgs.ghostel
        ]);
    };
}
```

Both `pkgs` and `epkgs` are explicit. `pkgs` must be the nixpkgs
package set used to build `epkgs`; the epkgs scope does not expose it.

### Supported languages

The list of pinned languages comes directly from `pins.nix`:

```sh
nix eval 'github:judaew/emacs-treesit-grammars#lib.languages' --json | jq -r '.[]'
```

### Verifying that pins are in use

Check the system closure:

```sh
nix path-info -r /run/current-system | grep -E 'tree-sitter-[^-]+-.*-emacs$'
```

Store names look like this:

| Pin                | Store name                                       |
|--------------------|--------------------------------------------------|
| rev = "v0.24.2"    | tree-sitter-rust-v0.24.2-emacs |
| rev = "18b0515..." | tree-sitter-rust-18b0515-emacs |

## Why this project exists

Tree-sitter grammar revisions in nixpkgs follow the nixpkgs
channel. Unstable gets newer grammar revisions over time, while stable
keeps the revisions that were available when the branch was cut.

Neither is tied to the grammar versions expected by individual Emacs
modes. Updating nixpkgs can therefore change the parsers used by
Emacs even when nothing in the Emacs configuration itself changed.

This matters because Emacs modes depend on the syntax tree produced by
a grammar. Fontification, indentation, navigation, language
injections, and structured editing all use node names, fields, and the
structure of the tree.

### Grammar versions are part of the mode's contract

A grammar can change its node names, fields, or tree structure while
remaining fully compatible with the Tree-sitter ABI:

```
old:                  new:
call_expression       call_expression
└── arguments         └── argument_list
```

The new grammar is valid from Tree-sitter's perspective: the parser
simply follows its new syntax tree definition. The problem is code
that expects the previous tree structure.

For example, an Emacs mode may contain a query like:

```emacs-lisp
(treesit-query-capture
        parser
        '((call_expression
           function: (identifier) @function)))
```

If a node or field changes, the parser can still load normally while the query
stops matching.

The same applies to:

- `treesit-font-lock-rules`
- indentation rules
- navigation and `treesit-defun-type-regexp`
- injection rules
- folding
- custom queries

These failures are often silent. Highlighting can stop matching, indentation
can change, or navigation can behave differently without any error pointing to
the grammar update.

Grammar versions therefore need to be pinned independently from the
nixpkgs channel.
