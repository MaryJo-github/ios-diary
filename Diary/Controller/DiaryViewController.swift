//
//  Diary - DiaryViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
//  last modified by Mary & Whales

import UIKit
import Kingfisher
import CoreLocation

final class DiaryViewController: UIViewController {
    private let diaryManager: DiaryEditable
    private let locationManager: CLLocationManager
    private let weatherManager: WeatherManager
    private let logger: Logger
    private var openWeather: OpenWeather?
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    init(
        diaryManager: DiaryEditable,
        locationManager: CLLocationManager = CLLocationManager(),
        weatherManager: WeatherManager = WeatherManager(),
        logger: Logger = Logger()
    ) {
        self.diaryManager = diaryManager
        self.locationManager = locationManager
        self.weatherManager = weatherManager
        self.logger = logger

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureLocations()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshDiaries()
        tableView.reloadData()
    }
    
    private func configureLocations() {
        locationManager.delegate = self
        checkUserCurrentLocationAuthorization(locationManager.authorizationStatus)
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        
        configureNavigationItem()
        setupConstraints()
    }
    
    private func configureNavigationItem() {
        let addDiaryBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                    target: self,
                                                    action: #selector(tappedAddDiaryButton))
        
        navigationItem.rightBarButtonItem = addDiaryBarButtonItem
        navigationItem.title = "title".localized
    }
    
    @objc private func tappedAddDiaryButton() {
        var diaryContent = DiaryContent()
        
        if let openWeather {
            diaryContent.weatherTitle = openWeather.weather.first?.main
            diaryContent.weatherId = openWeather.weather.first?.icon
        }
        
        showEditingDiaryViewController(with: diaryContent)
    }
    
    private func showEditingDiaryViewController(with diaryContent: DiaryContent) {
        let editingDiaryViewController = EditingDiaryViewController(diaryManager: diaryManager,
                                                                    logger: logger,
                                                                    with: diaryContent)
        
        show(editingDiaryViewController, sender: self)
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DiaryTableViewCell.self, forCellReuseIdentifier: DiaryTableViewCell.reuseIdentifier)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }
}

extension DiaryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return diaryManager.diaryContents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DiaryTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? DiaryTableViewCell
        else {
            return UITableViewCell()
        }
        
        guard let diaryContent = diaryManager.diaryContents[safe: indexPath.row]
        else {
            return UITableViewCell()
        }
        
        if let weatherId = diaryContent.weatherId,
           let url = weatherManager.fetchWeatherImageURL(id: weatherId) {
            cell.weatherImageView.kf.setImage(with: url)
        }
        
        cell.configureCell(data: diaryContent)
        
        return cell
    }
}

extension DiaryViewController: UITableViewDelegate, ActivityViewPresentable {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diaryContent = diaryManager.diaryContents[safe: indexPath.row]
        else {
            return
        }
        
        showEditingDiaryViewController(with: diaryContent)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let diaryContent = diaryManager.diaryContents[safe: indexPath.row]
        else {
            return nil
        }
        
        let share = UIContextualAction(
            style: .normal,
            title: "share".localized
        ) { [weak self] (_, _, success: @escaping (Bool) -> Void) in
            
            let diaryContentItem = diaryContent.title + diaryContent.body
            
            self?.presentActivityView(shareItem: diaryContentItem)
            success(true)
        }
        
        let delete = UIContextualAction(
            style: .destructive,
            title: "delete".localized
        ) { [weak self] (_, _, success: @escaping (Bool) -> Void) in
            
            self?.presentCheckDeleteAlert { [weak self] _ in
                self?.deleteDiary(id: diaryContent.id)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            success(true)
        }
        
        return UISwipeActionsConfiguration(actions: [delete, share])
    }
}

extension DiaryViewController {
    private func refreshDiaries() {
        do {
            try diaryManager.refresh()
        } catch {
            logger.osLog(error.localizedDescription)
            presentAlert(title: "failedFetchDataAlertTitle".localized,
                         message: "failedFetchDataAlertMessage".localized,
                         preferredStyle: .alert,
                         actionConfigs: ("failedFetchDataAlertAction".localized, .default, nil))
        }
    }
    
    private func deleteDiary(id: UUID) {
        do {
            try diaryManager.delete(id: id)
        } catch {
            logger.osLog(error.localizedDescription)
            presentAlert(title: "failedDeleteDataAlertTitle".localized,
                         message: "failedDeleteDataAlertMessage".localized,
                         preferredStyle: .alert,
                         actionConfigs: ("failedDeleteDataAlertAction".localized, .default, nil))
        }
    }
}

extension DiaryViewController {
    func showRequestLocationServiceAlert() {
        let requestLocationServiceAlert = UIAlertController(
            title: "위치 정보 이용",
            message: "위치 서비스를 사용할 수 없습니다.\n디바이스의 '설정 > 개인정보 보호'에서 위치 서비스를 켜주세요.",
            preferredStyle: .alert
        )
        
        let goSetting = UIAlertAction(
            title: "설정으로 이동",
            style: .destructive
        ) { _ in
            if let appSetting = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSetting)
            }
        }
        
        let cancel = UIAlertAction(
            title: "취소",
            style: .default
        )
        
        requestLocationServiceAlert.addAction(goSetting)
        requestLocationServiceAlert.addAction(cancel)
        
        present(requestLocationServiceAlert, animated: true)
    }
    
    func checkUserCurrentLocationAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            showRequestLocationServiceAlert()
        case .notDetermined:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            fatalError("Invalid Authorization Status")
        }
    }
}

extension DiaryViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkUserCurrentLocationAuthorization(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task {
            let coordinate = locations.last!.coordinate
            do {
                openWeather = try await weatherManager.fetchWeather(
                    lat: coordinate.latitude,
                    lon: coordinate.longitude
                )
            } catch {
                logger.osLog(error.localizedDescription)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.osLog(error.localizedDescription)
    }
}
