//
//  NetworkRepository.swift
//  Signup
//
//  Created by seongha shin on 2022/03/28.
//

import Combine
import Foundation

class NetworkApiRepository<Target: EndPoint> {
    private var provider: URLSessionProvider?
    
    func request(_ target: Target, session: URLSessionProtocol = URLSession.shared ) -> AnyPublisher<NetworkResult, Never> {
        provider = URLSessionProvider(session: session)
        
        if target.contentType == .urlencode {
            let url = target.baseUrl
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = target.method.value
            urlRequest.setValue(target.contentType.value, forHTTPHeaderField: "Content-Type")

            if let param = target.parameter {
                let formDataString = param.reduce(into: "") {
                    $0 = $0 + "\($1.key)=\($1.value)&"
                }.dropLast()

                let data = formDataString.data(using: .utf8, allowLossyConversion: true)
                urlRequest.httpBody = data
            }

            return Future<NetworkResult, Never> { promise in
                self.provider?.dataTask(request: urlRequest) { result in
                    promise(.success(result))
                }
            }.eraseToAnyPublisher()
        } else {
            let url = target.baseUrl.appendingPathComponent(target.path)
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = target.method.value
            urlRequest.setValue(target.contentType.value, forHTTPHeaderField: "Content-Type")
            
            if let param = target.parameter,
               let body = try? JSONSerialization.data(withJSONObject: param, options: .init()) {
                urlRequest.httpBody = body
            }
            return Future<NetworkResult, Never> { promise in
                self.provider?.dataTask(request: urlRequest) { result in
                    promise(.success(result))
                }
            }.eraseToAnyPublisher()
        }
    }
}
