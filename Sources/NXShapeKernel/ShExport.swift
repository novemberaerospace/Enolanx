// ShExport.swift
// Genolanx — STL export helper

import Foundation

enum ShExport {
    /// Get export file path in the user's Documents directory.
    static func exportPath(filename: String, ext: String = "stl") -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Genolanx_Export", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(filename).\(ext)").path
    }
}
