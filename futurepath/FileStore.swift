//
//  FileStore.swift
//  futurepath
//
//  Created on 2025-10-15
//

import SwiftUI
import Combine

/// A lightweight JSON-based storage utility for saving and loading Codable data.
final class FileStore {

    static let shared = FileStore()
    private init() {}

    private let fileManager = FileManager.default

    // MARK: - Directory Helpers

    private func documentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func fileURL(for name: String) -> URL {
        documentsDirectory().appendingPathComponent(name)
    }

    // MARK: - Public API

    /// Saves any Codable object as a JSON file in the Documents directory.
    func save<T: Codable>(_ value: T, as fileName: String) {
        let url = fileURL(for: fileName)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("❌ FileStore save error for \(fileName): \(error.localizedDescription)")
        }
    }

    /// Loads and decodes a Codable object from a JSON file.
    func load<T: Codable>(_ type: T.Type, from fileName: String) -> T? {
        let url = fileURL(for: fileName)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ FileStore load error for \(fileName): \(error.localizedDescription)")
            return nil
        }
    }

    /// Deletes the specified file from the Documents directory.
    func delete(_ fileName: String) {
        let url = fileURL(for: fileName)
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                print("❌ FileStore delete error for \(fileName): \(error.localizedDescription)")
            }
        }
    }

    /// Returns true if a file exists in the Documents directory.
    func exists(_ fileName: String) -> Bool {
        fileManager.fileExists(atPath: fileURL(for: fileName).path)
    }

    /// Lists all stored JSON files for debugging.
    func listFiles() -> [String] {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: documentsDirectory().path)
            return contents.filter { $0.hasSuffix(".json") }
        } catch {
            print("❌ FileStore list error: \(error.localizedDescription)")
            return []
        }
    }
}
