//
//  posix.swift
//  Serial
//
//  Created by Julian Porter on 26/02/2020.
//  Copyright © 2020 JP Embedded Solutions. All rights reserved.
//

import Foundation



internal func wopen(_ path: UnsafePointer<CChar>,_ oflag : Int32) throws -> Int32 {
    return try POSIXException.wrap(open(path,oflag))
}
@discardableResult  internal func wclose(_ fd: Int32) throws -> Int32 {
    return try POSIXException.wrap(close(fd))
}
@discardableResult internal func wread(_ fd : Int32,_ raw : UnsafeMutableRawPointer!,_ minimum : Int) throws -> Int {
    return try POSIXException.wrapInt(read(fd, raw, minimum))
}
@discardableResult  internal func wwrite(_ fd : Int32,_ raw : UnsafeRawPointer!,_ count : Int) throws -> Int {
    return try POSIXException.wrapInt(write(fd, raw, count))
}
@discardableResult internal func wioctl(_ fd : CInt,_ request : UInt) throws -> Int32 {
    return try POSIXException.wrap(ioctl(fd, request))
}
@discardableResult internal func wfcntl(_ fd : Int32,_ request : Int32, _ flag: Int32) throws -> Int32 {
    return try POSIXException.wrap(fcntl(fd, request, flag))
}
 

