pins:
let
  inherit (builtins) head match substring removeAttrs mapAttrs attrNames;

  # tree-sitter-rust -> rust for buildGrammar
  langName = name: builtins.head (match "tree-sitter-(.*)" name);

  baseVersion = rev: if match "v.*" rev != null then rev else substring 0 7 rev;

  mkGrammar = pkgs: name: pin:
  pkgs.tree-sitter.buildGrammar ({
    language = langName name;
    version = baseVersion pin.rev + "-emacs";
    src = pkgs.fetchFromGitHub { inherit (pin) owner repo rev hash; };
  } // removeAttrs pin [ "owner" "repo" "rev" "hash" ]);

  grammars = pkgs: mapAttrs (mkGrammar pkgs) pins;

  pick = pkgs: stock: languages:
    let mine = grammars pkgs;
    in map (lang: mine.${lang}
    or stock.${lang}
    or (throw "emacs-treesit-grammars: '${lang}' isn't in pins or stock set")) languages;
in {
  inherit pins grammars pick;

  languages = attrNames pins;

  withGrammars =
    { pkgs, epkgs, languages ? null }:
    epkgs.treesit-grammars.with-grammars
      (stock: pick pkgs stock
        (if languages == null then attrNames pins else languages));
}
