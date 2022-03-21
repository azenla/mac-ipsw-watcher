//
//  main.swift
//  mac-ipsw-watcher
//
//  Created by Kenneth Endfinger on 3/20/22.
//

import CommonCrypto
import Foundation
import Virtualization

func checkAndDownload() async throws {
    let latestSupportedImage = try await VZMacOSRestoreImage.latestSupported
    let url = latestSupportedImage.url
    let absoluteUrlString = url.absoluteString
    guard let ipswFileName = url.pathComponents.last else {
        throw URLError(.badURL)
    }
    
    guard let shaOfUrl = absoluteUrlString.data(using: .utf8)?.sha256() else {
        throw URLError(.badURL)
    }
    let localFilePath = "\(shaOfUrl)/\(ipswFileName)"
    if FileManager.default.fileExists(atPath: localFilePath) {
        print("Latest IPSW is already downloaded: \(localFilePath)")
        return
    }
    let localFileUrl = URL(fileURLWithPath: localFilePath)
    try FileManager.default.createDirectory(at: localFileUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
    print("Downloading IPSW \(absoluteUrlString) to \(localFilePath)")
    let (temporaryFileUrl, response) = try await URLSession.shared.download(from: url)
    if (response as! HTTPURLResponse).statusCode != 200 {
        throw URLError(.badURL)
    }
    try FileManager.default.moveItem(at: temporaryFileUrl, to: localFileUrl)
    print("Latest IPSW \(localFilePath) downloaded.")
}

Task {
    while true {
        do {
            try await checkAndDownload()
        } catch {
            print("ERROR: \(error)")
        }
        sleep(5)
    }
}

dispatchMain()
