import Scribe

@main
struct Client {
    public static func main() async {
        do {
            try await withThrowingDiscardingTaskGroup { group in
                for _ in 0..<1_000 {
                    group.addTask {
                        let client = try await MessageClient()
                        try await withThrowingDiscardingTaskGroup { childgroup in
                            for i in 0..<1_000 {
                                childgroup.addTask {
                                    let r = try await client.send(msg: "Zane was here \(i)")
                                    print(r)
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            print("failed to connect: \(error)")
        }
    }
}
