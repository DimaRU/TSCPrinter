//
//  TSCPrinter.swift
//  TestPrinter
//
//  Created by Dmitriy Borovikov on 07.06.2021.
//

import Foundation
import Socket

final class TSCPrinter {
    let socket: Socket

    public enum BarcodeType: String {
        case B128 = "128"             // Code 128, switching code subset A, B, C automatically
        case B128M = "128M"           // Code 128, switching code subset A, B, C manually.
        case EAN128 = "EAN128"        // Code 128, switching code subset A, B, C automatically
        case B25 = "25"               // Interleaved 2 of 5
        case B25C = "25C"             // Interleaved 2 of 5 with check digits
        case B39 = "39"               // Code 39
        case B39C = "39C"             // Code 39 with check digits
        case B93 = "93"               // Code 93
        case EAN13 = "EAN13"          // EAN 13
        case EAN13_2 = "EAN13+2"      // EAN 13 with 2 digits add-on
        case EAN13_5 = "EAN13+5"      // EAN 13 with 5 digits add-on
        case EAN8 = "EAN8"            // EAN 8
        case EAN8_2 = "EAN8+2"        // EAN 8 with 2 digits add-on
        case EAN8_5 = "EAN8+5"        // EAN 8 with 5 digits add-on
        case CODA = "CODA"            // Codabar
        case POST = "POST"            // Postnet
        case UPCA = "UPCA"            // UPC-A
        case UPCA_2 = "UPCA+2"        // UPC-A with 2 digits add-on
        case UPCA_5 = "UPCA+5"        // UPC-A with 5 digits add-on
        case UPCE = "UPCE"            // UPC-E
        case UPCE_2 = "UPCE+2"        // UPC-E with 2 digits add-on
        case UPCE_5 = "UPCE+5"        // UPC-E with 5 digits add-on
    }

    public enum Rotation: String {
        case r0 = "0"
        case r90 = "90"
        case r180 = "180"
        case r270 = "270"
    }

    public struct PrinterBasicStatus: OptionSet, CustomStringConvertible {
        let rawValue: UInt8

        static let normal = PrinterBasicStatus([])
        static let printHeadOpen = PrinterBasicStatus(rawValue: 1 << 0)
        static let paperJam = PrinterBasicStatus(rawValue: 1 << 1)
        static let paperEmpty = PrinterBasicStatus(rawValue: 1 << 2)
        static let ribbonEmpty = PrinterBasicStatus(rawValue: 1 << 3)
        static let pause = PrinterBasicStatus(rawValue: 1 << 4)
        static let printing = PrinterBasicStatus(rawValue: 1 << 5)
        static let error = PrinterBasicStatus(rawValue: 1 << 7)

        public var description: String {
            var s: [String] = []

            if self.contains(.printHeadOpen) { s.append("Открыта печатающая головка") }
            if self.contains(.paperJam) { s.append("Замятие бумаге") }
            if self.contains(.paperEmpty) { s.append("Закончилась бумага") }
            if self.contains(.ribbonEmpty) { s.append("Конец ленты") }
            if self.contains(.pause) { s.append("Пауза") }
            if self.contains(.printing) { s.append("Печать") }
            if self.contains(.error) { s.append("Ошибка") }
            return s.joined(separator: ", ")
        }
    }

    public enum PrinterStatus: UInt8, CustomStringConvertible {
        case normal = 0x40
        case pause = 0x60
        case backingLabel = 0x42
        case cutting = 0x43
        case printerError = 0x45
        case formFeed = 0x46
        case waitingPrintKey = 0x4b
        case waitingTakeLabel = 0x4c
        case printingBatch = 0x50
        case imaging = 0x57
        case unknown = 0

        public var description: String {
            switch self {
            case .normal: return "Нормально"
            case .pause: return "Пауза"
            case .backingLabel: return "Подготовка этикетки"
            case .cutting: return "Отрезание"
            case .printerError: return "Ошибка принтера"
            case .formFeed: return "Подача формы"
            case .waitingPrintKey: return "Ожидание нажатия кнопки печати"
            case .waitingTakeLabel: return "Ожидание отрыва этикетки"
            case .printingBatch: return "Печать задания"
            case .imaging: return "Отрисовка"
            case .unknown: return "Неизвестно"
            }
        }
    }

    public struct PrinterWarnings: OptionSet, CustomStringConvertible {
        let rawValue: UInt8

        static let paperLow = PrinterWarnings(rawValue: 1 << 0)
        static let ribbonLow = PrinterWarnings(rawValue: 1 << 1)

        public var description: String {
            var s: [String] = []
            if self.contains(.paperLow) { s.append("Заканчивается бумага") }
            if self.contains(.ribbonLow) { s.append("Заканчивается лента") }
            return s.joined(separator: ", ")
        }
    }

    public struct PrinterErrors: OptionSet, CustomStringConvertible {
        let rawValue: Int

        static let printHeadOverheat = PrinterErrors(rawValue: 1 << 0)
        static let steppingMotorOverheat = PrinterErrors(rawValue: 1 << 1)
        static let printHeadError = PrinterErrors(rawValue: 1 << 2)
        static let cutterJam = PrinterErrors(rawValue: 1 << 3)
        static let insufficientMemory = PrinterErrors(rawValue: 1 << 4)
        static let paperEmpty = PrinterErrors(rawValue: 1 << 5)
        static let paperJam = PrinterErrors(rawValue: 1 << 6)
        static let ribbonEmpty = PrinterErrors(rawValue: 1 << 7)
        static let ribbonJam = PrinterErrors(rawValue: 1 << 8)
        static let printHeadOpen = PrinterErrors(rawValue: 1 << 10)

        public var description: String {
            var s: [String] = []
            if self.contains(.printHeadOverheat) { s.append("Перегрев печатающей головки") }
            if self.contains(.steppingMotorOverheat) { s.append("Перегрев шагового двигателя") }
            if self.contains(.printHeadError) { s.append("Ошибка печатающей головки") }
            if self.contains(.cutterJam) { s.append("Заедание резака") }
            if self.contains(.insufficientMemory) { s.append("Недостаточно памяти") }
            if self.contains(.paperEmpty) { s.append("Закончилась бумага") }
            if self.contains(.paperJam) { s.append("Замятие бумаге") }
            if self.contains(.ribbonEmpty) { s.append("Конец ленты") }
            if self.contains(.ribbonJam) { s.append("Замятие ленты") }
            if self.contains(.printHeadOpen) { s.append("Открыта печатающая головка") }
            return s.joined(separator: ", ")
        }
    }

    init(address: String, port: Int32 = 9100) throws {
        socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)

        try socket.setReadTimeout(value: 2000)
        try socket.setWriteTimeout(value: 2000)
        try socket.connect(to: address, port: port, timeout: 1000)
    }

    deinit {
        socket.close()
    }

    public func sendString(_ s: String) throws {
        guard !s.isEmpty else { return }
        try socket.write(from: s + "\n")
    }

    public func sendData(_ data: Data) throws {
        try socket.write(from: data)
    }

    public func setup(width: String, height: String, speed: String, density: String, sensor: Bool, vertical: String, offset: String) throws {
        try sendString("SIZE \(width) mm,\(height) mm")
        try sendString("SPEED \(speed)")
        try sendString("DENSITY \(density)")
        let type = sensor ? "BLINE" : "GAP"
        try sendString("\(type) \(vertical) mm,\(offset) mm")
    }

    public func clearBuffer() throws {
        try sendString("CLS")
    }

    public func barcode(x: String, char y: String, type: BarcodeType, height: String,
                        readable: Bool, rotation: Rotation, narrow: String, wide: String, code: String) throws {

        let readable = readable ? "1" : "0"
        try sendString("BARCODE \(x),\(y),\"\(type.rawValue)\",\(height),\(readable),\(rotation.rawValue),\(narrow),\(wide),\(code)")
    }

    public func printLabel(set: Int, copy: Int) throws {
        try sendString("PRINT \(set),\(copy)")
    }

    public func formFeed() throws {
        try sendString("FORMFEED")
    }

    public func noBackfeed() throws {
        try sendString("SET STRIPER OFF")
        try sendString("SET TEAR OFF")
    }

    public func status() throws -> UInt8  {
        var buffer: Data = Data()
        try sendString("\u{1b}!?")
        let count = try socket.read(into: &buffer)
        guard count == 1 else {
            return 0x80
        }
        return buffer.first!
    }

    public func extendedStatus() throws -> (status: PrinterStatus, warnings: PrinterWarnings, errors: PrinterErrors)  {
        var buffer: Data = Data()
        try sendString("\u{1b}!S")
        let count = try socket.read(into: &buffer)
        guard count == 8 else {
            return (.unknown, [], [])
        }

        let status = PrinterStatus(rawValue: buffer[1]) ?? .unknown
        let warnins = PrinterWarnings(rawValue: buffer[2] & 0x3)
        let errors = PrinterErrors(rawValue: Int(buffer[4] & 0x3f) << 5 + Int(buffer[3] & 0x1f)  )
        return (status, warnins, errors)
    }

    public func modelName() throws -> String {
        var buffer: Data = Data()
        try sendString("~!T")
        _ = try socket.read(into: &buffer)
        let rezult = String(data: buffer, encoding: .utf8) ?? ""
        return rezult
    }

    public func serial() throws -> String {
        var buffer: Data = Data()
        try sendString("OUT _SERIAL$")
        _ = try socket.read(into: &buffer)
        let rezult = String(data: buffer, encoding: .utf8) ?? ""
        return rezult
    }
}
