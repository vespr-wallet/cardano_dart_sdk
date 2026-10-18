.PHONY: build

# Regenerates the squadron worker code and the web workers (js, wasm, MV3 loader). Commit the results.
# pubspec.lock pins the toolchain (squadron, build_runner) compiled into the workers: `flutter pub upgrade` to change it.
build:
	flutter pub get --enforce-lockfile
	dart run build_runner build --delete-conflicting-outputs
	bash scripts/gen_js_workers.sh
