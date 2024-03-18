import Programs
import Scribe

@main
struct Server: ScribeServer {
    var programs: [any Program.Type] = [
        ClientProgram.self
    ]
}
