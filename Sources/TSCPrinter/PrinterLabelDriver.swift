//
//  PrinterLabelDriver.swift
//
//
//  Created by Dmitriy Borovikov on 14.09.2021.
//

import Foundation
import Logging

final public class PrinterLabelDriver {
    public enum PrinterError: Error {
        case fatal(message: String)
        case error(message: String)
        case warning(message: String)
        public var localizedDescription:  String {
            switch self {
            case .fatal(message: let message),
                 .error(message: let message),
                 .warning(message: let message):
                return message
            }
        }
    }

    let logger = Logger(label: "PrinterLabelDriver")
    let address: String
    let port: Int32
    var model: String = ""
    var serial: String = ""

    public init(address: String, port: Int32 = 9100) {
        self.address = address
        self.port = port
    }

    deinit {
        logger.trace("Deinit: \(String(describing: Self.self))")
    }

    public func checkConnection() throws {
        let status: TSCPrinter.PrinterStatus
        let warnings: TSCPrinter.PrinterWarnings
        let errors: TSCPrinter.PrinterErrors
        do {
            let printer = try TSCPrinter(address: address, port: port)
            model = try printer.modelName()
            serial = try printer.serial()
            (status, warnings, errors) = try printer.extendedStatus()
        } catch {
            logger.critical("TSC connection error: \(error)")
            throw error
        }
        logger.info("Connected TSC-\(model), s/n \(serial)")
        guard errors.isEmpty else {
            logger.error("\(model) error: \(errors)")
            throw PrinterError.error(message: "\(errors.description)")
        }
        guard warnings.isEmpty else {
            logger.warning("\(model) warning: \(warnings)")
            throw PrinterError.warning(message: "\(warnings)")
        }
        logger.info("\(model) status: \(status)")
    }

    /// Make label from template
    /// - Parameters:
    ///   - templateName: The name of template
    ///   - dictionary: Replacement dictionary
    /// - Returns: formed label
    public func makeLabel(from template: String, with dictionary: [String: String] ) -> String {
        var label = template
        for (key, value) in dictionary {
            while label.range(of: "{{\(key)}}") != nil {
                label = label.replacingOccurrences(of: "{{\(key)}}", with: value)
            }
        }
        return label
    }

    /// Print label with template string
    /// - Parameters:
    ///   - template: string with label template
    ///   - dictionary: Replacement dictionary
    /// - Throws: Connection error or PrinterError
    public func printLabel(template: String, with dictionary: [String: String] ) throws {
        let status: TSCPrinter.PrinterStatus
        let warnings: TSCPrinter.PrinterWarnings
        let errors: TSCPrinter.PrinterErrors
        let label = makeLabel(from: template, with: dictionary)
        do {
            let printer = try TSCPrinter(address: address, port: port)
            try printer.sendString(label)
            (status, warnings, errors) = try printer.extendedStatus()
        } catch  {
            logger.error("\(model) \(error)")
            throw PrinterError.error(message: error.localizedDescription)
        }
        guard errors.isEmpty else {
            logger.error("\(model) error: \(errors)")
            throw PrinterError.error(message: "\(errors.description)")
        }
        guard warnings.isEmpty else {
            logger.warning("\(model) warning: \(warnings)")
            throw PrinterError.warning(message: "\(warnings)")
        }
        logger.trace("priner status: \(status)")
    }
}
