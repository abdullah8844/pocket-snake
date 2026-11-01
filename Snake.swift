import SwiftUI
import Combine

struct Cell: Equatable { var x: Int; var y: Int }

final class Game: ObservableObject {
    let size = 18
    @Published var snake = [Cell(x: 8, y: 9), Cell(x: 7, y: 9), Cell(x: 6, y: 9)]
    @Published var food = Cell(x: 12, y: 9)
    @Published var running = false
    @Published var ended = false
    @Published var score = 0
    @Published var best = UserDefaults.standard.integer(forKey: "best")
    var direction = Cell(x: 1, y: 0)
    var next = Cell(x: 1, y: 0)
    var turned = false

    func start() {
        snake = [Cell(x: 8, y: 9), Cell(x: 7, y: 9), Cell(x: 6, y: 9)]
        direction = Cell(x: 1, y: 0); next = direction
        turned = false; score = 0; ended = false
        spawnFood(); running = true
    }
    func turn(_ x: Int, _ y: Int) {
        guard running, !turned, !(x == -direction.x && y == -direction.y) else { return }
        next = Cell(x: x, y: y); turned = true
    }
    func spawnFood() {
        let empty = (0..<size).flatMap { y in (0..<size).map { Cell(x: $0, y: y) } }.filter { !snake.contains($0) }
        if let cell = empty.randomElement() { food = cell }
        else { running = false; ended = true }
    }
    func tick() {
        guard running else { return }
        direction = next; turned = false
        let head = Cell(x: snake[0].x + direction.x, y: snake[0].y + direction.y)
        let eating = head == food
        let body = eating ? snake : Array(snake.dropLast())
        guard head.x >= 0, head.y >= 0, head.x < size, head.y < size, !body.contains(head) else {
            running = false; ended = true; return
        }
        snake.insert(head, at: 0)
        if eating {
            score += 1
            if score > best { best = score; UserDefaults.standard.set(best, forKey: "best") }
            spawnFood()
        } else { snake.removeLast() }
    }
}

struct ContentView: View {
    @StateObject private var game = Game()
    @Environment(\.scenePhase) private var scenePhase
    private let timer = Timer.publish(every: 0.16, on: .main, in: .common).autoconnect()
    private let green = Color(red: 0.69, green: 0.96, blue: 0.35)

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    Text("POCKET SNAKE").font(.system(size: 27, weight: .black, design: .monospaced)).foregroundColor(green)
                    Text("الثعبان الكلاسيكي").foregroundColor(.white.opacity(0.65))
                    HStack {
                        Text("النقاط: \(game.score)")
                        Spacer()
                        Text("الأفضل: \(game.best)")
                    }.font(.system(.headline, design: .monospaced)).foregroundColor(green)
                    board
                        .frame(width: min(geometry.size.width - 40, 360), height: min(geometry.size.width - 40, 360))
                    Text(game.ended ? (game.snake.count == game.size * game.size ? "فزت! 🎉" : "انتهت اللعبة") : (game.running ? "اسحب على اللوحة أو استخدم الأسهم" : "جاهز للعب؟"))
                        .foregroundColor(.white.opacity(0.8)).font(.subheadline)
                    HStack(spacing: 14) {
                        Button(game.ended || game.score == 0 && !game.running ? "ابدأ اللعب" : "لعبة جديدة") { game.start() }
                        Button(game.running ? "إيقاف مؤقت" : "متابعة") {
                            if !game.ended { game.running.toggle() }
                        }.disabled(game.ended)
                    }.buttonStyle(.bordered).tint(green)
                    VStack(spacing: 6) {
                        arrow("arrow.up", x: 0, y: -1)
                        HStack(spacing: 44) {
                            arrow("arrow.left", x: -1, y: 0)
                            arrow("arrow.right", x: 1, y: 0)
                        }
                        arrow("arrow.down", x: 0, y: 1)
                    }.environment(\.layoutDirection, .leftToRight)
                    Text("تعمل بدون إنترنت • بدون إعلانات").font(.caption).foregroundColor(.white.opacity(0.4))
                }.padding(20).frame(maxWidth: .infinity)
            }
        }
        .background(Color(red: 0.045, green: 0.075, blue: 0.06).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in game.tick() }
        .onChange(of: scenePhase) { phase in if phase != .active { game.running = false } }
    }

    private func arrow(_ symbol: String, x: Int, y: Int) -> some View {
        Button { game.turn(x, y) } label: {
            Image(systemName: symbol).font(.system(size: 22, weight: .bold)).frame(width: 58, height: 44)
        }.buttonStyle(.bordered).tint(green).accessibilityLabel(symbol)
    }

    private var board: some View {
        Canvas { context, size in
            let unit = size.width / CGFloat(game.size)
            for y in 0..<game.size {
                for x in 0..<game.size {
                    let rect = CGRect(x: CGFloat(x) * unit + 1, y: CGFloat(y) * unit + 1, width: unit - 2, height: unit - 2)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(.white.opacity(0.035)))
                }
            }
            for (index, cell) in game.snake.enumerated() {
                let rect = CGRect(x: CGFloat(cell.x) * unit + 1, y: CGFloat(cell.y) * unit + 1, width: unit - 2, height: unit - 2)
                context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(green.opacity(index == 0 ? 1 : 0.7)))
            }
            if game.snake.count < game.size * game.size {
                let rect = CGRect(x: CGFloat(game.food.x) * unit + 2, y: CGFloat(game.food.y) * unit + 2, width: unit - 4, height: unit - 4)
                context.fill(Path(ellipseIn: rect), with: .color(.orange))
            }
        }
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(green.opacity(0.35)))
        .gesture(DragGesture(minimumDistance: 15).onEnded { value in
            let d = value.translation
            if abs(d.width) > abs(d.height) { game.turn(d.width > 0 ? 1 : -1, 0) }
            else { game.turn(0, d.height > 0 ? 1 : -1) }
        })
    }
}

@main
struct PocketSnakeApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}
