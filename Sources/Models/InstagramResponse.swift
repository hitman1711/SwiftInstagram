//
//  InstagramResponse.swift
//  SwiftInstagram
//
//  Created by Ander Goig on 16/9/17.
//  Copyright © 2017 Ander Goig. All rights reserved.
//

public struct InstagramResponse<T: Decodable>: Decodable {

    // MARK: - Properties

    public let data: T?
    public let meta: Meta
	public let pagination: Pagination?

    // MARK: - Types

    public struct Meta: Decodable {
		public let code: Int
        public let errorType: String?
        public let errorMessage: String?
    }

    public struct Pagination: Decodable {
        public let nextUrl: String?
        public let nextMaxId: String?
    }
}

/// Dummy struct used for empty Instagram API data responses
public struct InstagramEmptyResponse: Decodable { }
