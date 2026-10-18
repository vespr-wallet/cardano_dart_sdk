.PHONY: build

# Regenerates the squadron worker code and the web workers (js, wasm, MV3 loader). Commit the results.
build:
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
	bash scripts/gen_js_workers.sh
