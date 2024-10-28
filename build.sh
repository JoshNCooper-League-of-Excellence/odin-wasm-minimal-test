
if [ "$1" = "main.odin" ]; then
  echo "Building..."
  odin build . -target:js_wasm32
  echo -e "\033[1;32mDone\033[0m"
fi
