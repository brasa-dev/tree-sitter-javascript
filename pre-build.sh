for dialect in ./dialects/*; do
  [ ! -d $dialect ] && continue

  DIALECT=${dialect##./dialects/}
  echo $DIALECT

  DEF=../roseta-javascript-dialects/build/to_$DIALECT.json
  GRAMMAR="grammar.js"
  HIGHLIGHT="highlights.scm"

  # Build language

  cp $GRAMMAR.slate $dialect/$GRAMMAR
  cp $HIGHLIGHT.slate $dialect/highlights/$HIGHLIGHT

  jq -r '.lexicon | to_entries[] | "\(.key) \(.value)"' $DEF \
    | xargs -n 2 sh -c $'sed -i -e "s/{{$0}}/$1/g" '$dialect/$GRAMMAR

  jq -r '.dialect' $DEF \
    | xargs -n 1 sh -c $'sed -i -e "s/{{dialect}}/$0/g" '$dialect/$GRAMMAR

  jq -r '.lexicon | to_entries[] | "\(.key) \(.value)"' $DEF \
    | xargs -n 2 sh -c $'sed -i -e "s/{{$0}}/$1/g" '$dialect/highlights/$HIGHLIGHT

  pushd $dialect

  # Remove tree-sitter bindings
  rm \
    binding.gyp \
    bindings/node/index.js \
    bindings/node/binding.cc \
    bindings/rust/lib.rs \
    bindings/rust/build.rs \
    src/tree_sitter/parser.h 

  # Run tree-sitter generate
  tree-sitter generate

  echo adding scanner.c
  sed '12 i         "src/scanner.c",' ./binding.gyp

  node-gyp configure
  node-gyp build

  popd
done
