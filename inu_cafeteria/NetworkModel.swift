//
//  NetworkModel.swift
//  class_pick
//
//  Created by SeonIl Kim on 2017. 6. 2..
//  Copyright © 2017년 SeonIl Kim. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

let header: HTTPHeaders = [ "Content-Type": "application/x-www-form-urlencoded" ]

let jsonheader: HTTPHeaders = [ "Content-Type": "application/json" ]

class NetworkModel {
    
    //뷰컨트롤러로 데이터를 전달해줄 위임자를 나타내주는 변수
    
    //callbackDelegate
    var view: NetworkCallback?
    
    init() { }
    init(_ vc: NetworkCallback) {
        self.view = vc
    }
    
    func isSuccess(statusCode code: Int) -> Bool {
        switch code {
        case 200:
            return true
        default:
            return false
        }
    }
    
    func errorMsg(code: Int) -> String {
        switch code {
        case 400:
            return .checkId
        case 401:
            return .noToken
        case 402:
            return .dbERROR
        case 403:
            fallthrough
        default:
//            return "오류"
            return String(code)
        }
    }
    
    func post<T: Mappable>(function name: String, type: T.Type, params: Parameters? = nil, headers: HTTPHeaders? = header) {
        log.info(name)
        
        Alamofire.request("\(BASE_URL)/\(name)", method: .post, parameters: params, headers: headers).responseObject { (res: DataResponse<T>) in
            self.networkResult(function: name, statusCode: res.response?.statusCode, item: res.result.value)
            }.responseArray { (res: DataResponse<[T]>) in
                self.networkResult(function: name, statusCode: res.response?.statusCode, item: res.result.value)
        }
    }
    
    func post(function name: String, params: Parameters? = nil, headers: HTTPHeaders? = header) {
        log.info(name)
        Alamofire.request("\(BASE_URL)/\(name)", method: .post, parameters: params, headers: headers).response { res in
            self.networkResult(function: name, statusCode: res.response?.statusCode, item: "")
        }
    }
    
    func get<T: Mappable>(function name: String, type: T.Type, params: Parameters? = nil) {
        log.info(name)
        
        Alamofire.request("\(BASE_URL)/\(name)").responseObject { (res: DataResponse<T>) in
            self.networkResult(function: name, statusCode: res.response?.statusCode, item: res.result.value)
            }.responseArray { (res: DataResponse<[T]>) in
                self.networkResult(function: name, statusCode: res.response?.statusCode, item: res.result.value)
        }
    }
    
    func get(function name: String, params: Parameters? = nil) {
        log.info(name)
        Alamofire.request("\(BASE_URL)/\(name)").response { res in
            self.networkResult(function: name, statusCode: res.response?.statusCode, item: "")
        }
    }
    
    func networkResult(function name: String, statusCode code: Int? = nil, item: Any? = nil) {
        log.info(name)
        guard let code = code else {
            self.view?.networkFailed(errorMsg: name, code: name)
            return
        }
        
        if !self.isSuccess(statusCode: code) {
            self.view?.networkFailed(errorMsg: self.errorMsg(code: code), code: name)
            return
        }
        guard let item = item else {
            Indicator.stopAnimating()
            return
        }
        
        if self.isSuccess(statusCode: code) {
            self.view?.networkResult(resultData: item, code: name)
        } else {
            self.view?.networkFailed(errorMsg: self.errorMsg(code: code), code: name)
        }
    }
    
    /////////
    
    let _ads = "ads.json"
    let _foodplan = "food"
    
    func ads() {
        get(function: _ads, type: AdObject.self)
    }
    
    func foodplan() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"        
        Alamofire.request("\(BASE_URL)/food/\(formatter.string(from: today))").responseJSON { res in
            guard let code = res.response?.statusCode else {
                self.view?.networkFailed(errorMsg: String.noServer, code: self._foodplan)
                return
            }
            
            switch res.result {
            case .success(let item):
                if self.isSuccess(statusCode: code) {
                    if let array = item as? NSDictionary {
                        self.view?.networkResult(resultData: array, code: self._foodplan)
                    }
                } else {
                    self.view?.networkFailed(errorMsg: self.errorMsg(code: code), code: self._foodplan)
                }
            case .failure(let error):
                log.error(error)
                if let error = error as? String {
                    self.view?.networkFailed(errorMsg: error, code: self._foodplan)
                } else {
                    self.view?.networkFailed(errorMsg: String.noServer, code: self._foodplan)
                }
            }
        }
    }
}
