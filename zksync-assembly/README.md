> **This part of the codebase is under construction, and currently has no impact on the rest of the codebase**

# Getting Started 

## Requirements

## Installation

### zkEVM Assembler

1. Clone the [era-zkEVM-assmebly](https://github.com/matter-labs/era-zkEVM-assembly) compiler

```bash
git clone https://github.com/matter-labs/era-zkEVM-assembly
cd era-zkEVM-assembly
```

2. Update it so it will print out the compiled bytecode.

Go to `src/assembly/mod.rs` and add this:

```rust
println!("{:#?}\n\n", self.bytecode);
```

3. Update the name in `Cargo.toml` to zasm

```diff
[[bin]]
- name = "reader"
+ name = "zasm"
path = "src/reader/main.rs"
```

4. Build the compiler
```bash
cargo build --release
```

Now, you have it built! Try to have it compile the `Hi.zasm` from this repo with:

```bash
./target/release/zasm Hi.zasm
```

You should get an output that starts with:
```asm
[
    Instructions(
        [
            Add(
                Add {
                    condition: ConditionCase(
```

And ends with:
```
0000008003000039000000400030043f0000000102200190000000120000c13d000000000201001900000009022001980000001a0000613d000000000101043b0000000a011001970000000b0110009c0000001a0000c13d0000000001000416000000000101004b0000001a0000c13d0000000701000039000000800010043f0000000c010000410000001d0001042e0000000001000416000000000101004b0000001a0000c13d00000020010000390000010000100443000001200000044300000008010000410000001d0001042e00000000010000190000001e000104300000001c000004320000001d0001042e0000001e000104300000000000000000000000020000000000000000000000000000004000000100000000000000000000000000000000000000000000000000fffffffc000000000000000000000000ffffffff00000000000000000000000000000000000000000000000000000000a99dca3f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000008000000000000000000000000000000000000000000000000000000000000000000000000000000000fea1f379a7b6251b41f1eda49284fdc5f61518e60b7eaf3f34b372b53ad981d5
```

### zkSolc

1. Download the [zksolc](https://github.com/matter-labs/zksolc-bin) compiler, and set it as executeable. You'll have to pick the version for your operating system.

```bash
chmod +x /path/to/zksolc 
```

2. Test it by trying to compile `Hi.sol` from this repo.

```
zksolc Hi.sol
```

You should get an output that looks exactly like `Hi.zasm`

