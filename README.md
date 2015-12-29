#README #

##About
A programming language using LLVM, inspired by Swift, Haskell, and Rust.


##Installing
To use, install the following with homebrew

``` 
brew update
brew install llvm
brew install llvm36
brew install homebrew/versions/llvm-gcc28
``` 

##Examples

```swift
func foo: Int Int -> Int = do
    return $0 + $1

func bar: Int = do print($0)

func fact: Int -> Int = |a| do
    if a <= 1 do
        return foo(0 1)
    else do
        return a * fact(a - 1)
```

##How it works



