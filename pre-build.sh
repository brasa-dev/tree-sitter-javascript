SLATE="./grammar.js.slate"
FILE="./grammar.js"
HIGHLIGHT="./queries/highlights.scm"

DIALECT=$1

# Build language

cp $FILE.slate $FILE
cp $HIGHLIGHT.slate $HIGHLIGHT

replace() {
  sed -e "s/{{$1}}/$2/" $FILE
}

jq -r '.keywords + .literals + .special | to_entries[] | "\(.key) \(.value)"' $DIALECT \
  | xargs -n 2 sh -c $'sed -i -e "s/{{$0}}/$1/g" '$FILE

jq -r '.dialect' $DIALECT \
  | xargs -n 1 sh -c $'sed -i -e "s/{{dialect}}/$0/g" '$FILE

jq -r '.keywords + .literals + .special  | to_entries[] | "\(.key) \(.value)"' $DIALECT \
  | xargs -n 2 sh -c $'sed -i -e "s/{{$0}}/$1/g" '$HIGHLIGHT

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

echo adding to scanner
sed '12 i         "src/scanner.c",' ./binding.gyp

node-gyp configure
node-gyp build

