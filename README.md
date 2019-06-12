Files for hipster stack 2019 presentation held 2019-06-11.

# What
Langton's ant with Nix in Rust and Purescript.

# Starting it up

First start up the Rust API server (and watch for changes):
```
nix-shell # in project dir
cd backend
rustup install toolchain stable
cargo install cargo-watch
cargo watch -x run
```

Start up Purescript build (and watch for changes):
```
nix-shell # in project dir
cd frontend
spago build
spago bundle -w -m Main -t build/index.js
```

Start up http-server to serve Purescript output:
```
nix-shell # in project dir
cd frontend
http-server -p 8081 --cors --proxy http://localhost:8080 build
```
