<<<<<<< HEAD
# Warehouse-GatePass
=======
# Warehouse Gatepass App

A Flutter-based application for managing warehouse gatepasses. Supports mobile (Android), desktop (Windows), and web platforms. The app allows security guards and warehouse staff to create, print, and manage gatepasses for goods movement in and out of the warehouse.

---

## Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| Android  |   ✅      | Full support, including Bluetooth printing |
| Windows  |   ✅      | Full support, including local printing |
| Web      |   ✅      | Most features supported; printing may be limited |
| iOS      |   🚫      | Not currently supported |

---

## Features

- Create and print gatepasses with QR codes
- Import party master data from CSV/Excel files
- View gatepass history with filtering options
- Export gatepass data to Excel
- Bluetooth/Wi-Fi printer support (Android/Windows)
- Offline-first functionality with local SQLite database
- Modern Material Design 3 UI
- Full CRUD for Warehouses, Parties, Product Grades, and Gatepasses

---

## Requirements

- Flutter SDK (>=3.0.0 recommended)
- Android 5.0+ (API 21+)
- Windows 10+
- Chrome/Edge/Firefox (for Web)
- Bluetooth/Wi-Fi printer (optional, for printing)

---

## Installation & Setup

### 1. Clone the repository
```bash
git clone https://github.com/krnbhtt/warehouse-gatepass.git
cd warehouse-gatepass
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Platform-specific Build & Run

#### Android
```bash
flutter run -d android
# or build APK
flutter build apk
```

#### Windows
```bash
flutter run -d windows
# or build Windows executable
flutter build windows
```

#### Web
```bash
flutter run -d chrome
# or build for deployment
flutter build web
```

---

## Usage

### Creating a Gatepass
1. Navigate to the "New Gatepass" tab
2. Fill in the required information:
   - Invoice Number
   - Party Name (select from dropdown)
   - Vehicle Number (format: GJ01AB1234)
   - Quantity
   - Product Grade
3. Click "Submit & Print" to save and print the gatepass, or "Save Only" to save without printing

### Importing Party Master
1. Go to Settings > Upload Party Master
2. Select a CSV or Excel file with the following columns:
   - Party Name
   - GST Number
   - Address
3. The app will process the file and import the data

### Managing Masters (CRUD)
- Go to Settings to manage Warehouses, Parties, and Product Grades
- Use the add, edit, and delete buttons for full CRUD operations

### Viewing History
1. Navigate to the "History" tab
2. Use the date range picker and party filter to find specific gatepasses
3. Click the print icon to reprint a gatepass
4. Use the export button to download the data as Excel

### Printer Setup
1. Go to Settings > Printer Setup
2. Click "Scan" to find available Bluetooth/Wi-Fi printers
3. Select your printer from the list and click "Connect"

---

## CSV/Excel Format

The party master file should have the following columns:

| Party Name | GST Number | Address |
|------------|------------|---------|
| ABC Corp   | 27AAAAA1234Z1 | Mumbai, Maharashtra |
| XYZ Traders | 24BBBBB5678X1 | Surat, Gujarat |

---

## Troubleshooting & Known Limitations

- **iOS is not supported** due to plugin and printing limitations.
- **Web printing**: Printing support in browsers may be limited or require additional configuration.
- **Bluetooth permissions**: On Android, ensure Bluetooth and Location permissions are granted for printer setup.
- **Database location**: On Windows, the database is stored in the app's working directory; on Android/Web, it's in the app data directory.
- **File import**: Only CSV and Excel files are supported for party master import.
- **Large data sets**: Performance may degrade with very large numbers of gatepasses or parties.

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email karan@karaninfosys.com or create an issue in the repository.
>>>>>>> 7000191 (Initial commit)
