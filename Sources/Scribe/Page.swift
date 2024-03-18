public struct Selected {
    public var x: Int
    public var y: Int

    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

extension Page {
    public init(_ rows: [[String]]) {
        var cells: [Location: BasicCell] = [:]
        var h = 0
        var w = 0  // 1d array is only width one
        for (y, row) in rows.enumerated() {
            var cur = 0
            for (x, s) in row.enumerated() {
                let l = Location(1 + x, 1 + y)
                cells[l] = BasicCell(s)
                cur += 1
            }
            if cur > w {
                w = cur
            }
            h += 1
        }
        self.height = h
        self.width = w
        self.cells = cells
    }
}

public struct Page {

    public init(height: Int, width: Int, cells: [Location: any Cell]) {
        self.height = height
        self.width = width
        self.cells = cells
    }

    var height: Int
    var width: Int
    private var selected: Selected = Selected(1, 1)
    var cells: [Location: any Cell]
    public var current: any Cell {
        get {
            let l = Location(selected.x, selected.y)
            return cells[l]!
        }
        set {
            let l = Location(selected.x, selected.y)
            cells[l] = newValue
        }
    }

    public mutating func selected(move dir: Direction) {
        let t = self.selected
        switch dir {
        case .up:
            let p = t.y - 1
            if p > 0 {
                self.selected.y = p
            }
        case .down:
            let p = t.y + 1
            if p <= height {
                self.selected.y = p
            }
        case .left:
            let p = t.x - 1
            if p > 0 {
                self.selected.x = p
            }
        case .right:
            let p = t.x + 1
            if p <= width {
                self.selected.x = p
            }
        }
    }

    private func collectCells(_ maxX: Int, _ maxY: Int) -> [Location: any Cell]
    {
        var visited: Set<Location> = []
        let selected = Location(selected.x, selected.y)
        visited.insert(selected)
        var q = [selected]  // start at selected

        var collected: [Location: any Cell] = [:]
        var totalH = 0
        var widths: [Int: Int] = [:]
        var filled: [Int: Bool] = [:]
        // Breadth first search
        while !q.isEmpty {
            let l = q.removeFirst()
            var edges: [Location] = []
            edges.append(l.get(.up))
            edges.append(l.get(.right))
            edges.append(l.get(.down))
            edges.append(l.get(.left))
            for n in edges {
                if !visited.contains(n) {
                    visited.insert(n)
                    if cells[n] != nil {
                        q.append(n)
                    }
                }
            }
            if let c = cells[l] {
                // Update counters
                let y = l.y
                if widths[y] == nil {
                    if totalH < maxY {
                        widths[y] = c.width
                        filled[y] = false
                        totalH += 1
                        collected[l] = c
                    }
                } else {
                    if widths[y]! + c.width <= maxX {
                        widths[y]! += c.width
                        collected[l] = c
                    } else {
                        // if row is filled mark it filled
                        filled[y] = true
                    }
                }
            } else {
                print("\(l): not found")
            }
        }
        return collected
    }

    /// Builds a Frame based on a given max window x and y
    public func renderWindow(_ maxX: Int, _ maxY: Int) -> Frame {
        var frame = Frame(maxX, maxY)

        let cells = collectCells(maxX, maxY)
        let todoList = cells.keys.sorted()  // top left to bottom right
        var data = FrameData(
            todoList: todoList, cells: cells,
            selected: Location(selected.x, selected.y),
            maxX: maxX, maxY: maxY)

        var tileL = Location(-1, -1)
        for y in 1...maxY {
            for x in 1...maxX {
                tileL = Location(x, y)
                frame.frame[tileL] = String(data.nextChar(x, y))
            }
        }
        return frame
    }

    private struct FrameData {

        var todoList: [Location]
        let cells: [Location: any Cell]
        var current: [Character] = []
        let selected: Location
        let maxX: Int
        let maxY: Int

        init(
            todoList: [Location], cells: [Location: any Cell],
            selected: Location, maxX: Int, maxY: Int
        ) {
            self.todoList = todoList
            self.cells = cells
            self.selected = selected
            self.maxX = maxX
            self.maxY = maxY
        }

        private var lastY: Int? = nil

        mutating func nextChar(_ x: Int, _ y: Int) -> Character {
            let c: Character
            var curY: Int? = nil
            if lastY == nil {
                lastY = y
            }
            if current.count > 0 {
                c = current.removeFirst()
            } else {
                if todoList.count > 0 {
                    curY = todoList.first!.y
                    if curY == lastY! {
                        let index = todoList.removeFirst()
                        let cell = cells[index]!
                        if index == selected {
                            current = Array(
                                repeating: "@", count: cell.width)
                        } else {
                            var s = Array(cell.value)
                            while current.count < cell.width {
                                if s.count > 0 {
                                    current.append(s.removeFirst())
                                } else {
                                    current.append("_")
                                }
                            }
                        }
                        c = current.removeFirst()
                    } else {
                        current = []
                        c = "$"
                    }
                } else {
                    c = "#"
                }
            }
            if x == maxX {
                if let newY = curY {
                    lastY = newY
                }
                current = []
            }
            return c
        }
    }
}
