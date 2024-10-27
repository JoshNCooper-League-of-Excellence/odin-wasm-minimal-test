
if [ "$1" = "main.odin" ]; then
  odin build . -target:js_wasm32
fi
