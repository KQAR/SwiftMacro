import MacroTool
import Foundation

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

@Logged("span")
func test(arg: String) {
  print("test ---> ")
}

//@Logged("async")
@TakeTime("[🌟]")
func request(path: String, completion: (String) -> Void) {
  completion(path)
  print("request ---> ")
}

//test(arg: "hah")
request(path: "https://") { _ in
  let _ = 0..<100000.words.reduce(0, +)
  print("reduct")
}
