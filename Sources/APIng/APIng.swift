@main
public struct APIng {
    public private(set) var text = "Hello, World!"

    public static func main() {
        print(APIng().text)
    }
}
