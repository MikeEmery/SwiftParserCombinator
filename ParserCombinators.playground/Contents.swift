//: Playground - noun: a place where people can play

import Cocoa

struct Parser<Output> {
    typealias ValueRemainder = (value: Output, remainder: [Character])?
    typealias Instance = ([Character]) -> ValueRemainder
    
    let instance: Instance
    
    init(instance: @escaping Instance) {
        self.instance = instance
    }
    
    func apply(input: [Character]) -> ValueRemainder {
        return instance(input)
    }
}

extension Parser {
    static func zero() -> Parser {
        return Parser ( instance: { _ in
            return nil
        })
    }

    static func result(output: Output) -> Parser {
        return Parser(instance: { input in
            return (output, input)
        })
    }
    
    static func item() -> Parser<Character> {
        return Parser<Character>(instance: { input in
            return input.first.map { firstCharacter in
                return (firstCharacter, Array(input.dropFirst()))
            }
        })
    }
}

extension Parser {
    func bind<NewOutput>(_ closure: @escaping (Output) -> Parser<NewOutput>) -> Parser<NewOutput> {
        return Parser<NewOutput> { input in
            let result = self.apply(input: input)
            
            switch result {
            case .none:
                return nil
            case .some(let state):
                return closure(state.value).apply(input: state.remainder)
            }
        }
    }
}

extension Parser {
    static func satisfy(predicate: @escaping ((Character) -> Bool)) -> Parser<Character> {
        return Parser<Character>.item().bind { theChar in
            if predicate(theChar) {
                return Parser<Character>.result(output: theChar)
            }
            else {
                return Parser<Character>.zero()
            }
        }
    }
    
    static func char(x: Character) -> Parser<Character> {
        return satisfy { $0 == x }
    }
    
    static func choice(_ lhs: Parser<Output>, or rhs: Parser<Output>) -> Parser<Output> {
        return Parser<Output> { input in
            let leftResult = lhs.apply(input: input)
            switch leftResult {
            case .some:
                return leftResult
            case .none:
                return rhs.apply(input: input)
            }
        }
    }
}

extension Parser {
    static var digit: Parser<Character> { return satisfy { "0"..."9" ~= $0 } }
    static var lower: Parser<Character> { return satisfy { "a"..."z" ~= $0 } }
    static var upper: Parser<Character> { return satisfy { "A"..."Z" ~= $0 } }
}